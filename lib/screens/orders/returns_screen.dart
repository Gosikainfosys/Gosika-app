import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/return_model.dart';
import '../../providers/return_provider.dart';
import '../../shared/widgets/scrollable_filter_tabs.dart';

class ReturnsScreen extends ConsumerStatefulWidget {
  const ReturnsScreen({super.key});

  @override
  ConsumerState<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends ConsumerState<ReturnsScreen> {
  int _selectedTabIndex = 0;
  String? _selectedRequestType;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  String? _dateFrom;
  String? _dateTo;

  final List<Map<String, String?>> _statusTabs = const [
    {'label': 'All', 'value': null},
    {'label': 'Requested', 'value': 'requested'},
    {'label': 'Under Review', 'value': 'under_review'},
    {'label': 'Approved', 'value': 'approved'},
    {'label': 'Pickup Arranged', 'value': 'pickup_arranged'},
    {'label': 'Collected', 'value': 'collected'},
    {'label': 'Inspected', 'value': 'inspected'},
    {'label': 'Refund Pending', 'value': 'refund_pending'},
    {'label': 'Refunded', 'value': 'refunded'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Rejected', 'value': 'rejected'},
    {'label': 'Cancelled', 'value': 'cancelled'},
  ];

  final List<Map<String, String>> _requestTypes = const [
    {'label': 'Return & Refund', 'value': 'return_refund'},
    {'label': 'Exchange', 'value': 'exchange'},
    {'label': 'Replacement', 'value': 'replacement'},
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

  void _toggleRequestType(String val) {
    setState(() {
      if (_selectedRequestType == val) {
        _selectedRequestType = null;
      } else {
        _selectedRequestType = val;
      }
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

  void _clearAllFilters() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _selectedTabIndex = 0;
      _selectedRequestType = null;
      _searchQuery = '';
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

  int get _activeFilterCount {
    int count = 0;
    if (_selectedTabIndex != 0) count++;
    if (_selectedRequestType != null && _selectedRequestType!.isNotEmpty) count++;
    if (_searchQuery.isNotEmpty) count++;
    if (_selectedDateRange != null) count++;
    return count;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final activeStatusLabel = _statusTabs[_selectedTabIndex]['label'];
        final activeTypeLabel = _requestTypes.firstWhere(
          (e) => e['value'] == _selectedRequestType,
          orElse: () => {'label': '', 'value': ''},
        )['label'];

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Filters (${_activeFilterCount})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kNavy),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _clearAllFilters();
                    },
                    child: const Text('Clear All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(),
              if (_selectedTabIndex != 0)
                ListTile(
                  dense: true,
                  title: Text('Status: $activeStatusLabel', style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() => _selectedTabIndex = 0);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              if (_selectedRequestType != null)
                ListTile(
                  dense: true,
                  title: Text('Type: $activeTypeLabel', style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() => _selectedRequestType = null);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              if (_searchQuery.isNotEmpty)
                ListTile(
                  dense: true,
                  title: Text('Search: "$_searchQuery"', style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _clearSearch();
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              if (_selectedDateRange != null)
                ListTile(
                  dense: true,
                  title: Text('Date: $_formattedDateRangeText', style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _clearDateRange();
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ReturnFilter(
      status: _statusTabs[_selectedTabIndex]['value'],
      requestType: _selectedRequestType,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Returns & Exchanges', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 18)),
      ),
      body: Column(
        children: [
          // 1. Status Filter Tabs (Horizontal Scrollable with Arrows & Scrollbar)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: ScrollableFilterTabs(
              labels: _statusTabs.map((e) => e['label']!).toList(),
              selectedIndex: _selectedTabIndex,
              onTabSelected: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
          ),

          // 2. Request Type Filter Chips (Horizontal Scrollable)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _requestTypes.length,
                itemBuilder: (context, index) {
                  final t = _requestTypes[index];
                  final isSelected = _selectedRequestType == t['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        t['label']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : kNavy,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => _toggleRequestType(t['value']!),
                      selectedColor: AppColors.primaryOrange,
                      backgroundColor: Colors.grey[100],
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryOrange : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Search Box & Date Range Filter & Active Filters Indicator
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
                      hintText: 'Search by return number, order number or product name',
                      hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
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

                // Date Range Button & Active Filters Indicator Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date Range Picker Button
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

                    // Active Filters Indicator Button
                    if (_activeFilterCount > 0)
                      OutlinedButton.icon(
                        onPressed: _showFilterBottomSheet,
                        icon: const Icon(Icons.filter_list, size: 16, color: AppColors.primaryOrange),
                        label: Text(
                          'Filters (${_activeFilterCount})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryOrange),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 4. Returns List Content
          Expanded(
            child: _ReturnsListContent(
              filter: filter,
              onClearFilters: _clearAllFilters,
              statusLabel: _statusTabs[_selectedTabIndex]['label']!,
              searchQuery: _searchQuery,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnsListContent extends ConsumerStatefulWidget {
  final ReturnFilter filter;
  final VoidCallback onClearFilters;
  final String statusLabel;
  final String searchQuery;

  const _ReturnsListContent({
    required this.filter,
    required this.onClearFilters,
    required this.statusLabel,
    required this.searchQuery,
  });

  @override
  ConsumerState<_ReturnsListContent> createState() => _ReturnsListContentState();
}

class _ReturnsListContentState extends ConsumerState<_ReturnsListContent> {
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
      ref.read(returnListProvider(widget.filter).notifier).fetchNextPage();
    }
  }

  String _getEmptySubtitle() {
    if (widget.searchQuery.isNotEmpty) {
      return "No returns found for '${widget.searchQuery}'.";
    }
    if (widget.filter.status != null && widget.filter.status!.isNotEmpty) {
      return "No returns with status '${widget.statusLabel}'.";
    }
    if (widget.filter.hasActiveFilters) {
      return "No returns matching the selected filters.";
    }
    return "Items you request to return will appear here.";
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(returnListProvider(widget.filter));

    if (state.isLoading && state.returns.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (state.returns.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryOrange,
        onRefresh: () => ref.read(returnListProvider(widget.filter).notifier).fetchReturns(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Icon(Icons.assignment_return_outlined, size: 70, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      widget.filter.hasActiveFilters ? 'No returns found' : 'No returns yet',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getEmptySubtitle(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    if (widget.filter.hasActiveFilters) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onPressed: widget.onClearFilters,
                        icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                        label: const Text('Clear Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: () => ref.read(returnListProvider(widget.filter).notifier).fetchReturns(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: state.returns.length + (state.isFetchingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == state.returns.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
            );
          }
          final item = state.returns[index];
          return _ReturnCard(returnRequest: item);
        },
      ),
    );
  }
}

class _ReturnCard extends ConsumerWidget {
  final ReturnRequest returnRequest;
  const _ReturnCard({required this.returnRequest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getReturnStatusColor(returnRequest.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showReturnDetailBottomSheet(context, returnRequest, ref),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
              // Header: Return # + Status Badge
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
                      returnRequest.formattedStatusLabel.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Request Type Badge & Created Date Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      returnRequest.formattedRequestTypeLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(returnRequest.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Product Image & Info
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
                        errorWidget: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[100],
                          child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                        ),
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
                        if (returnRequest.refundAmount > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Refund: ${formatNPR(returnRequest.refundAmount)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                'Reason: ${returnRequest.reason}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (returnRequest.response != null && returnRequest.response!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
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
            ],
          ),
        ),
      ),
    );
  }

  void _showReturnDetailBottomSheet(BuildContext context, ReturnRequest item, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Return #${item.returnNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),

              // Status Badges
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getReturnStatusColor(item.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.formattedStatusLabel.toUpperCase(),
                      style: TextStyle(color: _getReturnStatusColor(item.status), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.formattedRequestTypeLabel,
                      style: const TextStyle(color: kNavy, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Info Row
              Row(
                children: [
                  if (item.productImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: item.productImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 30),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy)),
                        const SizedBox(height: 4),
                        Text('Order #${item.orderNumber} • Qty: ${item.quantity}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        if (item.refundAmount > 0) ...[
                          const SizedBox(height: 2),
                          Text('Refund Amount: ${formatNPR(item.refundAmount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Return Details Summary
              _buildDetailRow('Created Date', _formatDate(item.createdAt)),
              if (item.reasonType != null && item.reasonType!.isNotEmpty)
                _buildDetailRow('Reason Type', item.reasonType!),
              _buildDetailRow('Reason', item.reason),
              _buildDetailRow('Preferred Resolution', item.preferredResolution.toUpperCase()),
              if (item.response != null && item.response!.isNotEmpty)
                _buildDetailRow('Vendor Response', item.response!),
              if (item.reviewedAt != null)
                _buildDetailRow('Reviewed Date', _formatDate(item.reviewedAt)),

              if (item.status.toLowerCase() == 'pending' || item.status.toLowerCase() == 'requested') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        const filter = ReturnFilter();
                        await ref.read(returnListProvider(filter).notifier).cancelReturn(item.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return request cancelled.')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
                        }
                      }
                    },
                    child: const Text('Cancel Return Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: kNavy, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Color _getReturnStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
      case 'under_review':
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'pickup_arranged':
      case 'collected':
      case 'inspected':
        return Colors.blue;
      case 'exchange_dispatched':
      case 'replacement_dispatched':
      case 'refund_pending':
        return Colors.purple;
      case 'refunded':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}
