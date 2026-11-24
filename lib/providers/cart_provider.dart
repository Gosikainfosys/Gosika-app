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
      final newCount = newItems.fold<int>(0, (sum, item) => sum + item.quantity);
      final newSubtotal =
          newItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
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

    final index = _cart.items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final oldItem = _cart.items[index];
      List<CartItem> newItems = List.from(_cart.items);
      newItems[index] = oldItem.copyWith(quantity: quantity);
      final newCount = newItems.fold<int>(0, (sum, item) => sum + item.quantity);
      final newSubtotal =
          newItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
      _cart = _cart.copyWith(
        items: newItems,
        itemCount: newCount,
        subtotal: newSubtotal,
      );
      notifyListeners();

      try {
        _cart = await _service.updateQuantity(id, quantity);
        notifyListeners();
      } catch (e) {
        // Revert on error
        List<CartItem> revertedItems = List.from(_cart.items);
        final revIndex = revertedItems.indexWhere((i) => i.id == id);
        if (revIndex >= 0) {
          revertedItems[revIndex] = oldItem;
          final revCount =
              revertedItems.fold<int>(0, (sum, item) => sum + item.quantity);
          final revSubtotal = revertedItems.fold<double>(
              0.0, (sum, item) => sum + item.totalPrice);
          _cart = _cart.copyWith(
            items: revertedItems,
            itemCount: revCount,
            subtotal: revSubtotal,
          );
          notifyListeners();
        }
      }
    }
  }

  Future<void> removeItem(String id) async {
    // 1. Optimistically remove item from local cart state IMMEDIATELY
    final index = _cart.items.indexWhere((i) => i.id == id);
    if (index < 0) return;

    final removedItem = _cart.items[index];
    final newItems = List<CartItem>.from(_cart.items)..removeAt(index);
    final newCount = newItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final newSubtotal =
        newItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice);

    _cart = _cart.copyWith(
      items: newItems,
      itemCount: newCount,
      subtotal: newSubtotal,
    );
    _isLoading = false;
    _error = null;
    notifyListeners(); // Synchronously notifies listeners so onDismissed frame has updated list!

    // 2. Perform API call in background, revert if network fails
    try {
      final updatedCart = await _service.removeItem(id);
      _cart = updatedCart;
      notifyListeners();
    } catch (e) {
      // Revert local removal on failure
      final revertedItems = List<CartItem>.from(_cart.items)
        ..insert(index, removedItem);
      final revertedCount =
          revertedItems.fold<int>(0, (sum, item) => sum + item.quantity);
      final revertedSubtotal = revertedItems.fold<double>(
          0.0, (sum, item) => sum + item.totalPrice);
      _cart = _cart.copyWith(
        items: revertedItems,
        itemCount: revertedCount,
        subtotal: revertedSubtotal,
      );
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    final oldCart = _cart;
    _cart = CartModel.empty();
    _isLoading = false;
    _error = null;
    notifyListeners();

    try {
      await _service.clearCart();
    } catch (e) {
      _cart = oldCart;
      _error = e.toString().replaceAll('Exception: ', '');
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
