import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown(int initialSeconds) {
    _timer?.cancel();
    setState(() => _secondsRemaining = initialSeconds);
    if (_secondsRemaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsRemaining <= 1) {
          t.cancel();
          setState(() => _secondsRemaining = 0);
        } else {
          setState(() => _secondsRemaining--);
        }
      });
    }
  }

  String _formatTimerText(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showCancelBottomSheet(BuildContext context, Order order) {
    String selectedReason = order.allowedCancellationReasons.isNotEmpty
        ? order.allowedCancellationReasons.first
        : 'Mind changed';
    final explanationCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isCancelling = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bool isOther = selectedReason == 'Other';

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cancel Order',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please select a reason for cancelling Order #${order.orderNumber}:',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    ...order.allowedCancellationReasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(reason, style: const TextStyle(fontSize: 13, color: kNavy)),
                        value: reason,
                        groupValue: selectedReason,
                        activeColor: AppColors.primaryOrange,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedReason = val);
                          }
                        },
                      );
                    }),
                    if (isOther) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: explanationCtrl,
                        maxLines: 3,
                        validator: (val) {
                          if (isOther && (val == null || val.trim().isEmpty)) {
                            return 'Please provide an explanation for cancellation';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Please explain reason *',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isCancelling
                            ? null
                            : () async {
                                if (isOther && !formKey.currentState!.validate()) return;
                                setSheetState(() => isCancelling = true);
                                try {
                                  await ref.read(orderServiceProvider).cancelOrder(
                                        order.id,
                                        reason: selectedReason,
                                        explanation: isOther ? explanationCtrl.text.trim() : null,
                                      );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ref.invalidate(orderDetailProvider(widget.orderId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Order cancelled successfully.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Cancellation failed: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                } finally {
                                  setSheetState(() => isCancelling = false);
                                }
                              },
                        child: isCancelling
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Confirm Cancellation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kNavy)),
      ),
      body: orderAsync.when(
        data: (order) {
          if (_timer == null && order.cancellationSecondsRemaining > 0) {
            _startCountdown(order.cancellationSecondsRemaining);
          }

          final itemsList = order.items.isNotEmpty ? order.items : order.vendorOrders.expand((v) => v.items).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Details Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.orderNumber}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Placed on ${_formatDateTime(order.placedAt)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Text(
                        formatNPR(order.grandTotal),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Section A — Order Status Tracker
                _buildStatusTracker(order.status, order.cancelledReason),

                const SizedBox(height: 16),

                // Section B — Cancellation Section / Timer
                if (order.canCancel && _secondsRemaining > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.primaryOrange, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cancellation Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy)),
                              Text('Window expires in ${_formatTimerText(_secondsRemaining)}', style: const TextStyle(fontSize: 12, color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _showCancelBottomSheet(context, order),
                          child: const Text('Cancel Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  )
                else if (order.cancellationBlockedReason != null && order.cancellationBlockedReason!.isNotEmpty && !order.canCancel)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.grey[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.cancellationBlockedReason!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Section C — Delivery OTP
                if (order.hasDeliveryOtp && order.deliveryOtp != null && order.deliveryOtp!.isNotEmpty)
                  _buildDeliveryOtpSection(order.deliveryOtp!),

                // Section D — Order Items
                _buildOrderItemsSection(itemsList),

                const SizedBox(height: 20),

                // Section E — Price Summary
                _buildPriceSummarySection(order),

                const SizedBox(height: 20),

                // Section F — Shipping Address
                if (order.shippingAddress != null) ...[
                  _buildShippingAddressSection(order.shippingAddress!),
                  const SizedBox(height: 20),
                ],

                // Section G — Payment Info
                _buildPaymentInfoSection(order.paymentMethod, order.paymentStatus),

                // Section H — Return Window
                if (order.canRequestReturn)
                  _buildReturnWindowSection(order.returnWindowExpiresAt),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading order details: $err', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(orderDetailProvider(widget.orderId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section A: Horizontal Stepper
  Widget _buildStatusTracker(String status, String? cancelReason) {
    final s = status.toLowerCase();
    final isCancelled = s == 'cancelled' || s == 'rejected' || s == 'failed';

    if (isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Order Cancelled / Failed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade800),
                ),
              ],
            ),
            if (cancelReason != null && cancelReason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Reason: $cancelReason',
                style: TextStyle(fontSize: 13, color: Colors.red.shade900),
              ),
            ],
          ],
        ),
      );
    }

    final List<Map<String, dynamic>> allSteps = [
      {'key': 'payment_pending', 'label': 'Payment Pending', 'aliases': ['unpaid']},
      {'key': 'pending', 'label': 'Pending', 'aliases': []},
      {'key': 'confirmed', 'label': 'Confirmed', 'aliases': ['accepted']},
      {'key': 'processing', 'label': 'Processing', 'aliases': ['preparing']},
      {'key': 'ready_for_pickup', 'label': 'Ready for Pickup', 'aliases': []},
      {'key': 'picked_up', 'label': 'Picked Up', 'aliases': []},
      {'key': 'out_for_delivery', 'label': 'Out for Delivery', 'aliases': []},
      {'key': 'delivered', 'label': 'Delivered', 'aliases': []},
      {'key': 'completed', 'label': 'Completed', 'aliases': []},
    ];

    final steps = s == 'payment_pending'
        ? allSteps
        : allSteps.where((step) => step['key'] != 'payment_pending').toList();

    int currentIndex = -1;
    for (int i = 0; i < steps.length; i++) {
      final key = steps[i]['key'] as String;
      final aliases = steps[i]['aliases'] as List<String>;
      if (s == key || aliases.contains(s)) {
        currentIndex = i;
        break;
      }
    }
    if (currentIndex == -1) currentIndex = 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(steps.length, (index) {
            final isCompleted = index <= currentIndex;
            final isLast = index == steps.length - 1;
            final label = steps[index]['label'] as String;

            return SizedBox(
              width: 90,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index == 0
                              ? Colors.transparent
                              : (index <= currentIndex ? AppColors.primaryOrange : Colors.grey.shade300),
                        ),
                      ),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? AppColors.primaryOrange : Colors.white,
                          border: Border.all(
                            color: isCompleted ? AppColors.primaryOrange : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 3,
                          color: isLast
                              ? Colors.transparent
                              : (index < currentIndex ? AppColors.primaryOrange : Colors.grey.shade300),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
                      color: isCompleted ? kNavy : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // Section C: Delivery OTP Box
  Widget _buildDeliveryOtpSection(String otp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.blue.shade700, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Share this OTP with your delivery person',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Text(
              otp,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section D: Order Items
  Widget _buildOrderItemsSection(List<OrderItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final item = items[index];
              final statusColor = _getStatusColor(item.deliveryStatus);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[100],
                      child: item.image != null
                          ? CachedNetworkImage(
                              imageUrl: item.image!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(Icons.shopping_bag_outlined, color: Colors.grey[400], size: 28),
                            )
                          : Icon(Icons.shopping_bag_outlined, color: Colors.grey[400], size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.variantName != null && item.variantName!.isNotEmpty)
                          Text('Variant: ${item.variantName}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        if (item.sku != null && item.sku!.isNotEmpty)
                          Text('SKU: ${item.sku}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${formatNPR(item.unitPrice)} × ${item.quantity}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.deliveryStatus.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatNPR(item.lineTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy),
                      ),
                      if (item.canRequestReturn) ...[
                        const SizedBox(height: 6),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryOrange,
                            side: const BorderSide(color: AppColors.primaryOrange),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => context.push('/account/returns'),
                          child: const Text('Request Return', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Section E: Price Summary
  Widget _buildPriceSummarySection(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Price Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPriceRow('Subtotal', formatNPR(order.subtotal)),
              if (order.discount > 0) _buildPriceRow('Discount', '- ${formatNPR(order.discount)}', isDiscount: true),
              _buildPriceRow('Delivery Charge', formatNPR(order.deliveryCharge)),
              if (order.tax > 0) _buildPriceRow('Tax', formatNPR(order.tax)),
              const Divider(height: 20),
              _buildPriceRow('Grand Total', formatNPR(order.grandTotal), isBold: true),
              if (order.refundedAmount > 0) ...[
                const SizedBox(height: 4),
                _buildPriceRow('Refunded Amount', '- ${formatNPR(order.refundedAmount)}', isRefund: true),
              ],
              const SizedBox(height: 4),
              _buildPriceRow('Net Total', formatNPR(order.netTotal), isBold: true, isHighlight: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false, bool isDiscount = false, bool isRefund = false, bool isHighlight = false}) {
    Color valueColor = kNavy;
    if (isDiscount) valueColor = Colors.green;
    if (isRefund) valueColor = Colors.red;
    if (isHighlight) valueColor = AppColors.primaryOrange;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              color: isBold ? kNavy : Colors.grey[700],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Section F: Shipping Address
  Widget _buildShippingAddressSection(Map<String, dynamic> addr) {
    final fullName = addr['full_name']?.toString() ?? addr['name']?.toString() ?? '';
    final phone = addr['phone']?.toString() ?? '';
    final line1 = addr['address_line_1']?.toString() ?? addr['address']?.toString() ?? '';
    final line2 = addr['address_line_2']?.toString();
    final district = addr['district']?.toString();
    final province = addr['province']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Shipping Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fullName.isNotEmpty)
                Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy)),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
              const SizedBox(height: 6),
              Text(
                [line1, if (line2 != null && line2.isNotEmpty) line2, district, province]
                    .where((s) => s != null && s.toString().isNotEmpty)
                    .join(', '),
                style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section G: Payment Info
  Widget _buildPaymentInfoSection(String method, String status) {
    final statusColor = status.toLowerCase() == 'paid' || status.toLowerCase() == 'completed'
        ? Colors.green
        : (status.toLowerCase() == 'pending' ? Colors.orange : Colors.red);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Info', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.payment_rounded, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    method.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section H: Return Window
  Widget _buildReturnWindowSection(DateTime? returnWindowExpiresAt) {
    final dateStr = returnWindowExpiresAt != null
        ? DateFormat('MMM d, yyyy').format(returnWindowExpiresAt)
        : '';

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_return_rounded, color: Colors.teal.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Return Available',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal.shade900),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (dateStr.isNotEmpty)
            Text(
              'Return window closes on $dateStr',
              style: TextStyle(fontSize: 12, color: Colors.teal.shade800),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.push('/account/returns'),
              icon: const Icon(Icons.assignment_return_outlined, color: Colors.white, size: 18),
              label: const Text('Request Return', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'accepted':
        return Colors.blue;
      case 'processing':
      case 'preparing':
        return Colors.purple;
      case 'ready_for_pickup':
      case 'picked_up':
        return Colors.indigo;
      case 'out_for_delivery':
        return Colors.amber.shade800;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
      case 'failed':
        return Colors.red;
      case 'returned':
      case 'refunded':
        return Colors.teal;
      default:
        return kNavy;
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }
}
