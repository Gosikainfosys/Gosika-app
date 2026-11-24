import '../core/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<NotificationResponse> getNotifications({
    int perPage = 15,
    bool? unread,
    String? category,
  }) async {
    try {
      final response = await _apiClient.dio.get('/customer/notifications', queryParameters: {
        'per_page': perPage,
        if (unread != null) 'unread': unread,
        if (category != null && category.isNotEmpty) 'category': category,
      });
      return NotificationResponse.fromJson(response.data);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/customer/notifications/unread-count');
      final count = response.data['data']?['unread_count'] ?? response.data['unread_count'] ?? 0;
      return (count as num).toInt();
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _apiClient.dio.post('/customer/notifications/$id/read');
    } catch (e) {
      // Non-blocking
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.dio.post('/customer/notifications/read-all');
    } catch (e) {
      // Non-blocking
    }
  }

  Future<void> deleteAllRead() async {
    try {
      await _apiClient.dio.delete('/customer/notifications/read');
    } catch (e) {
      // Non-blocking
    }
  }
}
