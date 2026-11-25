import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final VoidCallback? onTap;
  final VoidCallback? onMicTap;
  final String hintText;
  final double height;
  final EdgeInsetsGeometry? margin;

  const HomeSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.onTap,
    this.onMicTap,
    this.hintText = 'Would you like to buy something?',
    this.height = 44,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 14, right: 4),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.secondaryText,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.darkText,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.inputHint.copyWith(
                  fontSize: 12.5,
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
          if (controller != null && controller!.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller!.clear();
                if (onChanged != null) onChanged!('');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.cancel_rounded, color: Colors.grey, size: 18),
              ),
            ),
          GestureDetector(
            onTap: onMicTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.mic_rounded, color: AppColors.secondaryText, size: 19),
            ),
          ),
          const SizedBox(width: 2),

          // Orange Styled Filter Sliders Button
          GestureDetector(
            onTap: onFilterTap ?? onTap,
            child: Container(
              width: height - 8,
              height: height - 8,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular((height - 8) / 2),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.primaryOrange,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
