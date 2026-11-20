import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TrustBanner extends StatelessWidget {
  const TrustBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTrustItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'Free Delivery',
                  subtitle: 'On all orders',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrustItem(
                  icon: Icons.shield_outlined,
                  title: 'Secure Payment',
                  subtitle: '100% Safe',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTrustItem(
                  icon: Icons.headset_mic_outlined,
                  title: '24/7 Support',
                  subtitle: 'Always Here',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrustItem(
                  icon: Icons.autorenew_rounded,
                  title: 'Easy Returns',
                  subtitle: 'Hassle Free',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.paleOrange,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primaryOrange,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
