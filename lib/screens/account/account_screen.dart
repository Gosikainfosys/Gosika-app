import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../message/message_screen.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _bannerDismissed = false;
  bool _isResendingVerification = false;
  bool _isConnectingSupport = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuth();
      ref.read(notificationListProvider.notifier).loadNotifications();
    });
  }

  Future<void> _handleResendVerification(String email) async {
    setState(() => _isResendingVerification = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.resendEmailVerification(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent to your email!')),
        );
        context.push('/verify-email', extra: email);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resend error: $e')),
        );
        context.push('/verify-email', extra: email);
      }
    } finally {
      if (mounted) setState(() => _isResendingVerification = false);
    }
  }

  Future<void> _handleContactSupport() async {
    setState(() => _isConnectingSupport = true);
    try {
      final supportConv = await ref.read(conversationsListProvider.notifier).getOrCreateSupport();
      if (mounted) {
        // Open support chat sheet or detail
        _openSupportChat(context, supportConv.id, supportConv.title);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open support chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnectingSupport = false);
    }
  }

  void _openSupportChat(BuildContext context, String conversationId, String title) {
    showChatDetailSheet(context, conversationId, title);
  }

  void _showHelpCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center', style: TextStyle(color: kNavy, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to GOSIKA Support!', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• For order queries, check My Orders section.'),
            Text('• For delivery updates, track via Order Details.'),
            Text('• For refunds/returns, request a return on eligible items.'),
            SizedBox(height: 12),
            Text('Email: support@gosika.info.np', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutGosika(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About GOSIKA', style: TextStyle(color: kNavy, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GOSIKA E-Commerce Platform', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 4),
            Text('Nepal\'s multi-vendor marketplace connecting top sellers directly with customers.'),
            SizedBox(height: 12),
            Text('© 2026 GOSIKA. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final notifState = ref.watch(notificationListProvider);
    final unreadNotifCount = notifState.value?.unreadCount ?? 0;

    final userName = user != null ? user.fullName : 'Guest User';
    final userEmail = user?.email ?? 'Please log in to manage your profile';
    final avatarUrl = user?.avatarUrl;

    final bool showUnverifiedBanner =
        authState.isAuthenticated && user != null && user.emailVerifiedAt == null && !_bannerDismissed;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Account', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 18)),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: kNavy),
                if (unreadNotifCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$unreadNotifCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.push('/'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).checkAuth();
          await ref.read(notificationListProvider.notifier).loadNotifications();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Unverified Email Banner
              if (showUnverifiedBanner)
                Container(
                  color: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_unread_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your email is not verified.',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      InkWell(
                        onTap: _isResendingVerification ? null : () => _handleResendVerification(user.email),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _isResendingVerification
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange),
                                )
                              : const Text(
                                  'Tap to verify →',
                                  style: TextStyle(
                                    color: AppColors.primaryOrange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
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

              const SizedBox(height: 12),

              // Profile Card Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () {
                    if (user != null) {
                      context.push('/account/profile');
                    } else {
                      context.push('/login');
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.paleOrange,
                          child: avatarUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => Text(
                                      user?.initials ?? 'G',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                                    ),
                                  ),
                                )
                              : Text(
                                  user?.initials ?? 'G',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kNavy),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // My Account Section
              _buildSectionHeader('MY ACCOUNT'),
              _buildMenuCard([
                _buildMenuItem(Icons.assignment_outlined, 'My Orders', () => context.push('/orders')),
                _buildDivider(),
                _buildMenuItem(Icons.favorite_border_rounded, 'Wishlist', () => context.push('/wishlist')),
                _buildDivider(),
                _buildMenuItem(Icons.location_on_outlined, 'Address Book', () => context.push('/account/addresses')),
                _buildDivider(),
                _buildMenuItem(Icons.rate_review_outlined, 'My Reviews', () => context.push('/account/reviews')),
              ]),

              const SizedBox(height: 20),

              // Support Section
              _buildSectionHeader('SUPPORT & INFO'),
              _buildMenuCard([
                _buildMenuItem(Icons.help_outline_rounded, 'Help Center', () => _showHelpCenter(context)),
                _buildDivider(),
                _buildMenuItem(
                  Icons.support_agent_rounded,
                  'Contact Us',
                  _isConnectingSupport ? () {} : _handleContactSupport,
                  trailing: _isConnectingSupport
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange),
                        )
                      : null,
                ),
                _buildDivider(),
                _buildMenuItem(Icons.info_outline_rounded, 'About GOSIKA', () => _showAboutGosika(context)),
              ]),

              const SizedBox(height: 24),

              // Log Out / Log In Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () async {
                    if (user != null) {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    } else {
                      context.push('/login');
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: user != null ? const Color(0xFFFFEBEE) : AppColors.paleOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          user != null ? Icons.logout_rounded : Icons.login_rounded,
                          color: user != null ? Colors.red : AppColors.primaryOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user != null ? 'Log Out' : 'Log In',
                          style: TextStyle(
                            color: user != null ? Colors.red : AppColors.primaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Text(
        title,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Widget? trailing}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: kNavy, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kNavy),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey[100]);
  }
}
