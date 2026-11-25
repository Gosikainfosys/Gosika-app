import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/cart_icon_badge.dart';
import '../../../widgets/cart_bottom_sheet.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String locationText;
  final String? userAvatarUrl;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onProfileTap;
  final GlobalKey? cartIconKey;
  final int notificationCount;

  const HomeHeader({
    super.key,
    this.userName = 'Guest',
    this.locationText = 'Kathmandu, Nepal',
    this.userAvatarUrl,
    this.onLocationTap,
    this.onNotificationTap,
    this.onCartTap,
    this.onProfileTap,
    this.cartIconKey,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // User Profile Avatar (Clean circle without blue tick)
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: userAvatarUrl != null && userAvatarUrl!.isNotEmpty
                  ? Image.network(
                      userAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackAvatar(),
                    )
                  : _buildFallbackAvatar(),
            ),
          ),
          const SizedBox(width: 10),

          // User Name & Location Dropdown (Clean without blue tick)
          Expanded(
            child: GestureDetector(
              onTap: onLocationTap ?? onProfileTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          locationText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.secondaryText,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons: Shopping Bag & Notification Bell (Circle buttons side-by-side)
          Row(
            children: [
              // Circular Shopping Bag / Cart button
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: CartIconBadge(
                    iconKey: cartIconKey,
                    onTap: onCartTap ?? () => CartBottomSheet.show(context),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Circular Notification Bell button with Badge count
              GestureDetector(
                onTap: onNotificationTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.darkText,
                        size: 20,
                      ),
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x30FF0000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$notificationCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    final nameParts = userName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'
        : (nameParts.isNotEmpty ? nameParts[0][0] : 'U');

    return Container(
      color: AppColors.primaryOrange.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primaryOrange,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}
