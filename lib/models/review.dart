import '../core/api_client.dart';

class CustomerReview {
  final String id;
  final int rating;
  final String? title;
  final String? body;
  final List<String> photos;
  final String status;
  final String? reply;
  final String? orderItemId;
  final String productId;
  final String productName;
  final String? image;
  final DateTime? createdAt;

  CustomerReview({
    required this.id,
    required this.rating,
    this.title,
    this.body,
    this.photos = const [],
    required this.status,
    this.reply,
    this.orderItemId,
    required this.productId,
    required this.productName,
    this.image,
    this.createdAt,
  });

  factory CustomerReview.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] as List? ?? [];
    final rawImg = json['image']?.toString();

    return CustomerReview(
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      photos: rawPhotos.map((e) => ApiClient.apiImage(e.toString())).toList(),
      status: json['status']?.toString() ?? 'pending',
      reply: json['reply']?.toString(),
      orderItemId: json['order_item_id']?.toString(),
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? 'Product',
      image: rawImg != null ? ApiClient.apiImage(rawImg) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class PendingReviewItem {
  final String id; // order_item_id
  final String productId;
  final String productName;
  final String? image;
  final int quantity;
  final double unitPrice;
  final String deliveryStatus;
  final String orderId;
  final String orderNumber;
  final DateTime? placedAt;

  PendingReviewItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.image,
    required this.quantity,
    required this.unitPrice,
    required this.deliveryStatus,
    required this.orderId,
    required this.orderNumber,
    this.placedAt,
  });

  factory PendingReviewItem.fromJson(Map<String, dynamic> json) {
    final rawImg = json['image']?.toString();

    return PendingReviewItem(
      id: json['id']?.toString() ?? json['order_item_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? 'Product',
      image: rawImg != null ? ApiClient.apiImage(rawImg) : null,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      deliveryStatus: json['delivery_status']?.toString() ?? 'delivered',
      orderId: json['order_id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      placedAt: json['placed_at'] != null ? DateTime.tryParse(json['placed_at'].toString()) : null,
    );
  }
}
