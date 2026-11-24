import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../services/wishlist_service.dart';

final wishlistServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WishlistService(apiClient);
});

final wishlistProvider = StateNotifierProvider<WishlistNotifier, AsyncValue<List<WishlistItem>>>((ref) {
  final service = ref.watch(wishlistServiceProvider);
  return WishlistNotifier(service, ref);
});

class WishlistNotifier extends StateNotifier<AsyncValue<List<WishlistItem>>> {
  final WishlistService _service;
  final Ref _ref;

  WishlistNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    fetchWishlist();

    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated && next.isAuthenticated) {
        fetchWishlist();
      }
    });
  }

  Future<void> fetchWishlist() async {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final items = await _service.getWishlist();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleWishlist(String productId) async {
    final currentItems = state.value ?? [];
    final isExist = currentItems.any((item) => item.productId == productId || item.product.id == productId);

    try {
      if (isExist) {
        await _service.removeFromWishlist(productId);
      } else {
        await _service.addToWishlist(productId);
      }
      await fetchWishlist();
    } catch (e) {
      rethrow;
    }
  }

  bool isWishlisted(String productId) {
    return state.value?.any((item) => item.productId == productId || item.product.id == productId) ?? false;
  }
}
