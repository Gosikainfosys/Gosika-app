import '../core/api_client.dart';
import '../models/product.dart';
import '../models/deal_product.dart';
import '../models/campaign.dart';
import '../models/product_filters.dart';

class CatalogService {
  final ApiClient _apiClient;

  CatalogService(this._apiClient);

  Future<List<Banner>> getBanners() async {
    try {
      final response = await _apiClient.dio.get('/banners');
      final dynamic resData = response.data;
      List rawList = [];
      if (resData is Map && resData.containsKey('data') && resData['data'] is List) {
        rawList = resData['data'];
      } else if (resData is List) {
        rawList = resData;
      }
      return rawList.map((e) => Banner.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Category>> getCategories() async {
    final response = await _apiClient.dio.get('/categories');
    final List data = response.data['data'];
    return data.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<String>> getSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _apiClient.dio.get('/products/suggestions', queryParameters: {'q': query});
      final List data = response.data['data'] ?? [];
      return data.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> getBrands() async {
    try {
      final response = await _apiClient.dio.get('/brands');
      final List data = response.data['data'] ?? [];
      return data.map((e) => {
        'id': e['id'].toString(),
        'name': e['name'].toString(),
        'slug': (e['slug'] ?? e['name']).toString(),
      }).toList();
    } catch (_) {
      return [
        {'id': 'brand_gosika', 'name': 'Gosika Select', 'slug': 'gosika-select'},
        {'id': 'brand_himalaya', 'name': 'Himalayan Crafts', 'slug': 'himalayan-crafts'},
        {'id': 'brand_nepal', 'name': 'Made in Nepal', 'slug': 'made-in-nepal'},
      ];
    }
  }

  Future<List<DealProduct>> getDeals() async {
    final response = await _apiClient.dio.get('/deals', queryParameters: {'per_page': 12});
    final List data = response.data['data'];
    return data.map((e) => DealProduct.fromJson(e)).toList();
  }

  Future<List<Campaign>> getCampaigns() async {
    final response = await _apiClient.dio.get('/campaigns');
    final List data = response.data['data'];
    return data.map((e) => Campaign.fromJson(e)).toList();
  }

  Future<PaginatedResponse<Product>> getProducts({
    int page = 1,
    int perPage = 20,
    String? search,
    String? categoryId,
    String? brandId,
    bool? isFeatured,
    String? sort,
    ProductFilters? filters,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'per_page': perPage,
    };

    if (filters != null) {
      queryParams.addAll(filters.toMap());
    } else {
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null && categoryId.isNotEmpty) queryParams['category_id'] = categoryId;
      if (brandId != null && brandId.isNotEmpty) queryParams['brand_id'] = brandId;
      if (isFeatured != null) queryParams['is_featured'] = isFeatured ? 1 : 0;
      if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;
    }

    final response = await _apiClient.dio.get('/products', queryParameters: queryParams);

    final List data = response.data['data'] ?? [];
    final meta = PaginationMeta.fromJson(response.data['meta'] ?? {});

    return PaginatedResponse(
      data: data.map((e) => Product.fromJson(e)).toList(),
      meta: meta,
    );
  }

  Future<Product> getProductDetail(String uuid) async {
    try {
      final response = await _apiClient.dio.get('/products/$uuid');
      final dynamic resData = response.data;
      Map<String, dynamic> jsonMap;
      if (resData is Map) {
        if (resData.containsKey('data') && resData['data'] is Map) {
          jsonMap = Map<String, dynamic>.from(resData['data']);
        } else {
          jsonMap = Map<String, dynamic>.from(resData);
        }
      } else {
        throw Exception('Invalid product response format');
      }
      return Product.fromJson(jsonMap);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
