import '../core/api_client.dart';

class Order {
  final String id;
  final String orderNumber;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final double tax;
  final double grandTotal;
  final double refundedAmount;
  final double netTotal;
  final String currency;
  final Map<String, dynamic>? shippingAddress;
  final List<OrderItem> items;
  final List<VendorOrder> vendorOrders;
  final String? customerNotes;
  final DateTime? placedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelledReason;
  final bool canCancel;
  final int cancellationWindowMinutes;
  final DateTime? cancellationDeadline;
  final int cancellationSecondsRemaining;
  final String? cancellationBlockedReason;
  final List<String> allowedCancellationReasons;
  final bool canRequestReturn;
  final DateTime? returnWindowExpiresAt;
  final String? deliveryOtp;
  final bool hasDeliveryOtp;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.discount,
    required this.deliveryCharge,
    required this.tax,
    required this.grandTotal,
    this.refundedAmount = 0.0,
    required this.netTotal,
    this.currency = 'NPR',
    this.shippingAddress,
    required this.items,
    this.vendorOrders = const [],
    this.customerNotes,
    this.placedAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelledReason,
    this.canCancel = false,
    this.cancellationWindowMinutes = 0,
    this.cancellationDeadline,
    this.cancellationSecondsRemaining = 0,
    this.cancellationBlockedReason,
    this.allowedCancellationReasons = const [],
    this.canRequestReturn = false,
    this.returnWindowExpiresAt,
    this.deliveryOtp,
    this.hasDeliveryOtp = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Items can come directly from json['items'] or flattened from json['vendor_orders']
    List rawItems = json['items'] as List? ?? [];
    if (rawItems.isEmpty && json['vendor_orders'] is List) {
      for (var vo in json['vendor_orders']) {
        if (vo['items'] is List) {
          rawItems.addAll(vo['items']);
        }
      }
    }

    final List<OrderItem> parsedItems = rawItems
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final List<VendorOrder> parsedVendorOrders = (json['vendor_orders'] as List? ?? [])
        .map((e) => VendorOrder.fromJson(e as Map<String, dynamic>))
        .toList();

    final subtotalVal = double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0;
    final grandTotalVal = double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0.0;
    final netTotalVal = double.tryParse(json['net_total']?.toString() ?? grandTotalVal.toString()) ?? grandTotalVal;

    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      paymentMethod: json['payment_method']?.toString() ?? 'cod',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      subtotal: subtotalVal,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      deliveryCharge: double.tryParse(json['delivery_charge']?.toString() ?? '0') ?? 0.0,
      tax: double.tryParse(json['tax']?.toString() ?? '0') ?? 0.0,
      grandTotal: grandTotalVal,
      refundedAmount: double.tryParse(json['refunded_amount']?.toString() ?? '0') ?? 0.0,
      netTotal: netTotalVal,
      currency: json['currency']?.toString() ?? 'NPR',
      shippingAddress: json['shipping_address'] as Map<String, dynamic>? ?? json['shipping_address_snapshot'] as Map<String, dynamic>?,
      items: parsedItems,
      vendorOrders: parsedVendorOrders,
      customerNotes: json['customer_notes']?.toString(),
      placedAt: json['placed_at'] != null
          ? DateTime.tryParse(json['placed_at'].toString())
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null),
      confirmedAt: json['confirmed_at'] != null ? DateTime.tryParse(json['confirmed_at'].toString()) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.tryParse(json['cancelled_at'].toString()) : null,
      cancelledReason: json['cancelled_reason']?.toString(),
      canCancel: json['can_cancel'] == true || json['can_cancel'] == 1,
      cancellationWindowMinutes: (json['cancellation_window_minutes'] as num?)?.toInt() ?? 0,
      cancellationDeadline: json['cancellation_deadline'] != null
          ? DateTime.tryParse(json['cancellation_deadline'].toString())
          : null,
      cancellationSecondsRemaining: (json['cancellation_seconds_remaining'] as num?)?.toInt() ?? 0,
      cancellationBlockedReason: json['cancellation_blocked_reason']?.toString(),
      allowedCancellationReasons: json['allowed_cancellation_reasons'] != null
          ? List<String>.from(json['allowed_cancellation_reasons'])
          : ['Mind changed', 'Ordered by mistake', 'Found better price elsewhere', 'Delayed delivery', 'Other'],
      canRequestReturn: json['can_request_return'] == true || json['can_request_return'] == 1,
      returnWindowExpiresAt: json['return_window_expires_at'] != null
          ? DateTime.tryParse(json['return_window_expires_at'].toString())
          : null,
      deliveryOtp: json['delivery_otp']?.toString(),
      hasDeliveryOtp: json['has_delivery_otp'] == true || json['has_delivery_otp'] == 1,
    );
  }
}

class VendorOrder {
  final String id;
  final String vendorOrderNumber;
  final String status;
  final String deliveryStatus;
  final double grandTotal;
  final List<OrderItem> items;

  VendorOrder({
    required this.id,
    required this.vendorOrderNumber,
    required this.status,
    required this.deliveryStatus,
    required this.grandTotal,
    required this.items,
  });

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    return VendorOrder(
      id: json['id']?.toString() ?? '',
      vendorOrderNumber: json['vendor_order_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      deliveryStatus: json['delivery_status']?.toString() ?? 'pending',
      grandTotal: double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0.0,
      items: (json['items'] as List?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String? variantId;
  final String productName;
  final String? sku;
  final String? variantName;
  final String? image;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String deliveryStatus;
  final bool canRequestReturn;

  OrderItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productName,
    this.sku,
    this.variantName,
    this.image,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.deliveryStatus,
    this.canRequestReturn = false,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final rawImg = json['image']?.toString();

    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      productName: json['product_name']?.toString() ?? 'Product',
      sku: json['sku']?.toString(),
      variantName: json['variant_name']?.toString(),
      image: rawImg != null ? ApiClient.apiImage(rawImg) : null,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      lineTotal: double.tryParse(json['line_total']?.toString() ?? '0') ?? 0.0,
      deliveryStatus: json['delivery_status']?.toString() ?? 'pending',
      canRequestReturn: json['can_request_return'] == true || json['can_request_return'] == 1,
    );
  }
}

class OrderTracking {
  final String status;
  final String note;
  final double? latitude;
  final double? longitude;
  final DateTime trackedAt;

  OrderTracking({
    required this.status,
    required this.note,
    this.latitude,
    this.longitude,
    required this.trackedAt,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    return OrderTracking(
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      trackedAt: json['tracked_at'] != null
          ? DateTime.tryParse(json['tracked_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class CheckoutSummary {
  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final double tax;
  final double grandTotal;
  final List<String> availablePaymentMethods;

  CheckoutSummary({
    required this.subtotal,
    required this.discount,
    required this.deliveryCharge,
    required this.tax,
    required this.grandTotal,
    required this.availablePaymentMethods,
  });

  factory CheckoutSummary.fromJson(Map<String, dynamic> json) {
    return CheckoutSummary(
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      deliveryCharge: double.tryParse(json['delivery_charge']?.toString() ?? '0') ?? 0.0,
      tax: double.tryParse(json['tax']?.toString() ?? '0') ?? 0.0,
      grandTotal: double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0.0,
      availablePaymentMethods: List<String>.from(json['available_payment_methods'] ?? []),
    );
  }
}
