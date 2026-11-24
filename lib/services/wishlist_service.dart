import '../core/api_client.dart';
import '../models/product.dart';

class WishlistItem {
  final String id;
  final String productId;
  final Product product;
  final DateTime? addedAt;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.product,
    this.addedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final prodObj = json['product'] is Map<String, dynamic>
        ? Product.fromJson(json['product'])
        : Product.fromJson(json);

    return WishlistItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? json['id']?.toString() ?? '',
      product: prodObj,
      addedAt: json['added_at'] != null ? DateTime.tryParse(json['added_at'].toString()) : null,
    );
  }
}

class WishlistService {
  final ApiClient _apiClient;

  WishlistService(this._apiClient);

  Future<List<WishlistItem>> getWishlist() async {
    try {
      final response = await _apiClient.dio.get('/wishlist');
      final data = response.data['data'];

      List rawItems = [];
      if (data is Map<String, dynamic> && data['items'] is List) {
        rawItems = data['items'];
      } else if (data is List) {
        rawItems = data;
      }

      return rawItems.map((e) => WishlistItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<bool> addToWishlist(String productId) async {
    try {
      final response = await _apiClient.dio.post('/wishlist/items', data: {'product_id': productId});
      return response.data?['data']?['wishlisted'] == true;
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<bool> removeFromWishlist(String productId) async {
    try {
      final response = await _apiClient.dio.delete('/wishlist/items', data: {'product_id': productId});
      return response.data?['data']?['wishlisted'] == true;
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<bool> checkStatus(String productId) async {
    try {
      final response = await _apiClient.dio.get('/wishlist/status/$productId');
      return response.data?['data']?['wishlisted'] == true;
    } catch (e) {
      return false;
    }
  }
}
