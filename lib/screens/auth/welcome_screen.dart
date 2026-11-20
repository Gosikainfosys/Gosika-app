import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/decorative_background.dart';
import '../../shared/widgets/gosika_logo.dart';
import '../../shared/widgets/primary_auth_button.dart';
import '../../shared/widgets/social_login_button.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In successful! Welcome to GOSIKA.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: DecorativeBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Logo at top (Prominent size 72)
                      const GosikaLogo(
                        logoSize: 72,
                        showTagline: true,
                      ),
                      const SizedBox(height: 20),

                      // Standalone Hero Shopping Bag Illustration (No white card)
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Image.asset(
                          AppAssets.welcomeShoppingBag,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.shopping_bag,
                              size: 80,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Main Title & Tagline
                      Text(
                        'Welcome to GOSIKA',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shop smarter, live better. Everything you love, just a tap away.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),

                      // Primary Orange Action: Create Account
                      PrimaryAuthButton(
                        text: 'Create Account',
                        onPressed: () => context.push('/register'),
                      ),
                      const SizedBox(height: 12),

                      // Secondary Outlined Action: Log In
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => context.push('/login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryOrange,
                            side: const BorderSide(
                              color: AppColors.primaryOrange,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Log In',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Social Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Or continue with',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Social Buttons (Google & Facebook)
                      Row(
                        children: [
                          Expanded(
                            child: SocialLoginButton(
                              provider: SocialProvider.google,
                              text: 'Continue with Google',
                              onTap: () => _handleGoogleSignIn(context, ref),
                              isLoading: authState.isLoading,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: SocialLoginButton(
                              provider: SocialProvider.facebook,
                              text: 'Facebook',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Continue as Guest Option
                      TextButton(
                        onPressed: () => context.go('/'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondaryText,
                        ),
                        child: Text(
                          'Continue as Guest',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Legal Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Terms of Service', style: AppTextStyles.bodySmall),
                          Text('   |   ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.border)),
                          Text('Privacy Policy', style: AppTextStyles.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
