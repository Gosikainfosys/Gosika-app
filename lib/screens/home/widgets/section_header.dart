import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? iconEmoji;
  final String actionText;
  final VoidCallback? onSeeAllTap;
  final bool showOrangeBar;

  const SectionHeader({
    super.key,
    required this.title,
    this.iconEmoji,
    this.actionText = 'View All',
    this.onSeeAllTap,
    this.showOrangeBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showOrangeBar) ...[
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (iconEmoji != null && iconEmoji!.isNotEmpty) ...[
                Text(
                  iconEmoji!,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onSeeAllTap ?? () => context.push('/shop'),
            child: Row(
              children: [
                Text(
                  actionText,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primaryOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.primaryOrange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
