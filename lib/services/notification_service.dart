import '../core/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<NotificationResponse> getNotifications() async {
    try {
      final response = await _apiClient.dio.get('/customer/notifications');
      return NotificationResponse.fromJson(response.data);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _apiClient.dio.post('/customer/notifications/$id/read');
    } catch (e) {
      // Non-critical, ignore error or log
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.dio.post('/customer/notifications/read-all');
    } catch (e) {
      // Non-critical
    }
  }
}
