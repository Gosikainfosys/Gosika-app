import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/hanging_search_filter_overlay.dart';
import '../home/widgets/home_search_bar.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  bool _isOverlayOpen = false;
  bool _isFilterTab = false;
  String _searchQuery = '';

  RangeValues _priceRangeValues = const RangeValues(0, 150000);
  int? _selectedRating;
  final Set<String> _selectedBrands = {};
  final Set<String> _selectedCategories = {};

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final brandsAsync = ref.watch(brandsProvider);
    final allProductsAsync = ref.watch(allProductsProvider);

    final mediaTopPadding = MediaQuery.of(context).padding.top;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final double availableOverlayHeight = (MediaQuery.of(context).size.height - mediaTopPadding - 110 - keyboardHeight)
        .clamp(120.0, MediaQuery.of(context).size.height * 0.70);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Categories',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kNavy),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Modern HomeSearchBar
              HomeSearchBar(
                controller: _searchController,
                hintText: 'Search in categories...',
                onTap: () {
                  setState(() => _isOverlayOpen = true);
                },
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
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
              const SizedBox(height: 12),

              // Categories List Content
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) {
                    final filtered = _searchQuery.isEmpty
                        ? categories
                        : categories.where((c) => c.name.toLowerCase().contains(_searchQuery)).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.category_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? 'No categories available' : 'No categories matching "$_searchQuery"',
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final category = filtered[index];
                        return _buildCategoryCard(context, category);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF5722))),
                  ),
                  error: (err, stack) => Center(child: Text('Error loading categories: $err')),
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
                          categories: categoriesAsync.value ?? [],
                          brands: brandsAsync.value ?? [],
                          products: allProductsAsync.value ?? [],
                          onFilterTabChanged: (isFilter) {
                            setState(() => _isFilterTab = isFilter);
                          },
                          onSearchQueryChanged: (query) {
                            setState(() => _searchQuery = query);
                          },
                          onPriceRangeChanged: (range) {
                            setState(() => _priceRangeValues = range);
                          },
                          onRatingChanged: (rating) {
                            setState(() => _selectedRating = rating);
                          },
                          onReset: _resetFilters,
                          onClose: () => setState(() => _isOverlayOpen = false),
                          onSelectCategory: (catName) {
                            setState(() {
                              _searchQuery = catName.toLowerCase();
                              _isOverlayOpen = false;
                            });
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

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return InkWell(
      onTap: () {
        context.push('/categories/${category.id}?name=${Uri.encodeComponent(category.name)}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.paleOrange,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: (category.image != null && category.image!.isNotEmpty)
                  ? Image.network(
                      ApiClient.apiImage(category.image),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          category.icon ?? '📦',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        category.icon ?? '📦',
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: kNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Text(
                        'Browse products & filter',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.tune_rounded, size: 12, color: AppColors.primaryOrange),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }
}
