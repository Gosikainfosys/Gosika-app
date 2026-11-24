import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import 'auth_provider.dart';

final reviewServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReviewService(apiClient);
});

final customerReviewsProvider = StateNotifierProvider<CustomerReviewsNotifier, AsyncValue<List<CustomerReview>>>((ref) {
  final service = ref.watch(reviewServiceProvider);
  return CustomerReviewsNotifier(service, ref);
});

final pendingReviewsProvider = StateNotifierProvider<PendingReviewsNotifier, AsyncValue<List<PendingReviewItem>>>((ref) {
  final service = ref.watch(reviewServiceProvider);
  return PendingReviewsNotifier(service, ref);
});

class CustomerReviewsNotifier extends StateNotifier<AsyncValue<List<CustomerReview>>> {
  final ReviewService _service;
  final Ref _ref;

  CustomerReviewsNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    fetchReviews();

    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated && next.isAuthenticated) {
        fetchReviews();
      }
    });
  }

  Future<void> fetchReviews() async {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final list = await _service.getReviews();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class PendingReviewsNotifier extends StateNotifier<AsyncValue<List<PendingReviewItem>>> {
  final ReviewService _service;
  final Ref _ref;

  PendingReviewsNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    fetchPendingReviews();

    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated && next.isAuthenticated) {
        fetchPendingReviews();
      }
    });
  }

  Future<void> fetchPendingReviews() async {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final list = await _service.getPendingReviews();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
