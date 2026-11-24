import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isLoading => false;
  String? get error => null;

  void addItem(Product product, {int quantity = 1, String? variantName}) {
    final index = _items.indexWhere((i) => i.productId == product.id && i.variantName == variantName);
    if (index >= 0) {
      final existing = _items[index];
      _items[index] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      _items.add(CartItem(
        id: '${product.id}_${variantName ?? 'default'}',
        productId: product.id,
        name: product.name,
        image: product.image ?? (product.images.isNotEmpty ? product.images.first : null),
        unitPrice: product.price,
        quantity: quantity,
        variantName: variantName,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.any((i) => i.productId == productId);
  }

  CartItem? getItemByProduct(String productId) {
    try {
      return _items.firstWhere((i) => i.productId == productId);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchCart() async {
    notifyListeners();
  }

  void setToken(String? token) {
    // No-op for local normal cart
  }
}
