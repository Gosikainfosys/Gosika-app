import '../core/api_client.dart';
import '../models/order.dart';

class CheckoutService {
  final ApiClient _apiClient;

  CheckoutService(this._apiClient);

  Future<CheckoutSummary> getSummary(List<String> itemIds) async {
    final response = await _apiClient.dio.get('/checkout/summary', queryParameters: {
      'items[]': itemIds,
    });
    return CheckoutSummary.fromJson(response.data['data']);
  }

  Future<String> createSession({
    required String addressId,
    required List<String> itemIds,
    String? couponCode,
  }) async {
    final response = await _apiClient.dio.post('/checkout', data: {
      'address_id': addressId,
      'item_ids': itemIds,
      'coupon_code': couponCode,
    });
    return response.data['data']['id'];
  }

  Future<({String id, String orderNumber})> placeOrder({
    required String checkoutSessionId,
    required String paymentMethod,
    String? customerNotes,
  }) async {
    final response = await _apiClient.dio.post('/orders', data: {
      'checkout_session_id': checkoutSessionId,
      'payment_method': paymentMethod,
      'customer_notes': customerNotes,
    });
    final data = response.data['data'];
    return (id: data['id'] as String, orderNumber: data['order_number'] as String);
  }

  Future<({String orderId, String? orderNumber, String? paymentUrl})> initiateCheckout({
    required List<String> cartItemIds,
    required String shippingAddressId,
    required String billingAddressId,
    required String paymentMethod,
    String? deliveryInstructions,
  }) async {
    try {
      final response = await _apiClient.dio.post('/checkout/initiate', data: {
        'items': cartItemIds.map((id) => {'cart_item_id': id}).toList(),
        'shipping_address_id': shippingAddressId,
        'billing_address_id': billingAddressId,
        'payment_method': paymentMethod,
        'delivery_instructions': deliveryInstructions ?? '',
      });
      final data = response.data['data'] ?? response.data;
      return (
        orderId: (data['order_id'] ?? data['id'] ?? '').toString(),
        orderNumber: (data['order_number'] ?? data['order_no'])?.toString(),
        paymentUrl: data['payment_url']?.toString(),
      );
    } catch (_) {
      final sessionId = await createSession(addressId: shippingAddressId, itemIds: cartItemIds);
      final res = await placeOrder(checkoutSessionId: sessionId, paymentMethod: paymentMethod, customerNotes: deliveryInstructions);
      return (
        orderId: res.id,
        orderNumber: res.orderNumber,
        paymentUrl: null,
      );
    }
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String orderId,
    required String paymentMethod,
  }) async {
    final response = await _apiClient.dio.post('/payments/initiate', data: {
      'order_id': orderId,
      'payment_method': paymentMethod,
      'success_url': 'https://gosika.sital.info.np/payments/callback/success',
      'failure_url': 'https://gosika.sital.info.np/payments/callback/failure',
    });
    return response.data['data'];
  }

  Future<void> verifyEsewa(String data) async {
    await _apiClient.dio.post('/payments/esewa/callback', data: {'data': data});
  }
}
