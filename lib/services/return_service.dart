import '../core/api_client.dart';
import '../models/return_model.dart';

class ReturnService {
  final ApiClient _apiClient;

  ReturnService(this._apiClient);

  Future<List<ReturnRequest>> getReturns({int perPage = 15}) async {
    try {
      final response = await _apiClient.dio.get('/customer/returns', queryParameters: {
        'per_page': perPage,
      });
      final List data = response.data['data'] as List? ?? [];
      return data.map((e) => ReturnRequest.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<ReturnRequest> submitReturn({
    required String orderItemId,
    required String requestType,
    required String reasonType,
    required String reason,
    required int quantity,
    required String preferredResolution,
  }) async {
    try {
      final response = await _apiClient.dio.post('/customer/returns', data: {
        'order_item_id': orderItemId,
        'request_type': requestType,
        'reason_type': reasonType,
        'reason': reason,
        'quantity': quantity,
        'preferred_resolution': preferredResolution,
      });
      final data = response.data['data'] ?? response.data;
      return ReturnRequest.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> cancelReturn(String returnId) async {
    try {
      await _apiClient.dio.post('/customer/returns/$returnId/cancel');
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
