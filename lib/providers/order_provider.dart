import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';

final orderServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderService(apiClient);
});

final orderDetailProvider = FutureProvider.family<Order, String>((ref, id) async {
  final service = ref.watch(orderServiceProvider);
  return service.getOrderDetail(id);
});

final orderTrackingProvider = FutureProvider.family<List<OrderTracking>, String>((ref, id) async {
  final service = ref.watch(orderServiceProvider);
  return service.getTracking(id);
});

class OrderFilter {
  final String? status;
  final String? search;
  final String? dateFrom;
  final String? dateTo;

  const OrderFilter({
    this.status,
    this.search,
    this.dateFrom,
    this.dateTo,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          search == other.search &&
          dateFrom == other.dateFrom &&
          dateTo == other.dateTo;

  @override
  int get hashCode =>
      status.hashCode ^ search.hashCode ^ dateFrom.hashCode ^ dateTo.hashCode;
}

class OrderListState {
  final List<Order> orders;
  final bool isLoading;
  final bool isFetchingMore;
  final String? error;
  final PaginationMeta? meta;

  OrderListState({
    this.orders = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.error,
    this.meta,
  });

  OrderListState copyWith({
    List<Order>? orders,
    bool? isLoading,
    bool? isFetchingMore,
    String? error,
    PaginationMeta? meta,
    bool clearError = false,
  }) {
    return OrderListState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: clearError ? null : (error ?? this.error),
      meta: meta ?? this.meta,
    );
  }

  bool get hasMore => meta == null || meta!.currentPage < meta!.lastPage;
}

class OrderListNotifier extends StateNotifier<OrderListState> {
  final OrderService _service;
  final OrderFilter filter;

  OrderListNotifier(this._service, this.filter) : super(OrderListState()) {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _service.getOrders(
        page: 1,
        status: filter.status,
        search: filter.search,
        dateFrom: filter.dateFrom,
        dateTo: filter.dateTo,
      );
      state = state.copyWith(
        orders: res.data,
        meta: res.meta,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isFetchingMore || !state.hasMore) return;
    final nextPage = (state.meta?.currentPage ?? 1) + 1;

    state = state.copyWith(isFetchingMore: true);
    try {
      final res = await _service.getOrders(
        page: nextPage,
        status: filter.status,
        search: filter.search,
        dateFrom: filter.dateFrom,
        dateTo: filter.dateTo,
      );
      state = state.copyWith(
        orders: [...state.orders, ...res.data],
        meta: res.meta,
        isFetchingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isFetchingMore: false);
    }
  }

  Future<void> cancelOrder(String orderId, String reason, String? explanation) async {
    try {
      final updatedOrder = await _service.cancelOrder(orderId, reason: reason, explanation: explanation);
      final updatedList = state.orders.map((o) => o.id == orderId ? updatedOrder : o).toList();
      state = state.copyWith(orders: updatedList);
    } catch (e) {
      rethrow;
    }
  }
}

final orderListProvider = StateNotifierProvider.autoDispose.family<OrderListNotifier, OrderListState, OrderFilter>((ref, filter) {
  final service = ref.watch(orderServiceProvider);
  return OrderListNotifier(service, filter);
});
