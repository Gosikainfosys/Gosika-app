import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';
import '../../widgets/wishlist_heart_button.dart';
import '../../widgets/flying_cart_animation.dart';
import '../../widgets/cart_icon_badge.dart';
import '../../widgets/cart_bottom_sheet.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final Product? initialProduct;
  const ProductDetailScreen({super.key, required this.productId, this.initialProduct});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  String _selectedColor = 'Blue';
  final PageController _pageController = PageController();
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _cartIconKey = GlobalKey();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final product = productAsync.valueOrNull ?? widget.initialProduct;
    final isLoading = productAsync.isLoading && product == null;
    final hasError = productAsync.hasError && product == null;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9FAFB),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kNavy, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange)),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9FAFB),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kNavy, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load product details:\n${productAsync.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kNavy, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => ref.invalidate(productDetailProvider(widget.productId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9FAFB),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kNavy, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('Product not found', style: TextStyle(color: kNavy, fontSize: 16)),
        ),
      );
    }

    if (_selectedVariant == null && product.variants.isNotEmpty) {
      _selectedVariant = product.variants.first;
    }

    final imageList = product.images.isNotEmpty ? product.images : [product.image ?? 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80'];
    final double currentPrice = _selectedVariant?.price ?? product.price;
    final double comparePrice = product.compareAtPrice ?? (currentPrice * 1.25);
    final discount = comparePrice > currentPrice
        ? (((comparePrice - currentPrice) / comparePrice) * 100).round()
        : 20;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kNavy, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: kNavy, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product link copied to clipboard!')),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
              ],
            ),
            child: WishlistHeartButton(
              productId: widget.productId,
              showBackground: false,
              size: 20,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                ],
              ),
              child: CartIconBadge(
                iconKey: _cartIconKey,
                onTap: () => CartBottomSheet.show(context),
                iconColor: kNavy,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Product Image View with Discount Badge & Page Indicator
            Container(
              height: 280,
              width: double.infinity,
              color: const Color(0xFFF9FAFB),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageController,
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
                            child: Icon(Icons.laptop_mac_rounded, size: 80, color: Colors.grey),
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

                  // -20% Discount Badge (Top Left)
                  if (discount > 0)
                    Positioned(
                      top: 16,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Text(
                          '-$discount%',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  // Image Index Indicator Pill (Bottom Right)
                  Positioned(
                    bottom: 12,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${imageList.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Thumbnail Selector Strip
            if (imageList.length > 1)
              Container(
                height: 60,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: imageList.length,
                  itemBuilder: (context, index) {
                    final isSelected = _currentImageIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentImageIndex = index);
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryOrange : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.2), blurRadius: 6),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: CachedNetworkImage(
                            imageUrl: imageList[index],
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(Icons.image, size: 20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // 3. White Details Sheet Container with Curved Top Corners
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, -4)),
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

                  // Product Title
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kNavy, height: 1.25),
                  ),
                  const SizedBox(height: 10),

                  // Ratings & Sold Count Row
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
                        product.ratingAvg > 0 ? product.ratingAvg.toStringAsFixed(1) : '4.6',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.ratingCount > 0 ? product.ratingCount : 856} reviews)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      Container(height: 14, width: 1, color: Colors.grey.shade300),
                      const SizedBox(width: 10),
                      const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.primaryOrange),
                      const SizedBox(width: 2),
                      const Text(
                        '2.5k+ sold',
                        style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'NPR ${NumberFormat('#,###').format(currentPrice)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      if (comparePrice > currentPrice) ...[
                        const SizedBox(width: 12),
                        Text(
                          'NPR ${NumberFormat('#,###').format(comparePrice)}',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Save Discount Banner Pill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5500).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF5500).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_rounded, size: 18, color: AppColors.primaryOrange),
                        const SizedBox(width: 8),
                        Text(
                          'Save NPR ${NumberFormat('#,###').format(comparePrice - currentPrice)} ($discount%)',
                          style: const TextStyle(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Key Features Section
                  Row(
                    children: [
                      Container(width: 4, height: 16, color: AppColors.primaryOrange),
                      const SizedBox(width: 8),
                      const Text(
                        'Key Features',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildFeatureCard(Icons.memory_rounded, 'Intel Core', 'i5 13th Gen'),
                      const SizedBox(width: 8),
                      _buildFeatureCard(Icons.desktop_windows_rounded, '15.6” FHD', 'Display'),
                      const SizedBox(width: 8),
                      _buildFeatureCard(Icons.storage_rounded, '8GB RAM', '512GB SSD'),
                      const SizedBox(width: 8),
                      _buildFeatureCard(Icons.window_rounded, 'Windows', '11 Pro'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Offers & Discounts Section
                  Row(
                    children: [
                      Container(width: 4, height: 16, color: AppColors.primaryOrange),
                      const SizedBox(width: 8),
                      const Text(
                        'Offers & Discounts',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Flat 10% OFF',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Use code: GOSIKA10',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primaryOrange),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryOrange,
                            elevation: 0,
                            side: const BorderSide(color: AppColors.primaryOrange),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: 'GOSIKA10'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Promo code GOSIKA10 copied to clipboard! ✓'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Copy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Available Options (Color & Quantity)
                  Row(
                    children: [
                      Container(width: 4, height: 16, color: AppColors.primaryOrange),
                      const SizedBox(width: 8),
                      const Text(
                        'Available Options',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Color Options Row
                  Row(
                    children: [
                      const Text('Color:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kNavy)),
                      const SizedBox(width: 16),
                      _buildColorOption('Blue', const Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      _buildColorOption('Grey', const Color(0xFF4B5563)),
                      const SizedBox(width: 12),
                      _buildColorOption('Silver', const Color(0xFFE5E7EB)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quantity Row
                  Row(
                    children: [
                      const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kNavy)),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () {
                                if (_quantity > 1) setState(() => _quantity--);
                              },
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 32),
                              alignment: Alignment.center,
                              child: Text(
                                _quantity.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Product Details / Description
                  const Text('Product Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kNavy)),
                  const SizedBox(height: 8),
                  Text(
                    product.description ?? product.shortDescription ?? 'High-performance authentic device crafted with premium components for superior multitasking, stunning visuals, and ultimate reliability.',
                    style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Trust Badges
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TrustBadge(icon: Icons.verified_rounded, title: '100% Authentic'),
                        _TrustBadge(icon: Icons.local_shipping_rounded, title: 'Fast Delivery'),
                        _TrustBadge(icon: Icons.replay_rounded, title: 'Easy Returns'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120), // Bottom padding for floating bar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Store Button
              InkWell(
                onTap: () => context.go('/'),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_outlined, color: kNavy, size: 22),
                    SizedBox(height: 2),
                    Text('Store', style: TextStyle(fontSize: 10, color: kNavy, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Chat Button
              InkWell(
                onTap: () => context.push('/message'),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.headset_mic_outlined, color: kNavy, size: 22),
                    SizedBox(height: 2),
                    Text('Chat', style: TextStyle(fontSize: 10, color: kNavy, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Add to Cart Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primaryOrange, size: 18),
                    label: const Text(
                      'Add to Cart',
                      style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      FlyingCartAnimation.animate(
                        context: context,
                        startKey: _imageKey,
                        cartIconKey: _cartIconKey,
                      );
                      context.read<CartProvider>().addItem(
                            product,
                            quantity: _quantity,
                            variantId: _selectedVariant?.id,
                            variantName: '${_selectedVariant?.name ?? ''} (Color: $_selectedColor)',
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to cart successfully! ✓'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Buy Now Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'Buy Now',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      context.read<CartProvider>().addItem(
                            product,
                            quantity: _quantity,
                            variantId: _selectedVariant?.id,
                            variantName: '${_selectedVariant?.name ?? ''} (Color: $_selectedColor)',
                          );
                      context.push('/checkout');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryOrange),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kNavy),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(String colorName, Color colorValue) {
    final isSelected = _selectedColor == colorName;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = colorName),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : Colors.transparent,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 14,
          backgroundColor: colorValue,
          child: isSelected
              ? Icon(Icons.check, size: 14, color: colorValue == Colors.white ? Colors.black : Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String title;

  const _TrustBadge({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryOrange),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kNavy),
        ),
      ],
    );
  }
}
