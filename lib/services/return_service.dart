import '../core/api_client.dart';
import '../models/product.dart';
import '../models/return_model.dart';

class ReturnService {
  final ApiClient _apiClient;

  ReturnService(this._apiClient);

  Future<PaginatedResponse<ReturnRequest>> getReturns({
    int page = 1,
    int perPage = 15,
    String? status,
    String? requestType,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final response = await _apiClient.dio.get('/customer/returns', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null && status.isNotEmpty) 'status': status,
        if (requestType != null && requestType.isNotEmpty) 'request_type': requestType,
        if (search != null && search.isNotEmpty) 'search': search,
        if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
      });

      final List data = response.data['data'] as List? ?? [];
      final returns = data.map((e) => ReturnRequest.fromJson(e as Map<String, dynamic>)).toList();

      PaginationMeta meta = PaginationMeta(currentPage: page, lastPage: 1, total: returns.length, perPage: perPage);
      if (response.data['meta'] != null) {
        meta = PaginationMeta.fromJson(response.data['meta']);
      }

      return PaginatedResponse(data: returns, meta: meta);
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
