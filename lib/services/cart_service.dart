import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/cart_item.dart';
import '../models/cart_model.dart';

class CartService {
  final String? _explicitToken;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  CartService([this._explicitToken]);

  Future<Map<String, String>> _getHeaders() async {
    String? token = _explicitToken;
    if (token == null || token.isEmpty) {
      token = await _storage.read(key: kTokenKey);
    }
    if (token == null || token.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('auth_token') ?? prefs.getString(kTokenKey);
      } catch (_) {}
    }

    String sessionId = '';
    try {
      sessionId = await ApiClient.getSessionId();
    } catch (_) {}

    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (sessionId.isNotEmpty) 'X-Session-Id': sessionId,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  CartModel _parseCartData(Map<String, dynamic> body) {
    dynamic rawData = body['data'] ?? body['cart'] ?? body;
    if (rawData is Map<String, dynamic>) {
      if (rawData.containsKey('cart') && rawData['cart'] is Map<String, dynamic>) {
        return CartModel.fromJson(rawData['cart'] as Map<String, dynamic>);
      }
      return CartModel.fromJson(rawData);
    } else if (rawData is List) {
      final items = rawData
          .map((e) => e is Map<String, dynamic> ? CartItem.fromJson(e) : null)
          .whereType<CartItem>()
          .toList();
      final subtotal = items.fold(0.0, (sum, i) => sum + i.totalPrice);
      final count = items.fold(0, (sum, i) => sum + i.quantity);
      return CartModel(
        id: '',
        status: 'active',
        itemCount: count,
        lineCount: items.length,
        subtotal: subtotal,
        items: items,
      );
    }
    return CartModel.empty();
  }

  // GET /cart
  Future<CartModel> fetchCart() async {
    final headers = await _getHeaders();
    final res = await http.get(Uri.parse('$kBaseUrl/cart'), headers: headers);
    
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true || body['data'] != null || body['items'] != null) {
        return _parseCartData(body);
      }
      return CartModel.empty();
    } else if (res.statusCode == 401) {
      throw Exception('Please login to view your cart');
    }
    
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to load cart. Status: ${res.statusCode}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to load cart (Status ${res.statusCode})');
    }
  }

  // POST /cart/items
  Future<CartModel> addItem({
    required String productId,
    String? variantId,
    int quantity = 1,
  }) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('$kBaseUrl/cart/items'),
      headers: headers,
      body: jsonEncode({
        'product_id': productId,
        if (variantId != null) 'variant_id': variantId,
        'quantity': quantity,
      }),
    );
    
    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return _parseCartData(body);
    }
    
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to add item');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to add item to cart (Status ${res.statusCode})');
    }
  }

  // PUT /cart/items/{id}
  Future<CartModel> updateQuantity(String itemId, int quantity) async {
    final headers = await _getHeaders();
    final res = await http.put(
      Uri.parse('$kBaseUrl/cart/items/$itemId'),
      headers: headers,
      body: jsonEncode({'quantity': quantity}),
    );
    
    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return _parseCartData(body);
    }
    
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to update quantity');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update quantity (Status ${res.statusCode})');
    }
  }

  // DELETE /cart/items/{id}
  Future<CartModel> removeItem(String itemId) async {
    final headers = await _getHeaders();
    final res = await http.delete(
      Uri.parse('$kBaseUrl/cart/items/$itemId'),
      headers: headers,
    );
    
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return _parseCartData(body);
    }
    
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to remove item');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to remove item (Status ${res.statusCode})');
    }
  }

  // DELETE /cart
  Future<void> clearCart() async {
    final headers = await _getHeaders();
    await http.delete(Uri.parse('$kBaseUrl/cart'), headers: headers);
  }
}
