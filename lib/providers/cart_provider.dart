import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/cart_model.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  CartModel _cart = CartModel.empty();
  bool _isLoading = false;
  String? _error;
  String? _token;

  CartProvider() {
    fetchCart();
  }

  CartModel get cart => _cart;
  List<CartItem> get items => _cart.items;
  int get itemCount => _cart.itemCount;
  double get subtotal => _cart.subtotal;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CartService get _service => CartService(_token);

  void setToken(String? token) {
    if (_token != token) {
      _token = token;
      fetchCart();
    }
  }

  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cart = await _service.fetchCart();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(
    Product product, {
    int quantity = 1,
    String? variantId,
    String? variantName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cart = await _service.addItem(
        productId: product.id,
        variantId: variantId,
        quantity: quantity,
      );
    } catch (e) {
      // Fallback for offline / guest mode local add
      final index = _cart.items.indexWhere(
          (i) => i.productId == product.id && i.variantName == variantName);
      List<CartItem> newItems = List.from(_cart.items);
      if (index >= 0) {
        final existing = newItems[index];
        newItems[index] =
            existing.copyWith(quantity: existing.quantity + quantity);
      } else {
        newItems.add(CartItem(
          id: '${product.id}_${variantName ?? 'default'}',
          productId: product.id,
          name: product.name,
          image: product.image ??
              (product.images.isNotEmpty ? product.images.first : null),
          unitPrice: product.price,
          quantity: quantity,
          totalPrice: product.price * quantity,
          variantId: variantId,
          variantName: variantName,
        ));
      }
      final newCount = newItems.fold(0, (sum, item) => sum + item.quantity);
      final newSubtotal =
          newItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      _cart = _cart.copyWith(
        items: newItems,
        itemCount: newCount,
        subtotal: newSubtotal,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String id, int quantity) async {
    if (quantity <= 0) {
      await removeItem(id);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cart = await _service.updateQuantity(id, quantity);
    } catch (e) {
      final index = _cart.items.indexWhere((i) => i.id == id);
      if (index >= 0) {
        List<CartItem> newItems = List.from(_cart.items);
        newItems[index] = newItems[index].copyWith(quantity: quantity);
        final newCount = newItems.fold(0, (sum, item) => sum + item.quantity);
        final newSubtotal =
            newItems.fold(0.0, (sum, item) => sum + item.totalPrice);
        _cart = _cart.copyWith(
          items: newItems,
          itemCount: newCount,
          subtotal: newSubtotal,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeItem(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cart = await _service.removeItem(id);
    } catch (e) {
      List<CartItem> newItems = List.from(_cart.items);
      newItems.removeWhere((i) => i.id == id);
      final newCount = newItems.fold(0, (sum, item) => sum + item.quantity);
      final newSubtotal =
          newItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      _cart = _cart.copyWith(
        items: newItems,
        itemCount: newCount,
        subtotal: newSubtotal,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.clearCart();
    } catch (_) {
    } finally {
      _cart = CartModel.empty();
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isInCart(String productId) {
    return _cart.items.any((i) => i.productId == productId);
  }

  CartItem? getItemByProduct(String productId) {
    try {
      return _cart.items.firstWhere((i) => i.productId == productId);
    } catch (_) {
      return null;
    }
  }
}
