import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_model.dart';

const String _base = 'https://gosika.sital.info.np/api/v1';

class CartService {
  final String? token;
  CartService(this.token);

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${token ?? ''}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // GET /cart
  Future<CartModel> fetchCart() async {
    final res = await http.get(Uri.parse('$_base/cart'), headers: _headers);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return CartModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to load cart');
  }

  // POST /cart/items
  Future<CartModel> addItem({
    required String productId,
    String? variantId,
    int quantity = 1,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/cart/items'),
      headers: _headers,
      body: jsonEncode({
        'product_id': productId,
        if (variantId != null) 'variant_id': variantId,
        'quantity': quantity,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      // response is { data: { item: uuid, cart: {...} } }
      final cartData = (body['data'] as Map<String, dynamic>)['cart']
          as Map<String, dynamic>;
      return CartModel.fromJson(cartData);
    }
    throw Exception(body['message'] ?? 'Failed to add item');
  }

  // PUT /cart/items/{id}
  Future<CartModel> updateQuantity(String itemId, int quantity) async {
    final res = await http.put(
      Uri.parse('$_base/cart/items/$itemId'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return CartModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to update quantity');
  }

  // DELETE /cart/items/{id}
  Future<CartModel> removeItem(String itemId) async {
    final res = await http.delete(
      Uri.parse('$_base/cart/items/$itemId'),
      headers: _headers,
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return CartModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to remove item');
  }

  // DELETE /cart
  Future<void> clearCart() async {
    await http.delete(Uri.parse('$_base/cart'), headers: _headers);
  }
}
