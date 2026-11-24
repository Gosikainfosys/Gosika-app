import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import 'variant_selector_sheet.dart';

class AddToCartButton extends StatelessWidget {
  final Product product;
  final ProductVariant? selectedVariant;
  final GlobalKey? productImageKey;
  final GlobalKey? cartIconKey;
  final bool fullWidth;
  final bool compact;
  final bool iconOnly;
  final bool showQuantityStepperWhenInCart;

  const AddToCartButton({
    super.key,
    required this.product,
    this.selectedVariant,
    this.productImageKey,
    this.cartIconKey,
    this.fullWidth = true,
    this.compact = false,
    this.iconOnly = false,
    this.showQuantityStepperWhenInCart = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (ctx, cart, _) {
        final inCart = cart.isInCart(product.id);

        if (iconOnly) {
          return SizedBox(
            width: 36,
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: inCart ? Colors.green : const Color(0xFFF97316),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () => _handleAddToCart(context),
              child: Icon(
                inCart ? Icons.check : Icons.add,
                color: Colors.white,
                size: 18,
              ),
            ),
          );
        }

        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: inCart ? Colors.green : const Color(0xFFF97316),
            minimumSize: Size(fullWidth ? double.infinity : 120, compact ? 36 : 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          icon: Icon(
            inCart ? Icons.check : Icons.add_shopping_cart,
            color: Colors.white,
            size: compact ? 16 : 20,
          ),
          label: Text(
            inCart ? 'Added to Cart' : 'Add to Cart',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 12 : 14,
            ),
          ),
          onPressed: () => _handleAddToCart(context),
        );
      },
    );
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    if (product.variants.isNotEmpty && selectedVariant == null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx2) => VariantSelectorSheet(
          product: product,
          initialVariant: selectedVariant,
          onConfirm: (selectedV, selectedQty) async {
            context.read<CartProvider>().addItem(
                  product,
                  quantity: selectedQty,
                  variantName: selectedV?.name,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Added to cart ✓'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        ),
      );
      return;
    }

    context.read<CartProvider>().addItem(
          product,
          quantity: 1,
          variantName: selectedVariant?.name,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart ✓'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
