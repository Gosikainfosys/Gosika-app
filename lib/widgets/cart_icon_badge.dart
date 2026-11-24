import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/cart_provider.dart';

class CartIconBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final GlobalKey? iconKey;
  final Color iconColor;
  final double size;

  const CartIconBadge({
    super.key,
    this.onTap,
    this.iconKey,
    this.iconColor = AppColors.darkText,
    this.size = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: iconKey,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Consumer<CartProvider>(
        builder: (ctx, cart, _) => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: iconColor,
              size: size,
            ),
            if (cart.itemCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF97316),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '${cart.itemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
