import 'cart_item.dart';

class CartModel {
  final String id;
  final String status;
  final int itemCount;
  final int lineCount;
  final double subtotal;
  final List<CartItem> items;

  const CartModel({
    required this.id,
    required this.status,
    required this.itemCount,
    required this.lineCount,
    required this.subtotal,
    required this.items,
  });

  // Parse from GET /cart → response['data']
  factory CartModel.fromJson(Map<String, dynamic> data) {
    return CartModel(
      id: data['id'] as String,
      status: data['status'] as String,
      itemCount: (data['item_count'] as num).toInt(),
      lineCount: (data['line_count'] as num).toInt(),
      subtotal: double.tryParse(data['subtotal']?.toString() ?? '0') ?? 0.0,
      items: (data['items'] as List<dynamic>)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  CartModel copyWith({List<CartItem>? items, int? itemCount, double? subtotal}) {
    return CartModel(
      id: id, status: status,
      itemCount: itemCount ?? this.itemCount,
      lineCount: items?.length ?? lineCount,
      subtotal: subtotal ?? this.subtotal,
      items: items ?? this.items,
    );
  }

  static CartModel empty() => const CartModel(
    id: '', status: 'active', itemCount: 0, lineCount: 0, subtotal: 0.0, items: [],
  );
}
