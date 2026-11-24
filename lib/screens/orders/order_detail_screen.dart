import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  void _showCancelDialog(Order order) {
    String selectedReason = order.allowedCancellationReasons.isNotEmpty
        ? order.allowedCancellationReasons.first
        : 'Mind changed';
    final explanationCtrl = TextEditingController();
    bool isCancelling = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cancel Order', style: TextStyle(color: kNavy, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please select a reason for cancellation:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: order.allowedCancellationReasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: explanationCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Explanation (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isCancelling ? null : () => Navigator.pop(context),
              child: const Text('Back'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: isCancelling
                  ? null
                  : () async {
                      setDialogState(() => isCancelling = true);
                      try {
                        await ref.read(orderServiceProvider).cancelOrder(
                          order.id,
                          reason: selectedReason,
                          explanation: explanationCtrl.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ref.invalidate(orderDetailProvider(widget.orderId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order cancelled successfully.')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Cancellation failed: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        setDialogState(() => isCancelling = false);
                      }
                    },
              child: isCancelling
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Cancel', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: Colors.white,
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

          final statusColor = _getStatusColor(order.status);
          final itemsList = order.items.isNotEmpty ? order.items : order.vendorOrders.expand((v) => v.items).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header & Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.orderNumber}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Placed on ${_formatDateTime(order.placedAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (order.deliveryOtp != null && order.deliveryOtp!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security_rounded, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              const Text('Delivery OTP: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy)),
                              Text(
                                order.deliveryOtp!,
                                style: const TextStyle(fontWeight: FontWeight.extrabold, fontSize: 16, color: Colors.blue, letterSpacing: 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Cancellation Window Countdown Banner
                if (order.canCancel && _secondsRemaining > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.primaryOrange, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cancellation Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy)),
                              Text('Expires in ${_formatTimerText(_secondsRemaining)}', style: const TextStyle(fontSize: 12, color: AppColors.primaryOrange, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: () => _showCancelDialog(order),
                          child: const Text('Cancel Order'),
                        ),
                      ],
                    ),
                  ),

                // Shipping Address Section
                if (order.shippingAddress != null) ...[
                  const Text('Shipping Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.shippingAddress!['full_name'] != null)
                          Text(
                            order.shippingAddress!['full_name'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy),
                          ),
                        if (order.shippingAddress!['phone'] != null)
                          Text(order.shippingAddress!['phone'].toString(), style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        const SizedBox(height: 4),
                        Text(
                          [
                            order.shippingAddress!['address_line_1'],
                            order.shippingAddress!['address_line_2'],
                            order.shippingAddress!['district'],
                            order.shippingAddress!['province'],
                          ].where((s) => s != null && s.toString().isNotEmpty).join(', '),
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Order Items Section
                const Text('Order Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: itemsList.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.image != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: item.image!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                              ),
                            const SizedBox(width: 12),
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
                                  if (item.variantName != null)
                                    Text('Variant: ${item.variantName}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${formatNPR(item.unitPrice)} × ${item.quantity}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[800]),
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
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () => context.push('/account/returns'),
                                    child: const Text(
                                      'Request Return',
                                      style: TextStyle(color: AppColors.primaryOrange, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // Payment & Price Breakdown Section
                const Text('Payment Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Payment Method', order.paymentMethod.toUpperCase()),
                      _buildSummaryRow('Payment Status', order.paymentStatus.toUpperCase()),
                      const Divider(height: 16),
                      _buildSummaryRow('Subtotal', formatNPR(order.subtotal)),
                      _buildSummaryRow('Delivery Charge', formatNPR(order.deliveryCharge)),
                      if (order.discount > 0) _buildSummaryRow('Discount', '- ${formatNPR(order.discount)}'),
                      if (order.tax > 0) _buildSummaryRow('Tax', formatNPR(order.tax)),
                      const Divider(height: 16),
                      _buildSummaryRow('Grand Total', formatNPR(order.grandTotal), isBold: true),
                    ],
                  ),
                ),

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

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isBold ? kNavy : Colors.grey[700], fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 13, color: isBold ? AppColors.primaryOrange : kNavy, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
      case 'preparing':
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'ready_for_pickup':
      case 'picked_up':
      case 'out_for_delivery':
        return Colors.blue;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return kNavy;
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
