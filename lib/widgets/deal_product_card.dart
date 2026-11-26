import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/deal_product.dart';
import '../models/product.dart';
import '../core/api_client.dart';
import 'wishlist_heart_button.dart';
import 'add_to_cart_button.dart';

class DealProductCard extends ConsumerStatefulWidget {
  final DealProduct product;
  final double? width;
  final GlobalKey? cartIconKey;

  const DealProductCard({
    super.key,
    required this.product,
    this.width,
    this.cartIconKey,
  });

  @override
  ConsumerState<DealProductCard> createState() => _DealProductCardState();
}

class _DealProductCardState extends ConsumerState<DealProductCard> {
  final GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final deal = widget.product;
    final discount = deal.discountPercentage;

    // Convert DealProduct to Product model so AddToCartButton works seamlessly
    final productModel = Product(
      id: deal.id,
      name: deal.name,
      slug: deal.id,
      price: deal.price,
      compareAtPrice: deal.compareAtPrice,
      image: deal.imageUrl,
      images: deal.imageUrl != null ? [deal.imageUrl!] : [],
      variants: [],
      ratingAvg: deal.ratingAvg,
      ratingCount: deal.ratingCount,
      isFeatured: false,
      status: 'active',
      stockStatus: deal.stockStatus,
    );

    return GestureDetector(
      onTap: () => context.push('/products/${deal.id}', extra: productModel),
      child: Container(
        width: widget.width ?? 175,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with badges and wishlist button
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.25,
                  child: KeyedSubtree(
                    key: _imageKey,
                    child: CachedNetworkImage(
                      imageUrl: ApiClient.apiImage(deal.imageUrl),
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
                // Discount badge
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
                // Wishlist button
                Positioned(
                  top: 6,
                  right: 6,
                  child: WishlistHeartButton(
                    productId: deal.id,
                    size: 18,
                  ),
                ),
              ],
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Rating Row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                      const SizedBox(width: 2),
                      Text(
                        '${deal.ratingAvg.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kInk),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '(${deal.ratingCount})',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatNPR(deal.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                      if (deal.compareAtPrice != null && deal.compareAtPrice! > deal.price) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            formatNPR(deal.compareAtPrice!),
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
                  const SizedBox(height: 8),

                  AddToCartButton(
                    product: productModel,
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
