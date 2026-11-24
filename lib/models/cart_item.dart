class CartItem {
  final String id;
  final String productId;
  final String name;
  final String? image;
  final double unitPrice;
  final int quantity;
  final String? variantName;

  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    this.image,
    required this.unitPrice,
    required this.quantity,
    this.variantName,
  });

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      productId: productId,
      name: name,
      image: image,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      variantName: variantName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'name': name,
    'image': image,
    'unit_price': unitPrice,
    'quantity': quantity,
    'variant_name': variantName,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      variantName: json['variant_name'],
    );
  }
}
