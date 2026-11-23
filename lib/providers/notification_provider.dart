import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ApiClient());
});

final notificationListProvider = StateNotifierProvider<NotificationListNotifier, AsyncValue<NotificationResponse>>((ref) {
  return NotificationListNotifier(ref.watch(notificationServiceProvider));
});

class NotificationListNotifier extends StateNotifier<AsyncValue<NotificationResponse>> {
  final NotificationService _service;

  NotificationListNotifier(this._service) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      state = const AsyncValue.loading();
      final res = await _service.getNotifications();
      state = AsyncValue.data(res);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final res = await _service.getNotifications();
      state = AsyncValue.data(res);
    } catch (e) {
      // Keep existing state on refresh error
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
}
