import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/platform_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/address.dart';
import '../../models/cart.dart';
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

  List<CartItem> _getFilteredItems(Cart cart) {
    if (widget.selectedItemIds != null && widget.selectedItemIds!.isNotEmpty) {
      return cart.items.where((e) => widget.selectedItemIds!.contains(e.id)).toList();
    }
    return cart.items;
  }

  double _calculateSubtotal(List<CartItem> items) {
    double total = 0.0;
    for (final item in items) {
      total += item.lineTotal > 0 ? item.lineTotal : (item.unitPrice * item.quantity);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final addressesAsync = ref.watch(addressListProvider);
    final platformConfig = ref.watch(platformConfigProvider);

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
      body: cartAsync.when(
        data: (cart) {
          final checkoutItems = _getFilteredItems(cart);
          final subtotal = _calculateSubtotal(checkoutItems);

          if (checkoutItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 64, color: kMuted),
                  const SizedBox(height: 12),
                  const Text('No items selected for checkout'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Return to Cart'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Selected Items Summary
                _buildSectionTitle('Order Items (${checkoutItems.length})'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
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
                          item.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text('Qty: ${item.quantity} × ${formatNPR(item.unitPrice)}', style: const TextStyle(fontSize: 11)),
                        trailing: Text(
                          formatNPR(item.lineTotal > 0 ? item.lineTotal : (item.unitPrice * item.quantity)),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryOrange),
                        ),
                      );
                    },
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
                  loading: () => const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF5722))),
                  ),
                  error: (e, s) => Text('Error loading addresses: $e'),
                ),
                const SizedBox(height: 24),

                // 3. Payment Method Section
                _buildSectionTitle('Payment Method'),
                const SizedBox(height: 8),
                platformConfig.when(
                  data: (config) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        if (config.checkout.codEnabled)
                          _buildPaymentOption('cod', 'Cash on Delivery (COD)', Icons.payments_outlined),
                        if (config.checkout.esewaEnabled)
                          _buildPaymentOption('esewa', 'eSewa Digital Wallet', Icons.account_balance_wallet_outlined),
                        if (config.checkout.khaltiEnabled)
                          _buildPaymentOption('khalti', 'Khalti Digital Wallet', Icons.account_balance_wallet),
                      ],
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildPaymentOption('cod', 'Cash on Delivery (COD)', Icons.payments_outlined),
                        _buildPaymentOption('esewa', 'eSewa Digital Wallet', Icons.account_balance_wallet_outlined),
                        _buildPaymentOption('khalti', 'Khalti Digital Wallet', Icons.account_balance_wallet),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Delivery Instructions Section
                _buildSectionTitle('Delivery Instructions (Optional)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _instructionsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Leave package at gate or call before delivery',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    contentPadding: const EdgeInsets.all(12),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Order Summary Section
                _buildSectionTitle('Order Summary'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Items Subtotal (${checkoutItems.length})', formatNPR(subtotal)),
                      const SizedBox(height: 6),
                      _buildSummaryRow('Delivery Fee', 'रु 0.00'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1),
                      ),
                      _buildSummaryRow('Grand Total', formatNPR(subtotal), isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Place Order Button
                ElevatedButton(
                  onPressed: (_selectedAddress == null || _isPlacingOrder)
                      ? null
                      : () => _handlePlaceOrder(checkoutItems),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isPlacingOrder
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF5722))),
        ),
        error: (e, s) => Center(child: Text('Error loading checkout: $e')),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onActionTap, String actionText = '+ Add New'}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
        if (onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
            ),
          ),
      ],
    );
  }

  Widget _buildAddAddressCta() {
    return InkWell(
      onTap: () => context.push('/checkout/address/new'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.05),
          border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.add_location_alt_outlined, color: Color(0xFFFF5722), size: 32),
            SizedBox(height: 8),
            Text(
              'No saved addresses. Tap to add one.',
              style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 13),
            ),
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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFFFF5722), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addr.label ?? addr.addressType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy)),
                const SizedBox(height: 2),
                if (addr.fullName != null && addr.fullName!.isNotEmpty)
                  Text(addr.fullName!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text(addr.addressLine1, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(addr.phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String val, String title, IconData icon) {
    final isSelected = _selectedPayment == val;
    return InkWell(
      onTap: () => setState(() => _selectedPayment = val),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Radio<String>(
              value: val,
              groupValue: _selectedPayment,
              onChanged: (v) => setState(() => _selectedPayment = v!),
              activeColor: AppColors.primaryOrange,
            ),
            if (val == 'esewa')
              Image.asset(
                'assets/illustrations/esewa_icon.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(icon, color: isSelected ? AppColors.primaryOrange : Colors.grey[600], size: 20),
              )
            else
              Icon(icon, color: isSelected ? AppColors.primaryOrange : Colors.grey[600], size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
                color: kNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            color: isBold ? kNavy : Colors.grey[600],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 13,
            color: isBold ? const Color(0xFFFF5722) : kNavy,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
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
        ref.invalidate(cartProvider);

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
