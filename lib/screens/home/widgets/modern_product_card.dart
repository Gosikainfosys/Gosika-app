import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/product.dart';
import '../../../widgets/wishlist_heart_button.dart';
import '../../../widgets/add_to_cart_button.dart';

class ModernProductData {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String currentPrice;
  final String? oldPrice;
  final String discountBadge;
  final double rating;
  final int reviewsCount;
  final Product? originalProduct;

  const ModernProductData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.currentPrice,
    this.oldPrice,
    required this.discountBadge,
    this.rating = 4.5,
    this.reviewsCount = 120,
    this.originalProduct,
  });

  Product toProduct() {
    if (originalProduct != null) return originalProduct!;

    double parsePrice(String text) {
      final cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }

    return Product(
      id: id,
      name: title,
      slug: id,
      shortDescription: subtitle,
      price: parsePrice(currentPrice),
      compareAtPrice: oldPrice != null ? parsePrice(oldPrice!) : null,
      image: imageUrl,
      images: [imageUrl],
      variants: [],
      ratingAvg: rating,
      ratingCount: reviewsCount,
      isFeatured: false,
      status: 'active',
      stockStatus: 'in_stock',
    );
  }
}

class ModernProductCard extends ConsumerStatefulWidget {
  final ModernProductData product;
  final GlobalKey? cartIconKey;

  const ModernProductCard({
    super.key,
    required this.product,
    this.cartIconKey,
  });

  @override
  ConsumerState<ModernProductCard> createState() => _ModernProductCardState();
}

class _ModernProductCardState extends ConsumerState<ModernProductCard> {
  final GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final productModel = p.toProduct();

    return GestureDetector(
      onTap: () => context.push('/products/${p.id}', extra: productModel),
      child: Container(
        width: 175,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Image Region with Discount Badge & Wishlist Heart Button
            Stack(
              children: [
                KeyedSubtree(
                  key: _imageKey,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: AppColors.inputBackground,
                    child: CachedNetworkImage(
                      imageUrl: p.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[100]),
                      errorWidget: (context, error, stackTrace) => const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.secondaryText,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),

                // Discount Badge (Top Left)
                if (p.discountBadge.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        p.discountBadge,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Wishlist Heart Button (Top Right)
                Positioned(
                  top: 6,
                  right: 6,
                  child: WishlistHeartButton(
                    productId: p.id,
                    size: 18,
                  ),
                ),
              ],
            ),

            // Bottom Product Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Subtitle / Short Category
                  Text(
                    p.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Rating Row
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB800),
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${p.rating}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '(${p.reviewsCount})',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price Row with Inline Compact Add-to-Cart Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.currentPrice,
                            style: AppTextStyles.button.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          if (p.oldPrice != null)
                            Text(
                              p.oldPrice!,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 9,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.secondaryText,
                              ),
                            ),
                        ],
                      ),
                      AddToCartButton(
                        product: productModel,
                        productImageKey: _imageKey,
                        cartIconKey: widget.cartIconKey,
                        iconOnly: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
