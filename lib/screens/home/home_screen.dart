import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/deal_product.dart';
import '../../models/product.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/cart_icon_badge.dart';
import '../../widgets/cart_bottom_sheet.dart';
import 'widgets/category_carousel.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/modern_product_card.dart';
import 'widgets/promo_banner.dart';
import 'widgets/section_header.dart';
import 'widgets/trust_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey _cartIconKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Overlay & Search/Filter state
  bool _isOverlayOpen = false;
  bool _isFilterTab = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSort = 'Relevance';

  RangeValues _priceRangeValues = const RangeValues(0, 150000);
  int? _selectedRating;
  final Set<String> _selectedBrands = {};
  final Set<String> _selectedCategories = {};
  bool _showMoreBrands = false;

  static const List<ModernProductData> _fallbackDeals = [
    ModernProductData(
      id: 'watermelon-1kg',
      title: 'Fresh Watermelon 1kg',
      subtitle: 'Fresh & Juicy',
      imageUrl:
          'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400',
      currentPrice: 'Rs. 1,200',
      oldPrice: 'Rs. 2,000',
      discountBadge: '-40%',
      rating: 4.5,
      reviewsCount: 120,
    ),
    ModernProductData(
      id: 'backpack-50l',
      title: 'Hiking Backpack 50L',
      subtitle: 'For Your Next Adventure',
      imageUrl:
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
      currentPrice: 'Rs. 3,750',
      oldPrice: 'Rs. 5,000',
      discountBadge: '-25%',
      rating: 4.6,
      reviewsCount: 210,
    ),
    ModernProductData(
      id: 'wireless-headphones',
      title: 'Wireless Headphones',
      subtitle: 'Noise Cancelling',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
      currentPrice: 'Rs. 4,500',
      oldPrice: 'Rs. 6,000',
      discountBadge: '-25%',
      rating: 4.8,
      reviewsCount: 340,
    ),
    ModernProductData(
      id: 'running-shoes',
      title: 'Pro Running Shoes',
      subtitle: 'Ultra Lightweight',
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
      currentPrice: 'Rs. 3,200',
      oldPrice: 'Rs. 4,500',
      discountBadge: '-28%',
      rating: 4.7,
      reviewsCount: 185,
    ),
  ];

  static const List<ModernProductData> _fallbackFeatured = [
    ModernProductData(
      id: 'laptop-dell-15',
      title: 'Dell Inspiron 15 Laptop',
      subtitle: 'Electronics & Computers',
      imageUrl:
          'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=400',
      currentPrice: 'Rs. 76,500',
      oldPrice: 'Rs. 90,000',
      discountBadge: '-15%',
      rating: 4.6,
      reviewsCount: 856,
    ),
    ModernProductData(
      id: 'laptop-lenovo-slim3',
      title: 'Lenovo IdeaPad Slim 3',
      subtitle: 'Electronics & Computers',
      imageUrl:
          'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=400',
      currentPrice: 'Rs. 48,000',
      oldPrice: 'Rs. 60,000',
      discountBadge: '-20%',
      rating: 4.5,
      reviewsCount: 724,
    ),
    ModernProductData(
      id: 'laptop-asus-rog',
      title: 'Asus ROG Gaming Laptop',
      subtitle: 'Gaming & Performance',
      imageUrl:
          'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=400',
      currentPrice: 'Rs. 115,000',
      oldPrice: 'Rs. 135,000',
      discountBadge: '-14%',
      rating: 4.9,
      reviewsCount: 412,
    ),
    ModernProductData(
      id: 'laptop-hp-pavilion',
      title: 'HP Pavilion 14 Laptop',
      subtitle: 'Business & Office',
      imageUrl:
          'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400',
      currentPrice: 'Rs. 64,000',
      oldPrice: 'Rs. 75,000',
      discountBadge: '-14%',
      rating: 4.7,
      reviewsCount: 310,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  ModernProductData _mapDealProduct(DealProduct deal) {
    final img = ApiClient.apiImage(deal.imageUrl);
    final disc = deal.discountPercentage > 0 ? '-${deal.discountPercentage}%' : '';

    final product = Product(
      id: deal.id,
      name: deal.name,
      slug: deal.slug,
      shortDescription: deal.brandName,
      price: deal.price,
      compareAtPrice: deal.compareAtPrice,
      image: img,
      images: img.isNotEmpty ? [img] : [],
      variants: [],
      ratingAvg: deal.ratingAvg,
      ratingCount: deal.ratingCount,
      isFeatured: false,
      status: 'active',
      stockStatus: deal.stockStatus,
    );

    return ModernProductData(
      id: deal.id,
      title: deal.name,
      subtitle: deal.brandName ?? 'Best Deal',
      imageUrl: img.isNotEmpty
          ? img
          : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
      currentPrice: formatNPR(deal.price),
      oldPrice: deal.compareAtPrice != null ? formatNPR(deal.compareAtPrice) : null,
      discountBadge: disc,
      rating: deal.ratingAvg > 0 ? deal.ratingAvg : 4.5,
      reviewsCount: deal.ratingCount > 0 ? deal.ratingCount : 120,
      originalProduct: product,
    );
  }

  ModernProductData _mapProduct(Product product) {
    final img = ApiClient.apiImage(product.image);
    final discPercentage = (product.compareAtPrice != null && product.compareAtPrice! > product.price)
        ? (((product.compareAtPrice! - product.price) / product.compareAtPrice!) * 100).round()
        : 0;

    return ModernProductData(
      id: product.id,
      title: product.name,
      subtitle: product.shortDescription ?? 'Featured Item',
      imageUrl: img.isNotEmpty
          ? img
          : 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
      currentPrice: formatNPR(product.price),
      oldPrice: product.compareAtPrice != null ? formatNPR(product.compareAtPrice) : null,
      discountBadge: discPercentage > 0 ? '-$discPercentage%' : '',
      rating: product.ratingAvg > 0 ? product.ratingAvg : 4.6,
      reviewsCount: product.ratingCount > 0 ? product.ratingCount : 90,
      originalProduct: product,
    );
  }

  void _openOverlay({bool isFilter = false}) {
    setState(() {
      _isOverlayOpen = true;
      _isFilterTab = isFilter;
    });
  }

  void _closeOverlay() {
    setState(() {
      _isOverlayOpen = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedSort = 'Relevance';
      _priceRangeValues = const RangeValues(0, 150000);
      _selectedRating = null;
      _selectedBrands.clear();
      _selectedCategories.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaTopPadding = MediaQuery.of(context).padding.top;

    // Real API state subscriptions
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final addressAsync = ref.watch(addressListProvider);
    final notificationAsync = ref.watch(notificationListProvider);

    final bannersAsync = ref.watch(bannersProvider);
    final campaignsAsync = ref.watch(campaignsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final dealsAsync = ref.watch(dealsProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);
    final allProductsAsync = ref.watch(allProductsProvider);

    // Real API User Info
    final String userName = user != null
        ? (user.fullName.isNotEmpty
            ? user.fullName
            : (user.firstName.isNotEmpty ? user.firstName : 'User'))
        : 'Sital';

    final String? userAvatarUrl = user?.avatarUrl;

    String locationText = 'Kathmandu, Nepal';
    if (addressAsync.value != null && addressAsync.value!.isNotEmpty) {
      final addresses = addressAsync.value!;
      final defaultAddr = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );
      final cityStr = defaultAddr.municipality?.name ?? defaultAddr.district?.name ?? defaultAddr.addressLine1;
      final stateStr = defaultAddr.province?.name ?? defaultAddr.country?.name ?? 'Nepal';
      locationText = cityStr.isNotEmpty ? '$cityStr, $stateStr' : 'Kathmandu, Nepal';
    }

    final int notificationCount = notificationAsync.value?.unreadCount ?? 3;

    final bool isSearchingOrFiltered = _searchQuery.isNotEmpty ||
        _selectedBrands.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _selectedRating != null ||
        _priceRangeValues.start > 0 ||
        _priceRangeValues.end < 150000;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primaryOrange,
            onRefresh: () async {
              ref.invalidate(bannersProvider);
              ref.invalidate(campaignsProvider);
              ref.invalidate(categoriesProvider);
              ref.invalidate(dealsProvider);
              ref.invalidate(featuredProductsProvider);
              ref.invalidate(allProductsProvider);
              ref.invalidate(addressListProvider);
              ref.invalidate(notificationListProvider);
            },
            child: CustomScrollView(
              slivers: [
                // 1. PINNED COLLAPSING HEADER WITH SMOOTH SEARCH & CART SLIDING ANIMATION
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CollapsingSearchCartHeaderDelegate(
                    topPadding: mediaTopPadding,
                    cartIconKey: _cartIconKey,
                    userName: userName,
                    locationText: locationText,
                    userAvatarUrl: userAvatarUrl,
                    notificationCount: notificationCount,
                    searchController: _searchController,
                    onSearchTap: () => _openOverlay(isFilter: false),
                    onSearchChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _isOverlayOpen = true;
                        _isFilterTab = false;
                      });
                    },
                    onFilterTap: () => _openOverlay(isFilter: true),
                    onProfileTap: () => context.push('/account'),
                    onNotificationTap: () => context.push('/notifications'),
                    onCartTap: () => CartBottomSheet.show(context),
                  ),
                ),

                // 2. MAIN SCROLLABLE CONTENT
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // ACTIVE SEARCH & FILTER RESULTS HEADER & CHIPS (SCREENSHOT 2 VIEW)
                        if (isSearchingOrFiltered) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Search Results for "${_searchQuery.isNotEmpty ? _searchQuery : 'Filter Results'}"',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.darkText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Showing 1–12 of 245 products',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _openOverlay(isFilter: true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.paleOrange,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.tune_rounded, size: 14, color: AppColors.primaryOrange),
                                        SizedBox(width: 4),
                                        Text(
                                          'Filter',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                PopupMenuButton<String>(
                                  initialValue: _selectedSort,
                                  onSelected: (val) => setState(() => _selectedSort = val),
                                  itemBuilder: (context) => ['Relevance', 'Price: Low to High', 'Price: High to Low', 'Top Rated'].map((s) {
                                    return PopupMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)));
                                  }).toList(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.darkText),
                                        SizedBox(width: 4),
                                        Text('Sort', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkText)),
                                        Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.darkText),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Applied Filter Chips Row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                if (_priceRangeValues.start > 0 || _priceRangeValues.end < 150000)
                                  _buildActiveFilterChip(
                                    'Price: NPR ${(_priceRangeValues.start / 1000).round()}k – ${(_priceRangeValues.end / 1000).round()}k',
                                    () => setState(() => _priceRangeValues = const RangeValues(0, 150000)),
                                  ),
                                if (_selectedRating != null)
                                  _buildActiveFilterChip(
                                    '★ ${_selectedRating}+ Rating',
                                    () => setState(() => _selectedRating = null),
                                  ),
                                ..._selectedBrands.map((b) => _buildActiveFilterChip('Brand: $b', () {
                                  setState(() => _selectedBrands.remove(b));
                                })),
                                ..._selectedCategories.map((c) => _buildActiveFilterChip('Cat: $c', () {
                                  setState(() => _selectedCategories.remove(c));
                                })),
                                TextButton.icon(
                                  onPressed: _resetFilters,
                                  icon: const Icon(Icons.refresh_rounded, size: 13, color: AppColors.primaryOrange),
                                  label: const Text('Clear All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // HERO PROMOTIONAL BANNER SECTION WITH REAL API BANNERS (/api/v1/banners)
                        if (!isSearchingOrFiltered) ...[
                          bannersAsync.when(
                            data: (banners) => PromoBanner(banners: banners),
                            loading: () => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                height: 170,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                            ),
                            error: (err, stack) => campaignsAsync.when(
                              data: (campaigns) => PromoBanner(campaigns: campaigns),
                              loading: () => const PromoBanner(),
                              error: (e, s) => const PromoBanner(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // TRUST / ADVANTAGE BANNER (2x2 Grid)
                          const TrustBanner(),

                          const SizedBox(height: 20),

                          // SHOP BY CATEGORIES SECTION
                          SectionHeader(
                            title: 'Shop by Categories',
                            showOrangeBar: true,
                            actionText: 'View All',
                            onSeeAllTap: () => context.push('/shop'),
                          ),
                          const SizedBox(height: 12),

                          categoriesAsync.when(
                            data: (categories) => CategoryCarousel(apiCategories: categories),
                            loading: () => const CategoryCarousel(),
                            error: (err, stack) => const CategoryCarousel(),
                          ),

                          const SizedBox(height: 22),

                          // TODAY'S DEALS / BEST DEALS SECTION
                          SectionHeader(
                            title: "Today's Deals",
                            iconEmoji: '🔥',
                            actionText: 'See All',
                            onSeeAllTap: () => context.push('/shop'),
                          ),
                          const SizedBox(height: 12),

                          dealsAsync.when(
                            data: (deals) {
                              final list = deals.isNotEmpty
                                  ? deals.map(_mapDealProduct).toList()
                                  : _fallbackDeals;
                              return SizedBox(
                                height: 250,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: list.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: ModernProductCard(
                                        product: list[index],
                                        cartIconKey: _cartIconKey,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            loading: () => SizedBox(
                              height: 250,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _fallbackDeals.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ModernProductCard(
                                      product: _fallbackDeals[index],
                                      cartIconKey: _cartIconKey,
                                    ),
                                  );
                                },
                              ),
                            ),
                            error: (err, stack) => SizedBox(
                              height: 250,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _fallbackDeals.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ModernProductCard(
                                      product: _fallbackDeals[index],
                                      cartIconKey: _cartIconKey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),
                        ],

                        // FEATURED PRODUCTS / SEARCH RESULTS GRID SECTION
                        SectionHeader(
                          title: isSearchingOrFiltered ? 'Search Products' : 'Featured Products',
                          iconEmoji: isSearchingOrFiltered ? '🔍' : '👑',
                          actionText: 'See All',
                          onSeeAllTap: () => context.push('/shop'),
                        ),
                        const SizedBox(height: 12),

                        featuredAsync.when(
                          data: (products) {
                            final list = _getFilteredProductList(
                              products.isNotEmpty ? products.map(_mapProduct).toList() : _fallbackFeatured,
                            );

                            if (list.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Text('No products match your selected filters.', style: TextStyle(color: Colors.grey)),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: list.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemBuilder: (context, index) {
                                  return ModernProductCard(
                                    product: list[index],
                                    cartIconKey: _cartIconKey,
                                  );
                                },
                              ),
                            );
                          },
                          loading: () => SizedBox(
                            height: 250,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _fallbackFeatured.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ModernProductCard(
                                    product: _fallbackFeatured[index],
                                    cartIconKey: _cartIconKey,
                                  ),
                                );
                              },
                            ),
                          ),
                          error: (err, stack) => SizedBox(
                            height: 250,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _fallbackFeatured.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ModernProductCard(
                                    product: _fallbackFeatured[index],
                                    cartIconKey: _cartIconKey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // EXPLORE ALL PRODUCTS GRID SECTION
                        if (!isSearchingOrFiltered) ...[
                          SectionHeader(
                            title: 'Explore Products',
                            iconEmoji: '🛍️',
                            actionText: 'View All',
                            onSeeAllTap: () => context.push('/shop'),
                          ),
                          const SizedBox(height: 12),

                          allProductsAsync.when(
                            data: (products) {
                              final list = products.isNotEmpty
                                  ? products.map(_mapProduct).toList()
                                  : _fallbackFeatured;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: list.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.72,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemBuilder: (context, index) {
                                    return ModernProductCard(
                                      product: list[index],
                                      cartIconKey: _cartIconKey,
                                    );
                                  },
                                ),
                              );
                            },
                            loading: () => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 4,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemBuilder: (context, index) {
                                  return Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            error: (err, stack) => const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Hanging Search & Filter Overlay Div anchored right below sticky header
          if (_isOverlayOpen)
            Positioned(
              top: mediaTopPadding + 56,
              left: 0,
              right: 0,
              bottom: 0,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _closeOverlay,
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
                        maxHeight: MediaQuery.of(context).size.height * 0.75,
                      ),
                      child: SingleChildScrollView(
                        child: _buildHangingOverlayDiv(allProductsAsync, categoriesAsync),
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

  List<ModernProductData> _getFilteredProductList(List<ModernProductData> sourceList) {
    return sourceList.where((p) {
      if (_searchQuery.isNotEmpty && !p.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedRating != null && p.rating < _selectedRating!) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.paleOrange,
        borderRadius: BorderRadius.circular(14),
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
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primaryOrange),
          ),
        ],
      ),
    );
  }

  // Hanging Overlay Div Widget attached directly below the search bar on Home Screen
  Widget _buildHangingOverlayDiv(
    AsyncValue<List<Product>> allProductsAsync,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    final List<Map<String, String>> sampleSuggestions = [
      {
        'title': 'Laptop',
        'subtitle': 'Electronics',
        'image': 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=300',
      },
      {
        'title': 'Gaming Laptop',
        'subtitle': 'Electronics',
        'image': 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=300',
      },
      {
        'title': 'Dell Laptop',
        'subtitle': 'Electronics',
        'image': 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=300',
      },
      {
        'title': 'Fitness Smart Watch',
        'subtitle': 'Gadgets',
        'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300',
      },
      {
        'title': 'Pro Running Shoes',
        'subtitle': 'Footwear',
        'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=300',
      },
    ];

    final filteredSuggestions = _searchQuery.isEmpty
        ? sampleSuggestions.take(3).toList()
        : sampleSuggestions.where((s) => s['title']!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar of Hanging Overlay
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isFilterTab ? Icons.tune_rounded : Icons.search_rounded,
                  color: AppColors.primaryOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isFilterTab ? 'Filters' : 'Suggestions & Nearby Search',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _resetFilters,
                child: const Text(
                  'Reset',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.darkText),
                onPressed: _closeOverlay,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const Divider(height: 16),

          // 1. NEARBY LOCATION (USE GPS BUTTON) - ALWAYS KEPT IN SEARCH DIV
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location_rounded, color: AppColors.primaryOrange, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nearby Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.darkText)),
                      Text('Kathmandu Metropolitan City, Nepal', style: TextStyle(fontSize: 10.5, color: AppColors.secondaryText)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Updated delivery location to current GPS location!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Use GPS',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MODE 1: SEARCH OVERLAY MODE (SCREENSHOT 1 MATCH)
          if (!_isFilterTab) ...[
            // Suggestions Section Header with "See all ->"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Suggestions',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.darkText),
                ),
                GestureDetector(
                  onTap: () {
                    _closeOverlay();
                  },
                  child: const Row(
                    children: [
                      Text('See all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primaryOrange),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Live Suggestion Items List
            if (filteredSuggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No matching suggestions.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              )
            else
              Column(
                children: filteredSuggestions.map((s) {
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          s['image']!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 40,
                            height: 40,
                            color: AppColors.primaryOrange.withValues(alpha: 0.1),
                            child: const Icon(Icons.laptop_mac_rounded, size: 22, color: AppColors.primaryOrange),
                          ),
                        ),
                      ),
                      title: _buildRichSuggestionTitle(s['title']!, _searchQuery),
                      subtitle: Text(s['subtitle']!, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                      onTap: () {
                        _searchController.text = s['title']!;
                        setState(() {
                          _searchQuery = s['title']!;
                        });
                        _closeOverlay();
                      },
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            // Quick Category / Brand Suggestion Chips Row (Bottom of Search Div in Screenshot 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickCategoryChip(
                    icon: Icons.grid_view_rounded,
                    iconBgColor: AppColors.primaryOrange,
                    title: 'Laptops',
                    count: '124+ products',
                    onTap: () {
                      _searchController.text = 'Laptop';
                      setState(() {
                        _searchQuery = 'Laptop';
                        _selectedCategories.add('Laptops');
                      });
                      _closeOverlay();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickCategoryChip(
                    icon: Icons.devices_rounded,
                    iconBgColor: const Color(0xFF2196F3),
                    title: 'Electronics',
                    count: '2.5k+ products',
                    onTap: () {
                      setState(() {
                        _selectedCategories.add('Electronics');
                      });
                      _closeOverlay();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickCategoryChip(
                    icon: Icons.local_offer_rounded,
                    iconBgColor: const Color(0xFF9C27B0),
                    title: 'Brands',
                    count: '50+ brands',
                    onTap: () {
                      setState(() {
                        _isFilterTab = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],

          // MODE 2: FILTER OVERLAY MODE (SCREENSHOT 2 MATCH)
          if (_isFilterTab) ...[
            // 1. Price Range (NPR) with Dual-Thumb Slider & Numeric Inputs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Price Range (NPR)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkText),
                ),
                Text(
                  'NPR ${(_priceRangeValues.start / 1000).round()}k – ${(_priceRangeValues.end / 1000).round()}k',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                ),
              ],
            ),
            RangeSlider(
              values: _priceRangeValues,
              min: 0,
              max: 150000,
              divisions: 150,
              activeColor: AppColors.primaryOrange,
              inactiveColor: Colors.grey[200],
              onChanged: (values) {
                setState(() {
                  _priceRangeValues = values;
                  _minPriceController.text = values.start.round().toString();
                  _maxPriceController.text = values.end.round().toString();
                });
              },
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: '30,000',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          setState(() => _priceRangeValues = RangeValues(parsed, _priceRangeValues.end));
                        }
                      },
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: '80,000',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          setState(() => _priceRangeValues = RangeValues(_priceRangeValues.start, parsed));
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 2. Rating Filter Option List
            const Text(
              'Rating',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            const SizedBox(height: 6),
            Column(
              children: [4, 3, 2, 1].map((stars) {
                final isSelected = _selectedRating == stars;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedRating = isSelected ? null : stars;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          size: 18,
                          color: isSelected ? AppColors.primaryOrange : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: i < stars ? const Color(0xFFFFB800) : Colors.grey[300],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$stars & above',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // 3. Brand Filter Checkboxes
            const Text(
              'Brand',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            const SizedBox(height: 4),
            ...[
              {'name': 'Dell', 'count': 12},
              {'name': 'HP', 'count': 10},
              {'name': 'Lenovo', 'count': 8},
              {'name': 'Asus', 'count': 6},
              if (_showMoreBrands) ...[
                {'name': 'Apple', 'count': 15},
                {'name': 'Samsung', 'count': 9},
              ],
            ].map((b) {
              final brandName = b['name'] as String;
              final isChecked = _selectedBrands.contains(brandName);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      _selectedBrands.remove(brandName);
                    } else {
                      _selectedBrands.add(brandName);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: isChecked,
                          activeColor: AppColors.primaryOrange,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedBrands.add(brandName);
                              } else {
                                _selectedBrands.remove(brandName);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(brandName, style: const TextStyle(fontSize: 12, color: AppColors.darkText)),
                      const SizedBox(width: 4),
                      Text('(${b['count']})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: () => setState(() => _showMoreBrands = !_showMoreBrands),
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                  children: [
                    Text(
                      _showMoreBrands ? 'See Less' : 'See More',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
                    ),
                    Icon(_showMoreBrands ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: AppColors.primaryOrange),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 4. Category Checkboxes
            const Text(
              'Category',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            const SizedBox(height: 4),
            ...[
              {'name': 'Laptops', 'count': 24},
              {'name': 'Gaming Laptops', 'count': 12},
              {'name': 'Business Laptops', 'count': 8},
              {'name': '2-in-1 Laptops', 'count': 4},
            ].map((c) {
              final catName = c['name'] as String;
              final isChecked = _selectedCategories.contains(catName);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      _selectedCategories.remove(catName);
                    } else {
                      _selectedCategories.add(catName);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: isChecked,
                          activeColor: AppColors.primaryOrange,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedCategories.add(catName);
                              } else {
                                _selectedCategories.remove(catName);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(catName, style: const TextStyle(fontSize: 12, color: AppColors.darkText)),
                      const SizedBox(width: 4),
                      Text('(${c['count']})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 16),

          // Apply & Search Actions Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                _closeOverlay();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                elevation: 2,
              ),
              child: Text(
                _isFilterTab ? 'Apply Filters & View Results' : 'Search & View Results',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichSuggestionTitle(String title, String query) {
    if (query.isEmpty) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
      );
    }
    final index = title.toLowerCase().indexOf(query.toLowerCase());
    if (index == -1) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
      );
    }
    final before = title.substring(0, index);
    final match = title.substring(index, index + query.length);
    final after = title.substring(index + query.length);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppColors.darkText),
        children: [
          TextSpan(text: before),
          TextSpan(text: match, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText)),
          TextSpan(text: after),
        ],
      ),
    );
  }

  Widget _buildQuickCategoryChip({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconBgColor),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Collapsing Header Delegate for smooth scrolling interpolation of Search Bar & Cart Button
class _CollapsingSearchCartHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final GlobalKey cartIconKey;
  final String userName;
  final String locationText;
  final String? userAvatarUrl;
  final int notificationCount;
  final TextEditingController searchController;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onCartTap;

  _CollapsingSearchCartHeaderDelegate({
    required this.topPadding,
    required this.cartIconKey,
    required this.userName,
    required this.locationText,
    this.userAvatarUrl,
    required this.notificationCount,
    required this.searchController,
    required this.onSearchTap,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.onProfileTap,
    required this.onNotificationTap,
    required this.onCartTap,
  });

  static const double _deliveryStripHeight = 26.0;
  static const double _headerHeight = 54.0;
  static const double _searchBarHeight = 44.0;
  static const double _bottomPadding = 8.0;

  @override
  double get minExtent => topPadding + _searchBarHeight + 12.0;

  @override
  double get maxExtent => topPadding + _deliveryStripHeight + _headerHeight + _searchBarHeight + _bottomPadding + 8.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double maxScrollable = maxExtent - minExtent;
    final double progress = maxScrollable > 0 ? (shrinkOffset / maxScrollable).clamp(0.0, 1.0) : 0.0;

    // Delivery strip collapses & fades out
    final double currentDeliveryHeight = _deliveryStripHeight * (1.0 - progress);
    final double deliveryOpacity = (1.0 - progress * 1.5).clamp(0.0, 1.0);

    // Profile header collapses & fades out
    final double profileOpacity = (1.0 - progress * 1.8).clamp(0.0, 1.0);

    // Interpolate search bar position & width
    final double searchTop = (topPadding + _deliveryStripHeight + _headerHeight + 4) * (1.0 - progress) + (topPadding + 6) * progress;
    final double searchRightMargin = 16.0 * (1.0 - progress) + 68.0 * progress;

    // Interpolate Cart Button position & sliding
    final double cartTop = (topPadding + _deliveryStripHeight + 6) * (1.0 - progress) + (topPadding + 6) * progress;
    final double cartRight = 64.0 * (1.0 - progress) + 16.0 * progress;

    return Container(
      color: AppColors.creamBackground,
      child: Stack(
        children: [
          // 1. Status Bar Fill (Orange)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding,
            child: Container(color: AppColors.primaryOrange),
          ),

          // 2. Top Delivery Strip ("Delivering across Nepal")
          if (currentDeliveryHeight > 0)
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              height: currentDeliveryHeight,
              child: Opacity(
                opacity: deliveryOpacity,
                child: Container(
                  color: AppColors.primaryOrange,
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_outlined, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Delivering across Nepal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. User Profile Header (Avatar, Name, Location, Notification Bell)
          if (profileOpacity > 0)
            Positioned(
              top: topPadding + currentDeliveryHeight,
              left: 16,
              right: 16,
              height: _headerHeight,
              child: Opacity(
                opacity: profileOpacity,
                child: Row(
                  children: [
                    // Profile Avatar
                    GestureDetector(
                      onTap: onProfileTap,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryOrange.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x18000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: userAvatarUrl != null && userAvatarUrl!.isNotEmpty
                            ? Image.network(
                                userAvatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(userName),
                              )
                            : _buildFallbackAvatar(userName),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // User Name & Location Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hello, $userName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.heading2.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkText,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('👋', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  locationText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.secondaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText, size: 16),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Notification Bell Circle Button
                    GestureDetector(
                      onTap: onNotificationTap,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.notifications_outlined, color: AppColors.darkText, size: 20),
                          ),
                          if (notificationCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '$notificationCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Smoothly sliding & Contracting Main Search Bar
          Positioned(
            top: searchTop,
            left: 16,
            right: searchRightMargin,
            height: _searchBarHeight,
            child: HomeSearchBar(
              controller: searchController,
              hintText: 'Would you like to buy something?',
              onTap: onSearchTap,
              onChanged: onSearchChanged,
              onFilterTap: onFilterTap,
              margin: EdgeInsets.zero,
            ),
          ),

          // 5. Smoothly sliding Cart Button
          Positioned(
            top: cartTop,
            right: cartRight,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Center(
                child: CartIconBadge(
                  iconKey: cartIconKey,
                  onTap: onCartTap,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : (parts.isNotEmpty ? parts[0][0] : 'U');

    return Container(
      color: AppColors.primaryOrange.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsingSearchCartHeaderDelegate oldDelegate) {
    return topPadding != oldDelegate.topPadding ||
        userName != oldDelegate.userName ||
        locationText != oldDelegate.locationText ||
        userAvatarUrl != oldDelegate.userAvatarUrl ||
        notificationCount != oldDelegate.notificationCount;
  }
}
