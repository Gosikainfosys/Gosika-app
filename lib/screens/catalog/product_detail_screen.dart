import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/catalog_provider.dart';
import '../../models/product.dart';
import '../../widgets/wishlist_heart_button.dart';
import '../../widgets/add_to_cart_button.dart';
import '../../widgets/cart_icon_badge.dart';
import '../../widgets/cart_bottom_sheet.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;
  ProductVariant? _selectedVariant;
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _cartIconKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kNavy, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Details',
          style: TextStyle(
            color: kNavy,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: kNavy, size: 22),
            onPressed: () {},
          ),
          WishlistHeartButton(
            productId: widget.productId,
            showBackground: false,
            size: 22,
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CartIconBadge(
              iconKey: _cartIconKey,
              onTap: () => CartBottomSheet.show(context),
              iconColor: kNavy,
              size: 22,
            ),
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (_selectedVariant == null && product.variants.isNotEmpty) {
            _selectedVariant = product.variants.first;
          }

          final imageList = product.images.isNotEmpty ? product.images : [product.image ?? ''];
          final discount = (product.compareAtPrice != null && product.compareAtPrice! > product.price)
              ? (((product.compareAtPrice! - product.price) / product.compareAtPrice!) * 100).round()
              : 0;

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. Hero Product Image View (Matching Design Template)
                Container(
                  height: 280,
                  width: double.infinity,
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
                        itemCount: imageList.length,
                        onPageChanged: (index) => setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          final imgWidget = Center(
                            child: CachedNetworkImage(
                              imageUrl: imageList[index],
                              fit: BoxFit.contain,
                              height: 240,
                              httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                              ),
                            ),
                          );

                          if (index == 0) {
                            return KeyedSubtree(
                              key: _imageKey,
                              child: imgWidget,
                            );
                          }
                          return imgWidget;
                        },
                      ),

                      // Page Indicator Dots
                      if (imageList.length > 1)
                        Positioned(
                          bottom: 4,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              imageList.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: index == _currentImageIndex ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: index == _currentImageIndex
                                      ? AppColors.primaryOrange
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 2. White Sheet Overlay with Curved Top Corners (Template matching mockups)
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle Bar Indicator
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Discount & Stock Badges
                      Row(
                        children: [
                          if (discount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$discount% OFF',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (product.stockStatus == 'low_stock')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Low Stock',
                                style: TextStyle(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      if (discount > 0 || product.stockStatus == 'low_stock') const SizedBox(height: 10),

                      // Product Name
                      Text(
                        product.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kNavy, height: 1.25),
                      ),
                      const SizedBox(height: 8),

                      // Rating & Verified Badge Row
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < product.ratingAvg.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 18,
                              color: const Color(0xFFFFB800),
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            '${product.ratingAvg.toStringAsFixed(1)} (${product.ratingCount} reviews)',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_rounded, size: 14, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price Row (App Primary Orange Theme)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formatNPR(_selectedVariant?.price ?? product.price),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          if (product.compareAtPrice != null && product.compareAtPrice! > product.price) ...[
                            const SizedBox(width: 10),
                            Text(
                              formatNPR(product.compareAtPrice),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Perks Row
                      Row(
                        children: [
                          _buildPerkCard(Icons.local_shipping_outlined, 'Free Shipping', 'Above रु1,000'),
                          const SizedBox(width: 8),
                          _buildPerkCard(Icons.payments_outlined, 'COD Available', 'Pay on delivery'),
                          const SizedBox(width: 8),
                          _buildPerkCard(Icons.published_with_changes, '7 Days Return', 'Easy returns'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Variants Selection
                      if (product.variants.isNotEmpty) ...[
                        const Text('Select Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.variants.map((v) {
                            final isSelected = _selectedVariant?.id == v.id;
                            return ChoiceChip(
                              label: Text(v.name ?? 'Default'),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedVariant = v);
                              },
                              selectedColor: AppColors.primaryOrange,
                              backgroundColor: const Color(0xFFF3F4F6),
                              side: BorderSide(
                                color: isSelected ? AppColors.primaryOrange : Colors.transparent,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : kNavy,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Description Section
                      const Text('Product Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kNavy)),
                      const SizedBox(height: 8),
                      Text(
                        product.description ?? product.shortDescription ?? 'High-quality authentic product crafted with standard materials for lasting satisfaction.',
                        style: TextStyle(color: Colors.grey[800], height: 1.5, fontSize: 13),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange)),
        ),
        error: (err, stack) => Center(child: Text('Error loading product: $err')),
      ),
      bottomSheet: productAsync.maybeWhen(
        data: (product) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: AddToCartButton(
              product: product,
              selectedVariant: _selectedVariant,
              productImageKey: _imageKey,
              cartIconKey: _cartIconKey,
              fullWidth: true,
              compact: false,
              showQuantityStepperWhenInCart: true,
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildPerkCard(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.primaryOrange),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kNavy),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
