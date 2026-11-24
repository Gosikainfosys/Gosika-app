import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ApiClient());
});

final notificationListProvider = StateNotifierProvider<NotificationListNotifier, AsyncValue<NotificationResponse>>((ref) {
  return NotificationListNotifier(ref.watch(notificationServiceProvider), ref);
});

class NotificationListNotifier extends StateNotifier<AsyncValue<NotificationResponse>> {
  final NotificationService _service;
  final Ref _ref;

  NotificationListNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadNotifications();

    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated && next.isAuthenticated) {
        loadNotifications();
      }
    });
  }

  Future<void> loadNotifications() async {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      state = AsyncValue.data(NotificationResponse(notifications: [], unreadCount: 0));
      return;
    }
    try {
      state = const AsyncValue.loading();
      final res = await _service.getNotifications();
      state = AsyncValue.data(res);
    } catch (e, st) {
      final isAuthenticated = _ref.read(authProvider).isAuthenticated;
      final errorMsg = ApiClient.parseError(e).toLowerCase();
      if (!isAuthenticated || errorMsg.contains('unauthenticated') || errorMsg.contains('401') || errorMsg.contains('unauthorized')) {
        state = AsyncValue.data(NotificationResponse(notifications: [], unreadCount: 0));
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() async {
    try {
      final isAuthenticated = _ref.read(authProvider).isAuthenticated;
      if (!isAuthenticated) {
        state = AsyncValue.data(NotificationResponse(notifications: [], unreadCount: 0));
        return;
      }
      final res = await _service.getNotifications();
      state = AsyncValue.data(res);
    } catch (e) {
      // Keep existing state
    }
  }

  Future<void> markAsRead(String id) async {
    final current = state.value;
    if (current == null) return;

    final updatedList = current.notifications.map((n) {
      if (n.id == id && !n.isRead) {
        return NotificationItem(
          id: n.id,
          type: n.type,
          title: n.title,
          message: n.message,
          link: n.link,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();

    final newUnreadCount = (current.unreadCount - 1).clamp(0, 999);
    state = AsyncValue.data(NotificationResponse(
      notifications: updatedList,
      unreadCount: newUnreadCount,
    ));

    await _service.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final current = state.value;
    if (current == null) return;

    final updatedList = current.notifications.map((n) {
      return NotificationItem(
        id: n.id,
        type: n.type,
        title: n.title,
        message: n.message,
        link: n.link,
        readAt: DateTime.now(),
        createdAt: n.createdAt,
      );
    }).toList();

    state = AsyncValue.data(NotificationResponse(
      notifications: updatedList,
      unreadCount: 0,
    ));

    await _service.markAllAsRead();
  }

  Future<void> deleteAllRead() async {
    final current = state.value;
    if (current == null) return;

    final unreadOnly = current.notifications.where((n) => !n.isRead).toList();
    state = AsyncValue.data(NotificationResponse(
      notifications: unreadOnly,
      unreadCount: unreadOnly.length,
    ));

    await _service.deleteAllRead();
  }
}
