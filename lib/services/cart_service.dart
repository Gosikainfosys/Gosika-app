import '../core/api_client.dart';
import '../models/cart.dart';

class CartService {
  final ApiClient _apiClient;

  CartService(this._apiClient);

  Future<Cart> getCart() async {
    final response = await _apiClient.dio.get('/cart');
    final data = response.data['data'] ?? response.data;
    return Cart.fromJson(data);
  }

  Future<void> addToCart({
    required String productId,
    String? variantId,
    int quantity = 1,
  }) async {
    try {
      await _apiClient.dio.post('/cart', data: {
        'product_id': productId,
        'variant_id': variantId,
        'quantity': quantity,
      });
    } catch (_) {
      await _apiClient.dio.post('/cart/items', data: {
        'product_id': productId,
        'variant_id': variantId,
        'quantity': quantity,
      });
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      await _apiClient.dio.patch('/cart/$itemId', data: {
        'quantity': quantity,
      });
    } catch (_) {
      await _apiClient.dio.put('/cart/items/$itemId', data: {
        'quantity': quantity,
      });
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      await _apiClient.dio.delete('/cart/$itemId');
    } catch (_) {
      await _apiClient.dio.delete('/cart/items/$itemId');
    }
  }

  Future<void> clearCart() async {
    try {
      await _apiClient.dio.delete('/cart/clear');
    } catch (_) {
      await _apiClient.dio.delete('/cart');
    }
  }
}
