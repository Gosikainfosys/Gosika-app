import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/return_model.dart';
import '../services/return_service.dart';
import 'auth_provider.dart';

final returnServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReturnService(apiClient);
});

class ReturnFilter {
  final String? status;
  final String? requestType;
  final String? search;
  final String? dateFrom;
  final String? dateTo;

  const ReturnFilter({
    this.status,
    this.requestType,
    this.search,
    this.dateFrom,
    this.dateTo,
  });

  bool get hasActiveFilters {
    return (status != null && status!.isNotEmpty) ||
        (requestType != null && requestType!.isNotEmpty) ||
        (search != null && search!.isNotEmpty) ||
        (dateFrom != null && dateFrom!.isNotEmpty) ||
        (dateTo != null && dateTo!.isNotEmpty);
  }

  int get activeFilterCount {
    int count = 0;
    if (status != null && status!.isNotEmpty) count++;
    if (requestType != null && requestType!.isNotEmpty) count++;
    if (search != null && search!.isNotEmpty) count++;
    if (dateFrom != null && dateFrom!.isNotEmpty && dateTo != null && dateTo!.isNotEmpty) count++;
    return count;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          requestType == other.requestType &&
          search == other.search &&
          dateFrom == other.dateFrom &&
          dateTo == other.dateTo;

  @override
  int get hashCode =>
      status.hashCode ^
      requestType.hashCode ^
      search.hashCode ^
      dateFrom.hashCode ^
      dateTo.hashCode;
}

class ReturnListState {
  final List<ReturnRequest> returns;
  final bool isLoading;
  final bool isFetchingMore;
  final String? error;
  final PaginationMeta? meta;

  ReturnListState({
    this.returns = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.error,
    this.meta,
  });

  ReturnListState copyWith({
    List<ReturnRequest>? returns,
    bool? isLoading,
    bool? isFetchingMore,
    String? error,
    PaginationMeta? meta,
    bool clearError = false,
  }) {
    return ReturnListState(
      returns: returns ?? this.returns,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: clearError ? null : (error ?? this.error),
      meta: meta ?? this.meta,
    );
  }

  bool get hasMore => meta == null || meta!.currentPage < meta!.lastPage;
}

class ReturnListNotifier extends StateNotifier<ReturnListState> {
  final ReturnService _service;
  final ReturnFilter filter;
  final Ref _ref;

  ReturnListNotifier(this._service, this.filter, this._ref) : super(ReturnListState()) {
    fetchReturns();
  }

  Future<void> fetchReturns() async {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      state = ReturnListState(returns: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _service.getReturns(
        page: 1,
        perPage: 15,
        status: filter.status,
        requestType: filter.requestType,
        search: filter.search,
        dateFrom: filter.dateFrom,
        dateTo: filter.dateTo,
      );
      state = state.copyWith(
        returns: res.data,
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
      final res = await _service.getReturns(
        page: nextPage,
        perPage: 15,
        status: filter.status,
        requestType: filter.requestType,
        search: filter.search,
        dateFrom: filter.dateFrom,
        dateTo: filter.dateTo,
      );
      state = state.copyWith(
        returns: [...state.returns, ...res.data],
        meta: res.meta,
        isFetchingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isFetchingMore: false);
    }
  }

  Future<void> submitReturn({
    required String orderItemId,
    required String requestType,
    required String reasonType,
    required String reason,
    required int quantity,
    required String preferredResolution,
  }) async {
    try {
      await _service.submitReturn(
        orderItemId: orderItemId,
        requestType: requestType,
        reasonType: reasonType,
        reason: reason,
        quantity: quantity,
        preferredResolution: preferredResolution,
      );
      await fetchReturns();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelReturn(String returnId) async {
    try {
      await _service.cancelReturn(returnId);
      await fetchReturns();
    } catch (e) {
      rethrow;
    }
  }
}

final returnListProvider = StateNotifierProvider.autoDispose.family<ReturnListNotifier, ReturnListState, ReturnFilter>((ref, filter) {
  final service = ref.watch(returnServiceProvider);
  return ReturnListNotifier(service, filter, ref);
});
