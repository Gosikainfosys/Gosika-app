import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../models/cart.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final Set<String> _selectedItemIds = {};
  bool _isInitialized = false;

  void _syncSelection(Cart cart) {
    if (!_isInitialized && cart.items.isNotEmpty) {
      _selectedItemIds.addAll(cart.items.map((e) => e.id));
      _isInitialized = true;
    } else {
      // Remove any IDs that no longer exist in cart
      final currentIds = cart.items.map((e) => e.id).toSet();
      _selectedItemIds.retainAll(currentIds);
    }
  }

  void _toggleSelectAll(Cart cart) {
    setState(() {
      if (_selectedItemIds.length == cart.items.length) {
        _selectedItemIds.clear();
      } else {
        _selectedItemIds.clear();
        _selectedItemIds.addAll(cart.items.map((e) => e.id));
      }
    });
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedItemIds.isEmpty) return;
    final idsToDelete = List<String>.from(_selectedItemIds);
    for (final id in idsToDelete) {
      await ref.read(cartProvider.notifier).removeItem(id);
    }
    setState(() {
      _selectedItemIds.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected items removed from cart'),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
    }
  }

  double _calculateSelectedSubtotal(Cart cart) {
    double total = 0.0;
    for (final item in cart.items) {
      if (_selectedItemIds.contains(item.id)) {
        total += item.lineTotal > 0 ? item.lineTotal : (item.unitPrice * item.quantity);
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Cart', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kNavy),
            tooltip: 'Delete Selected',
            onPressed: _selectedItemIds.isEmpty ? null : _deleteSelected,
          ),
        ],
      ),
      body: cartState.when(
        data: (cart) {
          if (cart.items.isEmpty) {
            return _buildEmptyState(context);
          }
          _syncSelection(cart);
          final allSelected = cart.items.isNotEmpty && _selectedItemIds.length == cart.items.length;
          final selectedSubtotal = _calculateSelectedSubtotal(cart);

          return Column(
            children: [
              // Top Selection Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.grey[50],
                child: Row(
                  children: [
                    Checkbox(
                      value: allSelected,
                      activeColor: AppColors.primaryOrange,
                      onChanged: (val) => _toggleSelectAll(cart),
                    ),
                    Text(
                      'Select All (${cart.items.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy),
                    ),
                    const Spacer(),
                    if (_selectedItemIds.isNotEmpty)
                      TextButton.icon(
                        onPressed: _deleteSelected,
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Cart Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final isSelected = _selectedItemIds.contains(item.id);
                    return _CartItemTile(
                      item: item,
                      isSelected: isSelected,
                      onToggle: () => _toggleItemSelection(item.id),
                    );
                  },
                ),
              ),

              // Bottom Selection & Checkout Bar
              _buildBottomBar(context, cart, selectedSubtotal, allSelected),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF5722))),
        ),
        error: (err, stack) => Center(child: Text('Error loading cart: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
          const SizedBox(height: 8),
          const Text('Discover amazing deals and products today!', style: TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Start Shopping', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Cart cart, double selectedSubtotal, bool allSelected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Checkbox(
              value: allSelected,
              activeColor: AppColors.primaryOrange,
              onChanged: (val) => _toggleSelectAll(cart),
            ),
            const Text('All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Total: ', style: TextStyle(fontSize: 12, color: kMuted)),
                    Text(
                      formatNPR(selectedSubtotal),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                    ),
                  ],
                ),
                Text(
                  '${_selectedItemIds.length} items selected',
                  style: const TextStyle(fontSize: 11, color: kMuted),
                ),
              ],
            ),
            const SizedBox(width: 14),
            ElevatedButton(
              onPressed: _selectedItemIds.isEmpty
                  ? null
                  : () {
                      context.push('/checkout', extra: {
                        'selectedItemIds': _selectedItemIds.toList(),
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                'Checkout (${_selectedItemIds.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  final bool isSelected;
  final VoidCallback onToggle;

  const _CartItemTile({
    required this.item,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryOrange.withValues(alpha: 0.5) : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox for selection
          Checkbox(
            value: isSelected,
            activeColor: AppColors.primaryOrange,
            onChanged: (val) => onToggle(),
          ),

          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 70,
              height: 70,
              child: item.image != null && item.image!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.image!,
                      fit: BoxFit.cover,
                      httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
                      placeholder: (context, url) => Container(color: Colors.grey[100]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
                      ),
                    )
                  : Container(color: Colors.grey[100], child: const Icon(Icons.image_outlined, color: kMuted)),
            ),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kNavy),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatNPR(item.unitPrice),
                  style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),

                // Quantity Stepper & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuantityStepper(
                      quantity: item.quantity,
                      onChanged: (val) {
                        if (val < 1) {
                          ref.read(cartProvider.notifier).removeItem(item.id);
                        } else {
                          ref.read(cartProvider.notifier).updateQuantity(item.id, val);
                        }
                      },
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            ref.read(wishlistProvider.notifier).toggleWishlist(item.productId);
                          },
                          icon: const Icon(Icons.favorite_border, size: 18, color: Colors.grey),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          onPressed: () => ref.read(cartProvider.notifier).removeItem(item.id),
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, () => onChanged(quantity - 1)),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          _btn(Icons.add, () => onChanged(quantity + 1)),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 15, color: kNavy),
      ),
    );
  }
}
