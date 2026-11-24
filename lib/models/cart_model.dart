import 'cart_item.dart';

class CartModel {
  final String id;
  final String status;
  final int itemCount;
  final int lineCount;
  final double subtotal;
  final List<CartItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CartModel({
    required this.id,
    required this.status,
    required this.itemCount,
    required this.lineCount,
    required this.subtotal,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  factory CartModel.fromJson(Map<String, dynamic> data) {
    final parsedItems = (data['items'] as List<dynamic>?)
            ?.map((e) => e is Map<String, dynamic> ? CartItem.fromJson(e) : null)
            .whereType<CartItem>()
            .toList() ??
        [];

    final double parsedSubtotal =
        double.tryParse(data['subtotal']?.toString() ?? '') ??
            parsedItems.fold<double>(
                0.0, (double sum, CartItem item) => sum + item.totalPrice);

    final int parsedItemCount =
        int.tryParse(data['item_count']?.toString() ?? '') ??
            parsedItems.fold<int>(
                0, (int sum, CartItem item) => sum + item.quantity);

    final int parsedLineCount =
        int.tryParse(data['line_count']?.toString() ?? '') ??
            parsedItems.length;

    return CartModel(
      id: data['id']?.toString() ?? '',
      status: data['status']?.toString() ?? 'active',
      itemCount: parsedItemCount,
      lineCount: parsedLineCount,
      subtotal: parsedSubtotal,
      items: parsedItems,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }

  CartModel copyWith({
    List<CartItem>? items,
    int? itemCount,
    double? subtotal,
  }) {
    return CartModel(
      id: id,
      status: status,
      itemCount: itemCount ?? this.itemCount,
      lineCount: items?.length ?? lineCount,
      subtotal: subtotal ?? this.subtotal,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static CartModel empty() => const CartModel(
        id: '',
        status: 'active',
        itemCount: 0,
        lineCount: 0,
        subtotal: 0.0,
        items: [],
      );
}

typedef CartResponse = CartModel;
