import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../models/deal_product.dart';
import '../../models/product.dart';
import '../../providers/catalog_provider.dart';
import 'widgets/category_carousel.dart';
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
      id: 'green-hoodie',
      title: 'Green Comfort Hoodie',
      subtitle: 'Premium Cotton Blend',
      imageUrl:
          'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=400',
      currentPrice: 'Rs. 2,400',
      oldPrice: 'Rs. 3,000',
      discountBadge: '-20%',
      rating: 4.6,
      reviewsCount: 88,
    ),
    ModernProductData(
      id: 'smart-watch',
      title: 'Fitness Smart Watch',
      subtitle: 'Heart & Sleep Tracker',
      imageUrl:
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
      currentPrice: 'Rs. 5,800',
      oldPrice: 'Rs. 6,800',
      discountBadge: '-15%',
      rating: 4.9,
      reviewsCount: 412,
    ),
    ModernProductData(
      id: 'women-handbag',
      title: "Women's Leather Handbag",
      subtitle: 'Elegant & Spacious',
      imageUrl:
          'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400',
      currentPrice: 'Rs. 3,500',
      oldPrice: 'Rs. 5,000',
      discountBadge: '-30%',
      rating: 4.5,
      reviewsCount: 96,
    ),
    ModernProductData(
      id: 'classic-sneakers',
      title: 'White Classic Sneakers',
      subtitle: 'Everyday Casual',
      imageUrl:
          'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=400',
      currentPrice: 'Rs. 4,200',
      oldPrice: 'Rs. 5,400',
      discountBadge: '-22%',
      rating: 4.7,
      reviewsCount: 150,
    ),
  ];

  ModernProductData _mapDealProduct(DealProduct deal) {
    final img = ApiClient.apiImage(deal.imageUrl);
    final disc = deal.discountPercentage > 0 ? '-${deal.discountPercentage}%' : '';

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
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaTopPadding = MediaQuery.of(context).padding.top;

    final campaignsAsync = ref.watch(campaignsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final dealsAsync = ref.watch(dealsProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);
    final allProductsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: RefreshIndicator(
        color: AppColors.primaryOrange,
        onRefresh: () async {
          ref.invalidate(campaignsProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(dealsProvider);
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(allProductsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // 1. PINNED STICKY HEADER (Delivery bar collapses up on scroll)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHomeHeaderDelegate(
                topPadding: mediaTopPadding,
                onSearchTap: () => context.push('/search'),
                onProfileTap: () => context.push('/account'),
                onCartTap: () => context.push('/cart'),
              ),
            ),

            // 2. HOME MAIN SCROLLABLE CONTENT
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // PROMOTIONAL BANNER SECTION
                    campaignsAsync.when(
                      data: (campaigns) => PromoBanner(campaigns: campaigns),
                      loading: () => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                      error: (err, stack) => const PromoBanner(),
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
                          height: 260,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ModernProductCard(product: list[index]),
                              );
                            },
                          ),
                        );
                      },
                      loading: () => SizedBox(
                        height: 260,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _fallbackDeals.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ModernProductCard(product: _fallbackDeals[index]),
                            );
                          },
                        ),
                      ),
                      error: (err, stack) => SizedBox(
                        height: 260,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _fallbackDeals.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ModernProductCard(product: _fallbackDeals[index]),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // FEATURED PRODUCTS SECTION
                    SectionHeader(
                      title: 'Featured Products',
                      iconEmoji: '👑',
                      actionText: 'See All',
                      onSeeAllTap: () => context.push('/shop'),
                    ),
                    const SizedBox(height: 12),

                    featuredAsync.when(
                      data: (products) {
                        final list = products.isNotEmpty
                            ? products.map(_mapProduct).toList()
                            : _fallbackFeatured;
                        return SizedBox(
                          height: 260,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ModernProductCard(product: list[index]),
                              );
                            },
                          ),
                        );
                      },
                      loading: () => SizedBox(
                        height: 260,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _fallbackFeatured.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ModernProductCard(product: _fallbackFeatured[index]),
                            );
                          },
                        ),
                      ),
                      error: (err, stack) => SizedBox(
                        height: 260,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _fallbackFeatured.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ModernProductCard(product: _fallbackFeatured[index]),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // EXPLORE ALL PRODUCTS GRID SECTION (Vertical multiple rows)
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
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemBuilder: (context, index) {
                              return ModernProductCard(product: list[index]);
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
                            childAspectRatio: 0.68,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyHomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;
  final VoidCallback onCartTap;

  _StickyHomeHeaderDelegate({
    required this.topPadding,
    required this.onSearchTap,
    required this.onProfileTap,
    required this.onCartTap,
  });

  static const double _topStripHeight = 28.0;
  static const double _headerRowHeight = 56.0;

  @override
  double get minExtent => topPadding + _headerRowHeight;

  @override
  double get maxExtent => topPadding + _topStripHeight + _headerRowHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double collapseRatio =
        (shrinkOffset / _topStripHeight).clamp(0.0, 1.0);
    final double currentStripHeight = _topStripHeight * (1.0 - collapseRatio);
    final bool isPinned = shrinkOffset > 5;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: isPinned
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Status bar background fill
          Container(
            height: topPadding,
            color: AppColors.primaryOrange,
          ),

          // 1. Top Delivery Strip ("Delivering across Nepal")
          if (currentStripHeight > 0)
            SizedBox(
              height: currentStripHeight,
              child: ClipRect(
                child: Container(
                  width: double.infinity,
                  color: AppColors.primaryOrange,
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: (1.0 - collapseRatio).clamp(0.0, 1.0),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          color: AppColors.white,
                          size: 15,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Delivering across Nepal',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 2. Main Header Row (Logo, Search Bar, Profile, Cart)
          SizedBox(
            height: _headerRowHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Logo Circle
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      AppAssets.logo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.shopping_bag_rounded,
                        color: AppColors.primaryOrange,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Search Bar Input (Pill shape)
                  Expanded(
                    child: GestureDetector(
                      onTap: onSearchTap,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.only(left: 14, right: 3),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Search products or brand...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryOrange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                color: AppColors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Profile Icon
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.darkText,
                        size: 23,
                      ),
                    ),
                  ),

                  // Cart Icon with Badge
                  GestureDetector(
                    onTap: onCartTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppColors.darkText,
                            size: 23,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 15,
                              minHeight: 15,
                            ),
                            child: const Text(
                              '0',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
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
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHomeHeaderDelegate oldDelegate) {
    return topPadding != oldDelegate.topPadding;
  }
}
