import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/payment_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/scrollable_filter_tabs.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  String? _dateFrom;
  String? _dateTo;

  final List<String?> _statuses = [
    null,
    'pending',
    'confirmed',
    'processing',
    'out_for_delivery',
    'delivered',
    'completed',
    'cancelled',
  ];
  final List<String> _tabLabels = [
    'All',
    'Pending',
    'Confirmed',
    'Processing',
    'Out for Delivery',
    'Delivered',
    'Completed',
    'Cancelled',
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim();
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    setState(() {
      _searchQuery = '';
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryOrange,
              onPrimary: Colors.white,
              onSurface: kNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _dateFrom = DateFormat('yyyy-MM-dd').format(picked.start);
        _dateTo = DateFormat('yyyy-MM-dd').format(picked.end);
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
      _dateFrom = null;
      _dateTo = null;
    });
  }

  String get _formattedDateRangeText {
    if (_selectedDateRange == null) return 'Date Range';
    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;
    if (start.year == end.year) {
      return '${DateFormat('MMM dd').format(start)} – ${DateFormat('MMM dd').format(end)}';
    } else {
      return '${DateFormat('MMM dd, yyyy').format(start)} – ${DateFormat('MMM dd, yyyy').format(end)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = OrderFilter(
      status: _statuses[_selectedTabIndex],
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 18)),
      ),
      body: Column(
        children: [
          // 1. Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: ScrollableFilterTabs(
              labels: _tabLabels,
              selectedIndex: _selectedTabIndex,
              onTabSelected: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
          ),

          // 2. Search Box & Date Range Filter Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search TextField
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 13, color: kNavy),
                    decoration: InputDecoration(
                      hintText: 'Search by order number or product name',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.search, size: 20, color: kMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: kMuted),
                              onPressed: _clearSearch,
                              splashRadius: 18,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Date Range Button Row
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _selectDateRange,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedDateRange != null
                                ? AppColors.primaryOrange.withValues(alpha: 0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedDateRange != null
                                  ? AppColors.primaryOrange
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: _selectedDateRange != null
                                    ? AppColors.primaryOrange
                                    : kNavy,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formattedDateRangeText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedDateRange != null
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _selectedDateRange != null
                                      ? AppColors.primaryOrange
                                      : kNavy,
                                ),
                              ),
                              if (_selectedDateRange != null) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: _clearDateRange,
                                  child: const Icon(
                                    Icons.cancel,
                                    size: 16,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 3. Order List Content
          Expanded(
            child: _OrderListContent(filter: filter),
          ),
        ],
      ),
    );
  }
}

class _OrderListContent extends ConsumerStatefulWidget {
  final OrderFilter filter;
  const _OrderListContent({required this.filter});

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
      ref.read(orderListProvider(widget.filter).notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListProvider(widget.filter));

    if (state.isLoading && state.orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (state.orders.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryOrange,
        onRefresh: () => ref.read(orderListProvider(widget.filter).notifier).fetchOrders(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 70, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No orders found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
                  const SizedBox(height: 4),
                  const Text('Try adjusting your search or date filter.', style: TextStyle(color: kMuted, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: () => ref.read(orderListProvider(widget.filter).notifier).fetchOrders(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
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
    final firstItem = order.items.isNotEmpty ? order.items.first : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
              // Header: Order Number + Status Badge
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
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Placed Date
              Text(
                _formatDate(order.placedAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),

              // Payment Method Icon & Payment Status Row
              const SizedBox(height: 8),
              Row(
                children: [
                  paymentMethodIcon(order.paymentMethod),
                  if (order.paymentMethod.toLowerCase() != 'cod') ...[
                    const SizedBox(width: 6),
                    Text(
                      getPaymentMethodLabel(order.paymentMethod),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: getPaymentStatusColor(order.paymentStatus).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.paymentStatus.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: getPaymentStatusColor(order.paymentStatus),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // First Item Preview
              if (firstItem != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[100],
                        child: firstItem.image != null
                            ? CachedNetworkImage(
                                imageUrl: firstItem.image!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Icon(Icons.shopping_bag_outlined, color: Colors.grey[400], size: 22),
                              )
                            : Icon(Icons.shopping_bag_outlined, color: Colors.grey[400], size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstItem.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kNavy),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Qty: ${firstItem.quantity}${firstItem.variantName != null ? ' • ${firstItem.variantName}' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (order.items.length > 1) ...[
                            const SizedBox(height: 2),
                            Text(
                              '+ ${order.items.length - 1} more item${order.items.length - 1 > 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 11, color: AppColors.primaryOrange, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),

              // Footer: Grand Total + Track Order Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total ($totalItems item${totalItems > 1 ? 's' : ''})',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                      Text(
                        formatNPR(order.grandTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange, fontSize: 15),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/orders/${order.id}'),
                    icon: const Icon(Icons.near_me_outlined, size: 14, color: AppColors.primaryOrange),
                    label: const Text(
                      'Track Order',
                      style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryOrange, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }
}
