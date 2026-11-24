import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/return_model.dart';
import '../services/return_service.dart';
import 'auth_provider.dart';

final returnServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReturnService(apiClient);
});

final returnListProvider = StateNotifierProvider<ReturnListNotifier, AsyncValue<List<ReturnRequest>>>((ref) {
  final service = ref.watch(returnServiceProvider);
  return ReturnListNotifier(service, ref);
});

class ReturnListNotifier extends StateNotifier<AsyncValue<List<ReturnRequest>>> {
  final ReturnService _service;
  final Ref _ref;

  ReturnListNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    fetchReturns();
  }

  Future<void> fetchReturns() async {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final returns = await _service.getReturns();
      state = AsyncValue.data(returns);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
