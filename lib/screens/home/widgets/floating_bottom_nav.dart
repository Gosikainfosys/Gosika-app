import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/cart_icon_badge.dart';
import '../../../widgets/cart_bottom_sheet.dart';

class FloatingBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final GlobalKey? cartIconKey;

  const FloatingBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.cartIconKey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 85,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // White Floating Container Card
          Container(
            height: 64,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Item 0: Category
                _buildNavItem(
                  index: 0,
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Category',
                ),

                // Item 1: Message
                _buildNavItem(
                  index: 1,
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Message',
                ),

                // Space reserved for Central Floating Home Button
                const SizedBox(width: 52),

                // Item 3: Cart (with reactive badge and animation)
                _buildCartNavItem(context, index: 3, label: 'Cart'),

                // Item 4: Account
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Account',
                ),
              ],
            ),
          ),

          // Central Floating Home Button (Overlapping) -> Index 2 (Home)
          Positioned(
            top: 2,
            child: GestureDetector(
              onTap: () => onItemTapped(2),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryOrange,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.home_rounded,
                  color: AppColors.white,
                  size: selectedIndex == 2 ? 30 : 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartNavItem(BuildContext context, {required int index, required String label}) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CartIconBadge(
            iconKey: cartIconKey,
            iconColor: isSelected ? AppColors.primaryOrange : AppColors.secondaryText,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryOrange : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.primaryOrange : AppColors.secondaryText,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryOrange : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
