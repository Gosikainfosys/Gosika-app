import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';
import '../../core/payment_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/platform_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/address.dart';
import '../../models/cart_item.dart';
import '../../services/checkout_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<String>? selectedItemIds;

  const CheckoutScreen({
    super.key,
    this.selectedItemIds,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  CustomerAddress? _selectedAddress;
  String _selectedPayment = 'cod';
  bool _isPlacingOrder = false;
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  List<CartItem> _getFilteredItems(CartProvider cartState) {
    if (widget.selectedItemIds != null && widget.selectedItemIds!.isNotEmpty) {
      return cartState.items.where((e) => widget.selectedItemIds!.contains(e.id)).toList();
    }
    return cartState.items;
  }

  double _calculateSubtotal(List<CartItem> items) {
    double total = 0.0;
    for (final item in items) {
      total += item.totalPrice > 0 ? item.totalPrice : (item.unitPrice * item.quantity);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartProvider>();
    final addressesAsync = ref.watch(addressListProvider);

    if (cartState.isLoading && cartState.items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kNavy)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    final checkoutItems = _getFilteredItems(cartState);
    final subtotal = _calculateSubtotal(checkoutItems);
    const double shippingFee = 0.0; // Free shipping default or calculated

    if (checkoutItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kNavy)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 64, color: kMuted),
              const SizedBox(height: 12),
              const Text('No items selected for checkout'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                child: const Text('Return to Cart', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kNavy),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Selected Items Summary
            _buildSectionTitle('Order Items (${checkoutItems.length})'),
            const SizedBox(height: 8),
            Material(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: checkoutItems.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = checkoutItems[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: item.image != null && item.image!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.image!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey[200]),
                                errorWidget: (context, url, err) => const Icon(Icons.image, size: 20),
                              )
                            : Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 20)),
                      ),
                    ),
                    title: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text('Qty: ${item.quantity} × ${formatNPR(item.unitPrice)}', style: const TextStyle(fontSize: 11)),
                    trailing: Text(
                      formatNPR(item.totalPrice > 0 ? item.totalPrice : (item.unitPrice * item.quantity)),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryOrange),
                    ),
                  );
                },
              ),
            ),
          ),
            const SizedBox(height: 24),

            // 2. Delivery Address Section
            _buildSectionTitle('Delivery Address', onActionTap: () {
              context.push('/checkout/address/new');
            }, actionText: 'Change'),
            const SizedBox(height: 8),
            addressesAsync.when(
              data: (list) {
                if (list.isEmpty) return _buildAddAddressCta();
                _selectedAddress ??= list.firstWhere((e) => e.isDefault, orElse: () => list.first);
                return _buildAddressCard(_selectedAddress!);
              },
              loading: () => Container(
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange),
              ),
              error: (e, s) => Text('Failed to load addresses: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
            const SizedBox(height: 24),

            // 3. Payment Method Section
            _buildSectionTitle('Payment Method'),
            const SizedBox(height: 8),
            _buildPaymentMethodOption(
              id: 'cod',
              title: 'Cash on Delivery (COD)',
              subtitle: 'Pay with cash upon delivery',
              icon: Icons.payments_outlined,
            ),
            _buildPaymentMethodOption(
              id: 'esewa',
              title: 'eSewa Mobile Wallet',
              subtitle: 'Pay securely via eSewa',
              customIcon: paymentMethodIcon('esewa'),
            ),
            _buildPaymentMethodOption(
              id: 'khalti',
              title: 'Khalti Mobile Wallet',
              subtitle: 'Pay securely via Khalti',
              customIcon: paymentMethodIcon('khalti'),
            ),
            const SizedBox(height: 24),

            // 4. Instructions
            _buildSectionTitle('Delivery Instructions (Optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _instructionsController,
              decoration: InputDecoration(
                hintText: 'e.g., Leave package with neighbor or call before delivery',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                fillColor: Colors.grey[50],
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // 5. Price Breakdown Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Items Subtotal', formatNPR(subtotal)),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Shipping Fee', formatNPR(shippingFee)),
                  const Divider(height: 20),
                  _buildSummaryRow(
                    'Total Payable',
                    formatNPR(subtotal + shippingFee),
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 11, color: kMuted)),
                  Text(
                    formatNPR(subtotal + shippingFee),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isPlacingOrder ? null : () => _handlePlaceOrder(checkoutItems),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Place Order', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onActionTap, String? actionText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
        if (onActionTap != null && actionText != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(actionText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
          ),
      ],
    );
  }

  Widget _buildAddAddressCta() {
    return GestureDetector(
      onTap: () => context.push('/checkout/address/new'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryOrange.withOpacity(0.4), style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt_outlined, color: AppColors.primaryOrange),
            SizedBox(width: 8),
            Text('Add Shipping Address', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(CustomerAddress addr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primaryOrange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(addr.fullName ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                      child: Text(addr.addressType.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kMuted)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(addr.phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(addr.fullDisplayAddress, style: const TextStyle(fontSize: 12, color: kInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required String id,
    required String title,
    required String subtitle,
    IconData? icon,
    Widget? customIcon,
  }) {
    final isSelected = _selectedPayment == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: id,
              groupValue: _selectedPayment,
              activeColor: AppColors.primaryOrange,
              onChanged: (val) => setState(() => _selectedPayment = val!),
            ),
            if (customIcon != null) ...[
              customIcon,
              const SizedBox(width: 12),
            ] else if (icon != null) ...[
              Icon(icon, color: isSelected ? AppColors.primaryOrange : kNavy),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? kNavy : kMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppColors.primaryOrange : kNavy,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePlaceOrder(List<CartItem> items) async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add a delivery address.')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);
    try {
      final cartItemIds = items.map((e) => e.id).toList();
      final checkoutService = CheckoutService(await ref.read(apiClientProvider));

      final result = await checkoutService.initiateCheckout(
        cartItemIds: cartItemIds,
        shippingAddressId: _selectedAddress!.id,
        billingAddressId: _selectedAddress!.id,
        paymentMethod: _selectedPayment,
        deliveryInstructions: _instructionsController.text.trim(),
      );

      if (mounted) {
        context.read<CartProvider>().fetchCart();

        if (_selectedPayment == 'cod' || result.paymentUrl == null) {
          context.go('/checkout/success', extra: result.orderNumber ?? result.orderId);
        } else {
          context.push('/checkout/payment', extra: {
            'orderId': result.orderId,
            'method': _selectedPayment,
            'paymentUrl': result.paymentUrl,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }
}
