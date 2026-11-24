import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Set<String> _loadingItems = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartProvider>().fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'My Cart (${cart.itemCount})',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: cart.isLoading && cart.items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)))
          : cart.error != null && cart.items.isEmpty
              ? _buildError(cart.error!)
              : cart.items.isEmpty
                  ? _buildEmpty()
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: cart.items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) => _buildItem(cart.items[i]),
                          ),
                        ),
                        _buildSummary(cart),
                      ],
                    ),
    );
  }

  Widget _buildItem(CartItem item) {
    final isLoading = _loadingItems.contains(item.id);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _remove(item.id),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.image != null
                  ? Image.network(
                      item.image!,
                      width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (item.variantName != null) ...[
                    const SizedBox(height: 2),
                    Text(item.variantName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NPR ${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF97316),
                          fontSize: 15,
                        ),
                      ),
                      // Quantity controls
                      Row(
                        children: [
                          _qtyBtn(
                            icon: Icons.remove,
                            onTap: isLoading ? null : () => item.quantity > 1
                                ? _update(item.id, item.quantity - 1)
                                : _remove(item.id),
                          ),
                          SizedBox(
                            width: 36,
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text('${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          _qtyBtn(
                            icon: Icons.add,
                            onTap: isLoading ? null : () => _update(item.id, item.quantity + 1),
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
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF97316)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFFF97316)),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 80, height: 80,
      color: Colors.grey[200],
      child: Icon(Icons.image_outlined, color: Colors.grey[400]),
    );
  }

  Widget _buildSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
          blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal (${cart.itemCount} items)',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text('NPR ${cart.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pushNamed(context, '/checkout'),
              child: const Text('Proceed to Checkout',
                style: TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Your cart is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Add items to get started',
            style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse Products',
              style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 12),
          const Text('Failed to load cart'),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
            onPressed: () => context.read<CartProvider>().fetchCart(),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _update(String itemId, int quantity) async {
    setState(() => _loadingItems.add(itemId));
    try {
      context.read<CartProvider>().updateQuantity(itemId, quantity);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _loadingItems.remove(itemId));
    }
  }

  Future<void> _remove(String itemId) async {
    try {
      context.read<CartProvider>().removeItem(itemId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove item')));
    }
  }

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      context.read<CartProvider>().clearCart();
    }
  }
}
