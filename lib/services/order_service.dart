import '../core/api_client.dart';
import '../models/order.dart';
import '../models/product.dart';

class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  Future<PaginatedResponse<Order>> getOrders({
    int page = 1,
    String? status,
    String? search,
    int perPage = 15,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/orders',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
          if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
          if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
        },
      );

      final List data = response.data['data'] as List? ?? [];
      final orders = data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();

      PaginationMeta meta = PaginationMeta(currentPage: page, lastPage: 1, total: orders.length, perPage: perPage);
      if (response.data['meta'] != null) {
        meta = PaginationMeta.fromJson(response.data['meta']);
      }

      return PaginatedResponse(data: orders, meta: meta);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<Order> getOrderDetail(String id) async {
    try {
      final response = await _apiClient.dio.get('/orders/$id');
      final data = response.data['data'] ?? response.data;
      return Order.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<List<OrderTracking>> getTracking(String id) async {
    try {
      final response = await _apiClient.dio.get('/orders/$id/tracking');
      final List data = response.data['data'] as List? ?? [];
      return data.map((e) => OrderTracking.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<Order> cancelOrder(
    String id, {
    required String reason,
    String? explanation,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/orders/$id/cancel',
        data: {
          'reason': reason,
          if (explanation != null && explanation.isNotEmpty) 'explanation': explanation,
        },
      );
      final data = response.data['data'] ?? response.data;
      return Order.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
