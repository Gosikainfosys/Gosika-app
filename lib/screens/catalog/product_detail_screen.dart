import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: kNavy),
            onPressed: () {},
          ),
          WishlistHeartButton(
            productId: widget.productId,
            showBackground: false,
            size: 22,
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CartIconBadge(
              iconKey: _cartIconKey,
              onTap: () => CartBottomSheet.show(context),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Gallery
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.1,
                      child: PageView.builder(
                        itemCount: imageList.length,
                        onPageChanged: (index) => setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          final imgWidget = CachedNetworkImage(
                            imageUrl: imageList[index],
                            fit: BoxFit.cover,
                            httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
                            placeholder: (context, url) => Container(color: Colors.grey[100]),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[100],
                              child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
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
                    ),
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${imageList.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stock warning badges if low_stock or out_of_stock
                      if (product.stockStatus == 'low_stock')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Low Stock',
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),

                      if (product.stockStatus == 'out_of_stock')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Out of Stock',
                            style: TextStyle(color: Colors.red.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),

                      // Discount Badge
                      if (discount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$discount% OFF',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),

                      // Title
                      Text(
                        product.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kNavy, height: 1.25),
                      ),
                      const SizedBox(height: 8),

                      // Rating & Verified
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < product.ratingAvg.floor() ? Icons.star : Icons.star_border,
                              size: 16,
                              color: Colors.amber[700],
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            '(${product.ratingCount} reviews)',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, size: 12, color: Colors.blue),
                                SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formatNPR(_selectedVariant?.price ?? product.price),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                          ),
                          if (product.compareAtPrice != null) ...[
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

                      // Perks Section
                      Row(
                        children: [
                          _buildPerkCard(Icons.local_shipping_outlined, 'Free Shipping', 'On orders above रु1,000'),
                          const SizedBox(width: 8),
                          _buildPerkCard(Icons.payments_outlined, 'Cash on Delivery', 'Available'),
                          const SizedBox(width: 8),
                          _buildPerkCard(Icons.published_with_changes, '7 Days Return', 'Easy return policy'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Variants
                      if (product.variants.isNotEmpty) ...[
                        const Text('Select Variant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: product.variants.map((v) {
                            final isSelected = _selectedVariant?.id == v.id;
                            return ChoiceChip(
                              label: Text(v.name ?? 'Default'),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedVariant = v);
                              },
                              selectedColor: const Color(0xFFFF5722),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Description
                      const Text('Product Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        product.description ?? product.shortDescription ?? 'Handcrafted product made with standard quality materials.',
                        style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 13),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF5722)))),
        error: (err, stack) => Center(child: Text('Error loading product: $err')),
      ),
      bottomSheet: productAsync.maybeWhen(
        data: (product) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFF5722), size: 20),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kNavy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 8, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
