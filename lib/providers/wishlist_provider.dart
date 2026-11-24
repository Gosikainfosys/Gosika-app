import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import 'auth_provider.dart';
import '../services/wishlist_service.dart';

class WishlistState {
  final Set<String> wishlistedProductIds;
  final List<WishlistItem> items;
  final bool isLoading;
  final String? error;

  const WishlistState({
    this.wishlistedProductIds = const {},
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  WishlistState copyWith({
    Set<String>? wishlistedProductIds,
    List<WishlistItem>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return WishlistState(
      wishlistedProductIds: wishlistedProductIds ?? this.wishlistedProductIds,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool isWishlisted(String productId) => wishlistedProductIds.contains(productId);
}

final wishlistServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WishlistService(apiClient);
});

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  final service = ref.watch(wishlistServiceProvider);
  return WishlistNotifier(service, ref);
});

class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistService _service;
  final Ref _ref;

  WishlistNotifier(this._service, this._ref) : super(const WishlistState(isLoading: false)) {
    fetchWishlist();

    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) {
        if (next.isAuthenticated) {
          fetchWishlist();
        } else {
          state = const WishlistState();
        }
      }
    });
  }

  bool isWishlisted(String productId) {
    return state.isWishlisted(productId);
  }

  Future<void> fetchWishlist() async {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      state = const WishlistState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _service.getWishlist();
      final ids = items.map((e) => e.productId).toSet();
      state = WishlistState(
        items: items,
        wishlistedProductIds: ids,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Toggles wishlist status. If guest, shows login bottom sheet.
  /// Returns true if toggled successfully, false if blocked (e.g. guest).
  Future<bool> toggleWishlist(BuildContext context, String productId) async {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      _showLoginPromptBottomSheet(context);
      return false;
    }

    final currentlyWishlisted = isWishlisted(productId);
    final previousIds = Set<String>.from(state.wishlistedProductIds);
    final newIds = Set<String>.from(previousIds);

    // Optimistic local update
    if (currentlyWishlisted) {
      newIds.remove(productId);
    } else {
      newIds.add(productId);
    }
    state = state.copyWith(wishlistedProductIds: newIds);

    try {
      if (currentlyWishlisted) {
        await _service.removeFromWishlist(productId);
      } else {
        await _service.addToWishlist(productId);
      }
      // Refresh items list in background
      fetchWishlist();
      return true;
    } catch (e) {
      // Revert local state on error
      state = state.copyWith(wishlistedProductIds: previousIds);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  void _showLoginPromptBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.primaryOrange,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Save to Wishlist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF161D2B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to save items to your wishlist and access them from any device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign In / Register',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
