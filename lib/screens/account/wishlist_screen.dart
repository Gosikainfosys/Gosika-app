import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Wishlist', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 18)),
      ),
      body: wishlistState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : wishlistState.error != null && wishlistState.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading wishlist: ${wishlistState.error}', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(wishlistProvider.notifier).fetchWishlist(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : wishlistState.items.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () => ref.read(wishlistProvider.notifier).fetchWishlist(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.favorite_border_rounded, size: 70, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                const Text(
                                  'Your wishlist is empty',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy),
                                ),
                                const SizedBox(height: 6),
                                const Text('Save items you love for later.', style: TextStyle(color: kMuted, fontSize: 13)),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => context.go('/'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: const Text('Explore Products', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(wishlistProvider.notifier).fetchWishlist(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.60,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: wishlistState.items.length,
                        itemBuilder: (context, index) {
                          final item = wishlistState.items[index];
                          return ProductCard(product: item.product);
                        },
                      ),
                    ),
    );
  }
}
