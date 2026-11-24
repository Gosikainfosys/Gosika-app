import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/return_model.dart';
import '../../providers/return_provider.dart';

class ReturnsScreen extends ConsumerWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnsAsync = ref.watch(returnListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Returns & Exchanges', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 18)),
      ),
      body: returnsAsync.when(
        data: (returns) {
          if (returns.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(returnListProvider.notifier).fetchReturns(),
              child: ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.assignment_return_outlined, size: 70, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('No return requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
                        const SizedBox(height: 4),
                        Text('Your return or exchange requests will appear here.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(returnListProvider.notifier).fetchReturns(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: returns.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = returns[index];
                return _ReturnCard(returnRequest: item);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(returnListProvider.notifier).fetchReturns(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReturnCard extends ConsumerWidget {
  final ReturnRequest returnRequest;
  const _ReturnCard({required this.returnRequest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(returnRequest.status);

    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Return #${returnRequest.returnNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (returnRequest.statusLabel ?? returnRequest.status).toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              if (returnRequest.productImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: returnRequest.productImage!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      returnRequest.productName ?? 'Item',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kNavy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #${returnRequest.orderNumber} • Qty: ${returnRequest.quantity}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    if (returnRequest.refundAmount > 0)
                      Text(
                        'Refund: ${formatNPR(returnRequest.refundAmount)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            'Reason: ${returnRequest.reason}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),

          if (returnRequest.response != null && returnRequest.response!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Vendor response: ${returnRequest.response}',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: kNavy),
              ),
            ),
          ],

          if (returnRequest.status.toLowerCase() == 'pending') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  try {
                    await ref.read(returnListProvider.notifier).cancelReturn(returnRequest.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Return request cancelled.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to cancel: $e')),
                      );
                    }
                  }
                },
                child: const Text('Cancel Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'pending':
      case 'under_review':
      default:
        return AppColors.primaryOrange;
    }
  }
}
