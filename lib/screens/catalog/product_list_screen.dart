import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../models/product_filters.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/hanging_search_filter_overlay.dart';
import '../../widgets/product_card.dart';
import '../home/widgets/home_search_bar.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String? title;
  final String? categoryId;
  final String? brandId;
  final String? search;
  final double? lat;
  final double? lng;
  final double? radius;

  const ProductListScreen({
    super.key,
    this.title,
    this.categoryId,
    this.brandId,
    this.search,
    this.lat,
    this.lng,
    this.radius,
  });

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  late ProductFilters _productFilters;
  late Map<String, dynamic> _providerKeyMap;

  bool _isOverlayOpen = false;
  bool _isFilterTab = false;
  String _searchQuery = '';

  RangeValues _priceRangeValues = const RangeValues(0, 150000);
  int? _selectedRating;
  final Set<String> _selectedBrands = {};
  final Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.search ?? '';
    _searchController.text = _searchQuery;

    _productFilters = ProductFilters(
      category: widget.categoryId,
      brand: widget.brandId,
      search: widget.search,
      lat: widget.lat,
      lng: widget.lng,
      radius: widget.radius,
    );
    _updateProviderKeyMap();
    _scrollController.addListener(_onScroll);
  }

  void _updateProviderKeyMap() {
    _providerKeyMap = {
      'filters_object': _productFilters,
      'category': _productFilters.category,
      'brand': _productFilters.brand,
      'search': _productFilters.search,
      'sort': _productFilters.sortBy,
      'active_count': _productFilters.activeFilterCount,
      'random_key': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider(_providerKeyMap).notifier).loadNextPage();
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _searchQuery = '';
      _isFilterTab = false;
      _priceRangeValues = const RangeValues(0, 150000);
      _selectedRating = null;
      _selectedBrands.clear();
      _selectedCategories.clear();
      _productFilters.reset();
      _updateProviderKeyMap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider(_providerKeyMap));
    final categories = ref.watch(categoriesProvider).value ?? [];
    final brands = ref.watch(brandsProvider).value ?? [];
    final allProducts = ref.watch(allProductsProvider).value ?? [];

    final mediaTopPadding = MediaQuery.of(context).padding.top;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    String categoryNameLabel = _productFilters.category ?? '';
    if (categoryNameLabel.isNotEmpty && categories.isNotEmpty) {
      final match = categories.firstWhere(
        (c) => c.id == categoryNameLabel || c.slug == categoryNameLabel,
        orElse: () => Category(id: categoryNameLabel, name: categoryNameLabel, slug: categoryNameLabel),
      );
      categoryNameLabel = match.name;
    }

    final double availableOverlayHeight = (MediaQuery.of(context).size.height - mediaTopPadding - 110 - keyboardHeight)
        .clamp(120.0, MediaQuery.of(context).size.height * 0.70);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kNavy),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title ?? (categoryNameLabel.isNotEmpty ? categoryNameLabel : 'Shop'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kNavy),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Modern HomeSearchBar
              HomeSearchBar(
                controller: _searchController,
                hintText: 'Search products in shop...',
                onTap: () {
                  setState(() => _isOverlayOpen = true);
                },
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                    _productFilters.search = _searchQuery.isNotEmpty ? _searchQuery : null;
                    _updateProviderKeyMap();
                    _isOverlayOpen = true;
                  });
                },
                onFilterTap: () {
                  setState(() {
                    _isOverlayOpen = true;
                    _isFilterTab = true;
                  });
                },
              ),
              const SizedBox(height: 8),

              // Active Filters Chip Row
              if (_productFilters.hasActiveFilters || _searchQuery.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: Colors.grey[50],
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryOrange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_searchQuery.isNotEmpty)
                                _buildFilterChip('Search: $_searchQuery', () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                    _productFilters.search = null;
                                    _updateProviderKeyMap();
                                  });
                                }),
                              if (_productFilters.category != null)
                                _buildFilterChip('Cat: $categoryNameLabel', () {
                                  setState(() {
                                    _productFilters.category = null;
                                    _updateProviderKeyMap();
                                  });
                                }),
                              if (_productFilters.brand != null)
                                _buildFilterChip('Brand: ${_productFilters.brand}', () {
                                  setState(() {
                                    _productFilters.brand = null;
                                    _updateProviderKeyMap();
                                  });
                                }),
                              if (_productFilters.priceRanges.isNotEmpty)
                                _buildFilterChip('Price: ${_productFilters.priceRanges.join(", ")}', () {
                                  setState(() {
                                    _productFilters.priceRanges.clear();
                                    _updateProviderKeyMap();
                                  });
                                }),
                              if (_productFilters.minRating != null)
                                _buildFilterChip('Rating: ${_productFilters.minRating}★+', () {
                                  setState(() {
                                    _productFilters.minRating = null;
                                    _updateProviderKeyMap();
                                  });
                                }),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              // Main Product Grid Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(productListProvider(_providerKeyMap).notifier).refresh(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      if (state.products.isEmpty && !state.isLoading)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 64, color: kMuted),
                                const SizedBox(height: 12),
                                const Text(
                                  'No products match your filters',
                                  style: TextStyle(color: kNavy, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Try clearing filters or searching for something else.',
                                  style: TextStyle(color: kMuted, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _resetFilters,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryOrange,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Reset All Filters'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.58,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => ProductCard(product: state.products[index]),
                              childCount: state.products.length,
                            ),
                          ),
                        ),
                        if (state.isLoading)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(Color(0xFFFF5722)),
                                ),
                              ),
                            ),
                          ),
                        if (state.error != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(kPad),
                              child: Center(child: Text('Error: ${state.error}')),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Hanging Search & Filter Overlay Div anchored EXACTLY below search box
          if (_isOverlayOpen)
            Positioned(
              top: 52,
              left: 0,
              right: 0,
              bottom: 0,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isOverlayOpen = false),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: availableOverlayHeight,
                      ),
                      child: SingleChildScrollView(
                        child: HangingSearchFilterOverlay(
                          isFilterTab: _isFilterTab,
                          searchQuery: _searchQuery,
                          searchController: _searchController,
                          minPriceController: _minPriceController,
                          maxPriceController: _maxPriceController,
                          priceRangeValues: _priceRangeValues,
                          selectedRating: _selectedRating,
                          selectedBrands: _selectedBrands,
                          selectedCategories: _selectedCategories,
                          categories: categories,
                          brands: brands,
                          products: allProducts,
                          onFilterTabChanged: (isFilter) {
                            setState(() => _isFilterTab = isFilter);
                          },
                          onSearchQueryChanged: (query) {
                            setState(() {
                              _searchQuery = query;
                              _productFilters.search = query.isNotEmpty ? query : null;
                              _updateProviderKeyMap();
                            });
                          },
                          onPriceRangeChanged: (range) {
                            setState(() => _priceRangeValues = range);
                          },
                          onRatingChanged: (rating) {
                            setState(() => _selectedRating = rating);
                          },
                          onReset: _resetFilters,
                          onClose: () => setState(() => _isOverlayOpen = false),
                          onSelectProduct: (product) {
                            setState(() => _isOverlayOpen = false);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paleOrange,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 12, color: AppColors.primaryOrange),
          ),
        ],
      ),
    );
  }
}
