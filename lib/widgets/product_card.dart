import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/product.dart';
import '../core/api_client.dart';
import 'wishlist_heart_button.dart';
import 'add_to_cart_button.dart';

class ProductCard extends ConsumerStatefulWidget {
  final Product product;
  final double? width;
  final GlobalKey? cartIconKey;

  const ProductCard({
    super.key,
    required this.product,
    this.width,
    this.cartIconKey,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  final GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final discount = (product.compareAtPrice != null && product.compareAtPrice! > product.price)
        ? (((product.compareAtPrice! - product.price) / product.compareAtPrice!) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
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
            // Image Section with Wishlist Heart Button
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: KeyedSubtree(
                    key: _imageKey,
                    child: CachedNetworkImage(
                      imageUrl: ApiClient.apiImage(product.image),
                      fit: BoxFit.cover,
                      httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
                      placeholder: (context, url) => Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Color(0xFFFF5722)),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 28),
                            const SizedBox(height: 2),
                            Text(
                              'No Image',
                              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Discount Badge (Top Left)
                if (discount > 0)
                  Positioned(
                    top: 8,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5722),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: const TextStyle(
                          color: Colors.white,
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
                    productId: product.id,
                    size: 18,
                  ),
                ),
              ],
            ),

            // Product Details Section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatNPR(product.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                      if (product.compareAtPrice != null && product.compareAtPrice! > product.price) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            formatNPR(product.compareAtPrice!),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Rating Row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                      const SizedBox(width: 2),
                      Text(
                        '${product.ratingAvg.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kInk),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '(${product.ratingCount})',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Full Width Add to Cart / Quantity Stepper Button
                  AddToCartButton(
                    product: product,
                    productImageKey: _imageKey,
                    cartIconKey: widget.cartIconKey,
                    fullWidth: true,
                    compact: true,
                    showQuantityStepperWhenInCart: true,
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
