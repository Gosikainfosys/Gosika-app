import '../core/api_client.dart';

class ReturnRequest {
  final String id;
  final String returnNumber;
  final String requestType;
  final String? requestTypeLabel;
  final String? reasonType;
  final String reason;
  final int quantity;
  final double refundAmount;
  final String preferredResolution;
  final String status;
  final String? statusLabel;
  final String? response;
  final DateTime? windowExpiresAt;
  final String? productName;
  final String? productImage;
  final String orderId;
  final String orderNumber;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  ReturnRequest({
    required this.id,
    required this.returnNumber,
    required this.requestType,
    this.requestTypeLabel,
    this.reasonType,
    required this.reason,
    required this.quantity,
    required this.refundAmount,
    required this.preferredResolution,
    required this.status,
    this.statusLabel,
    this.response,
    this.windowExpiresAt,
    this.productName,
    this.productImage,
    required this.orderId,
    required this.orderNumber,
    this.createdAt,
    this.reviewedAt,
  });

  String get formattedRequestTypeLabel {
    if (requestTypeLabel != null && requestTypeLabel!.isNotEmpty) {
      return requestTypeLabel!;
    }
    switch (requestType.toLowerCase()) {
      case 'return_refund':
      case 'return':
        return 'Return & Refund';
      case 'exchange':
        return 'Exchange';
      case 'replacement':
        return 'Replacement';
      default:
        return requestType.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get formattedStatusLabel {
    if (statusLabel != null && statusLabel!.isNotEmpty) {
      return statusLabel!;
    }
    switch (status.toLowerCase()) {
      case 'requested':
        return 'Requested';
      case 'under_review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'pickup_arranged':
        return 'Pickup Arranged';
      case 'collected':
        return 'Collected';
      case 'inspected':
        return 'Inspected';
      case 'refund_pending':
        return 'Refund Pending';
      case 'refunded':
        return 'Refunded';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    final rawImg = json['product_image']?.toString();

    return ReturnRequest(
      id: json['id']?.toString() ?? '',
      returnNumber: json['return_number']?.toString() ?? json['id']?.toString() ?? '',
      requestType: json['request_type']?.toString() ?? 'return',
      requestTypeLabel: json['request_type_label']?.toString(),
      reasonType: json['reason_type']?.toString(),
      reason: json['reason']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      refundAmount: double.tryParse(json['refund_amount']?.toString() ?? '0') ?? 0.0,
      preferredResolution: json['preferred_resolution']?.toString() ?? 'refund',
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['status_label']?.toString(),
      response: json['response']?.toString(),
      windowExpiresAt: json['window_expires_at'] != null
          ? DateTime.tryParse(json['window_expires_at'].toString())
          : null,
      productName: json['product_name']?.toString() ?? 'Item',
      productImage: rawImg != null ? ApiClient.apiImage(rawImg) : null,
      orderId: json['order_id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
    );
  }
}
