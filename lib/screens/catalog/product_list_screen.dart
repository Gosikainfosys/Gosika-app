import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../models/product_filters.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/filter_sheet.dart';
import '../../widgets/product_card.dart';

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
  late ProductFilters _productFilters;
  late Map<String, dynamic> _providerKeyMap;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider(_providerKeyMap).notifier).loadNextPage();
    }
  }

  void _openFilterSheet() {
    final categories = ref.read(categoriesProvider).value ?? [];
    final brands = ref.read(brandsProvider).value ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        categories: categories,
        brands: brands,
        initialFilters: _productFilters,
        onApply: (appliedFilters) {
          setState(() {
            _productFilters = appliedFilters;
            _updateProviderKeyMap();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider(_providerKeyMap));
    final categories = ref.watch(categoriesProvider).value ?? [];

    String categoryNameLabel = _productFilters.category ?? '';
    if (categoryNameLabel.isNotEmpty && categories.isNotEmpty) {
      final match = categories.firstWhere(
        (c) => c.id == categoryNameLabel || c.slug == categoryNameLabel,
        orElse: () => Category(id: categoryNameLabel, name: categoryNameLabel, slug: categoryNameLabel),
      );
      categoryNameLabel = match.name;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title ?? (_productFilters.search != null ? 'Search: "${_productFilters.search}"' : 'Shop'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kNavy),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: kNavy),
            onPressed: () => context.push('/search'),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: kNavy),
                onPressed: _openFilterSheet,
              ),
              if (_productFilters.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${_productFilters.activeFilterCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Filters Chip Row
          if (_productFilters.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.grey[50],
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16, color: AppColors.primaryOrange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
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
                          if (_productFilters.lat != null)
                            _buildFilterChip('Near Me📍', () {
                              setState(() {
                                _productFilters.lat = null;
                                _productFilters.lng = null;
                                _updateProviderKeyMap();
                              });
                            }),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _productFilters.reset();
                        _updateProviderKeyMap();
                      });
                    },
                    child: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 11)),
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
                              onPressed: () {
                                setState(() {
                                  _productFilters.reset();
                                  _updateProviderKeyMap();
                                });
                              },
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
                          childAspectRatio: 0.64,
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
