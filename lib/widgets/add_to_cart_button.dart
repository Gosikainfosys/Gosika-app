import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import 'flying_cart_animation.dart';
import 'variant_selector_sheet.dart';

class AddToCartButton extends StatefulWidget {
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
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton> {
  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      key: _buttonKey,
      builder: (ctx, cart, _) {
        final inCart = cart.isInCart(widget.product.id);

        if (widget.iconOnly) {
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
            minimumSize: Size(widget.fullWidth ? double.infinity : 120, widget.compact ? 36 : 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          icon: Icon(
            inCart ? Icons.check : Icons.add_shopping_cart,
            color: Colors.white,
            size: widget.compact ? 16 : 20,
          ),
          label: Text(
            inCart ? 'Added to Cart' : 'Add to Cart',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: widget.compact ? 12 : 14,
            ),
          ),
          onPressed: () => _handleAddToCart(context),
        );
      },
    );
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    // Trigger Glowing Orange Flying Bubble Animation starting from clicked button
    FlyingCartAnimation.animate(
      context: context,
      startKey: _buttonKey,
      cartIconKey: widget.cartIconKey,
    );

    if (widget.product.variants.isNotEmpty && widget.selectedVariant == null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx2) => VariantSelectorSheet(
          product: widget.product,
          initialVariant: widget.selectedVariant,
          onConfirm: (selectedV, selectedQty) async {
            context.read<CartProvider>().addItem(
                  widget.product,
                  quantity: selectedQty,
                  variantId: selectedV?.id,
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
          widget.product,
          quantity: 1,
          variantId: widget.selectedVariant?.id,
          variantName: widget.selectedVariant?.name,
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
