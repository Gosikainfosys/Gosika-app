import 'dart:convert';

class CartStore {
  final String id;
  final String name;

  const CartStore({required this.id, required this.name});

  factory CartStore.fromJson(Map<String, dynamic> json) {
    return CartStore(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class CartItem {
  final String id;
  final String productId;
  final String name;
  final String? sku;
  final String? variantId;
  final String? variantName;
  final Map<String, dynamic>? options;
  final String? image;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final String? stockStatus;
  final CartStore? store;
  final String? vendorName;
  final DateTime? createdAt;

  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    this.sku,
    this.variantId,
    this.variantName,
    this.options,
    this.image,
    required this.unitPrice,
    required this.quantity,
    double? totalPrice,
    this.stockStatus,
    this.store,
    this.vendorName,
    this.createdAt,
  }) : totalPrice = totalPrice ?? (unitPrice * quantity);

  String? get storeName => store?.name ?? vendorName;

  CartItem copyWith({
    int? quantity,
    double? totalPrice,
  }) {
    final qty = quantity ?? this.quantity;
    return CartItem(
      id: id,
      productId: productId,
      name: name,
      sku: sku,
      variantId: variantId,
      variantName: variantName,
      options: options,
      image: image,
      unitPrice: unitPrice,
      quantity: qty,
      totalPrice: totalPrice ?? (unitPrice * qty),
      stockStatus: stockStatus,
      store: store,
      vendorName: vendorName,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'name': name,
        'sku': sku,
        'variant_id': variantId,
        'variant_name': variantName,
        'options': options,
        'image': image,
        'unit_price': unitPrice,
        'quantity': quantity,
        'total_price': totalPrice,
        'stock_status': stockStatus,
        'store': store?.toJson(),
        'vendor_name': vendorName,
        'created_at': createdAt?.toIso8601String(),
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productMap = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : null;

    final parsedUnitPrice = double.tryParse(
            json['unit_price']?.toString() ??
                json['price']?.toString() ??
                productMap?['price']?.toString() ??
                '0') ??
        0.0;
    final parsedQty = int.tryParse(json['quantity']?.toString() ?? '1') ?? 1;
    final parsedTotalPrice =
        double.tryParse(json['total_price']?.toString() ?? '') ??
            (parsedUnitPrice * parsedQty);

    Map<String, dynamic>? parsedOptions;
    if (json['options'] != null) {
      if (json['options'] is Map) {
        parsedOptions = Map<String, dynamic>.from(json['options'] as Map);
      } else if (json['options'] is String) {
        try {
          final decoded = jsonDecode(json['options'] as String);
          if (decoded is Map) {
            parsedOptions = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
    }

    return CartItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ??
          productMap?['id']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ??
          productMap?['name']?.toString() ??
          productMap?['title']?.toString() ??
          'Unknown Product',
      sku: json['sku']?.toString() ?? productMap?['sku']?.toString(),
      variantId: json['variant_id']?.toString(),
      variantName: json['variant_name']?.toString(),
      options: parsedOptions,
      image: json['image']?.toString() ??
          productMap?['image']?.toString() ??
          productMap?['thumbnail']?.toString() ??
          (productMap?['images'] is List &&
                  (productMap!['images'] as List).isNotEmpty
              ? productMap['images'][0]?.toString()
              : null),
      unitPrice: parsedUnitPrice,
      quantity: parsedQty,
      totalPrice: parsedTotalPrice,
      stockStatus: json['stock_status']?.toString(),
      store: json['store'] != null && json['store'] is Map
          ? CartStore.fromJson(json['store'] as Map<String, dynamic>)
          : null,
      vendorName: json['vendor_name']?.toString() ??
          (json['store'] is Map ? json['store']['name']?.toString() : null),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
