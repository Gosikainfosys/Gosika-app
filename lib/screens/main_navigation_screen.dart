import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'account/account_screen.dart';
import 'cart/cart_screen.dart';
import 'catalog/category_screen.dart';
import 'home/home_screen.dart';
import 'home/widgets/floating_bottom_nav.dart';
import 'message/message_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 2; // Default to Home (Center Floating Button)
  bool _bannerDismissed = false;
  bool _isSendingOtp = false;

  final List<Widget> _screens = const [
    CategoryScreen(), // Index 0: Category
    MessageScreen(),  // Index 1: Message
    HomeScreen(),     // Index 2: Home
    CartScreen(),     // Index 3: Cart
    AccountScreen(),  // Index 4: Account
  ];

  void _onItemTapped(int index) {
    final requiresAuth = [1, 4].contains(index); // Message, Account
    final isAuthenticated = ref.read(authProvider).isAuthenticated;

    if (requiresAuth && !isAuthenticated) {
      context.push('/login');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _handleBannerVerify(String email) async {
    setState(() => _isSendingOtp = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.resendEmailVerification(email);
    } catch (_) {
      // Non-blocking, continue to OTP screen
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
        context.push('/verify-email', extra: email);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Show banner after login if email is unverified (emailVerifiedAt == null)
    final bool showUnverifiedBanner =
        authState.isAuthenticated && user != null && user.emailVerifiedAt == null && !_bannerDismissed;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: showUnverifiedBanner,
        child: Stack(
          children: [
            // Active Screen
            IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),

            // Non-blocking Unverified Email Banner
            if (showUnverifiedBanner)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 4,
                  color: AppColors.primaryOrange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_unread_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Your email is unverified',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _isSendingOtp ? null : () => _handleBannerVerify(user.email),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: _isSendingOtp
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryOrange,
                                    ),
                                  )
                                : const Text(
                                    'Verify →',
                                    style: TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _bannerDismissed = true),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Floating Bottom Navigation Bar Overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: FloatingBottomNav(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
