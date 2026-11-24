import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/review.dart';

class ReviewService {
  final ApiClient _apiClient;

  ReviewService(this._apiClient);

  Future<List<CustomerReview>> getReviews({int perPage = 12, String? orderId, String? status}) async {
    try {
      final response = await _apiClient.dio.get('/customer/reviews', queryParameters: {
        'per_page': perPage,
        if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
        if (status != null && status.isNotEmpty) 'status': status,
      });
      final List data = response.data['data'] as List? ?? [];
      return data.map((e) => CustomerReview.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<List<PendingReviewItem>> getPendingReviews({int perPage = 12, String? orderId}) async {
    try {
      final response = await _apiClient.dio.get('/customer/reviews/pending', queryParameters: {
        'per_page': perPage,
        if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
      });
      final List data = response.data['data'] as List? ?? [];
      return data.map((e) => PendingReviewItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<CustomerReview> submitReview({
    required String productUuid,
    required int rating,
    String? title,
    String? body,
    String? orderItemId,
    List<File>? photoFiles,
  }) async {
    try {
      dynamic payload;
      if (photoFiles != null && photoFiles.isNotEmpty) {
        final formData = FormData.fromMap({
          'rating': rating,
          if (title != null && title.isNotEmpty) 'title': title,
          if (body != null && body.isNotEmpty) 'body': body,
          if (orderItemId != null && orderItemId.isNotEmpty) 'order_item_id': orderItemId,
        });

        for (var file in photoFiles) {
          final filename = file.path.split('/').last;
          formData.files.add(MapEntry(
            'photos[]',
            await MultipartFile.fromFile(file.path, filename: filename),
          ));
        }
        payload = formData;
      } else {
        payload = {
          'rating': rating,
          if (title != null && title.isNotEmpty) 'title': title,
          if (body != null && body.isNotEmpty) 'body': body,
          if (orderItemId != null && orderItemId.isNotEmpty) 'order_item_id': orderItemId,
        };
      }

      final response = await _apiClient.dio.post(
        '/marketplace/products/$productUuid/reviews',
        data: payload,
      );

      final data = response.data['data'] ?? response.data;
      return CustomerReview.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
