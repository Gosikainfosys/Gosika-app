import 'package:flutter/material.dart';

/// Returns a payment method icon based on the method key ('esewa', 'khalti', 'cod').
Widget paymentMethodIcon(String method) {
  switch (method.toLowerCase()) {
    case 'esewa':
      return Image.asset(
        'assets/illustrations/esewa_icon.png',
        width: 40,
        height: 24,
        fit: BoxFit.contain,
      );
    case 'khalti':
      return Image.asset(
        'assets/illustrations/khalti_icon.png',
        width: 40,
        height: 24,
        fit: BoxFit.contain,
      );
    case 'cod':
    default:
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.money, size: 18, color: Colors.green),
          SizedBox(width: 4),
          Text('Cash on Delivery', style: TextStyle(fontSize: 12)),
        ],
      );
  }
}

/// Returns formatted display label for payment methods.
String getPaymentMethodLabel(String method) {
  switch (method.toLowerCase()) {
    case 'esewa':
      return 'eSewa';
    case 'khalti':
      return 'Khalti';
    case 'cod':
      return 'Cash on Delivery';
    default:
      return method;
  }
}

/// Returns color code for payment status values:
/// paid = green, pending = orange, failed/cancelled = red, refunded/partially_refunded = teal
Color getPaymentStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return Colors.green;
    case 'pending':
      return Colors.orange;
    case 'failed':
    case 'cancelled':
      return Colors.red;
    case 'refunded':
    case 'partially_refunded':
      return Colors.teal;
    default:
      return Colors.grey;
  }
}
