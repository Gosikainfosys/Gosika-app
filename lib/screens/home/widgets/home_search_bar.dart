import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeSearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onTap;
  final String hintText;

  const HomeSearchBar({
    super.key,
    this.onChanged,
    this.onFilterTap,
    this.onTap,
    this.hintText = 'Would you like to buy something?',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 16, right: 6),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.secondaryText,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onTap: onTap,
              onChanged: onChanged,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.darkText,
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.inputHint.copyWith(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),

          // Green/Orange Styled Filter Sliders Button
          GestureDetector(
            onTap: onFilterTap ?? onTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
