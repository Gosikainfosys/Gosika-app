import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  int _selectedTabIndex = 0;
  final List<String?> _statuses = [null, 'pending', 'processing', 'out_for_delivery', 'delivered', 'cancelled'];
  final List<String> _tabLabels = ['All', 'Pending', 'Processing', 'Out for Delivery', 'Delivered', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tabLabels.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedTabIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      _tabLabels[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    selectedColor: AppColors.primaryOrange,
                    backgroundColor: Colors.grey[100],
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Order List Content
          Expanded(
            child: _OrderListContent(status: _statuses[_selectedTabIndex]),
          ),
        ],
      ),
    );
  }
}

class _OrderListContent extends ConsumerStatefulWidget {
  final String? status;
  const _OrderListContent({this.status});

  @override
  ConsumerState<_OrderListContent> createState() => _OrderListContentState();
}

class _OrderListContentState extends ConsumerState<_OrderListContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(orderListProvider(widget.status).notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListProvider(widget.status));

    if (state.isLoading && state.orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (state.orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(orderListProvider(widget.status).notifier).fetchOrders(),
        child: ListView(
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 70, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No orders found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
                  const SizedBox(height: 4),
                  const Text('When you place orders, they will appear here.', style: TextStyle(color: kMuted, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(orderListProvider(widget.status).notifier).fetchOrders(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.orders.length + (state.isFetchingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == state.orders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
            );
          }
          final order = state.orders[index];
          return _OrderCard(order: order);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final totalItems = order.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy),
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
          const SizedBox(height: 4),
          Text(
            '${_formatDate(order.placedAt)} • $totalItems item(s) • ${order.paymentMethod.toUpperCase()}',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),

          // Bottom Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatNPR(order.grandTotal),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange, fontSize: 15),
              ),
              InkWell(
                onTap: () => context.push('/orders/${order.id}'),
                child: const Row(
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primaryOrange),
                  ],
                ),
              ),
            ],
          ),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
