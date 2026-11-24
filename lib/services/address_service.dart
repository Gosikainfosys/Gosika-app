import '../core/api_client.dart';
import '../models/address.dart';

class AddressService {
  final ApiClient _apiClient;

  AddressService(this._apiClient);

  Future<List<CustomerAddress>> getAddresses() async {
    try {
      final response = await _apiClient.dio.get('/customer/addresses');
      final List data = response.data['data'] as List? ?? [];
      return data.map((e) => CustomerAddress.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<CustomerAddress> createAddress(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/customer/addresses', data: payload);
      final data = response.data['data'] ?? response.data;
      return CustomerAddress.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<CustomerAddress> updateAddress(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.put('/customer/addresses/$id', data: payload);
      final data = response.data['data'] ?? response.data;
      return CustomerAddress.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _apiClient.dio.delete('/customer/addresses/$id');
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<CustomerAddress> setDefaultAddress(String id) async {
    try {
      final response = await _apiClient.dio.put('/customer/addresses/$id/default');
      final data = response.data['data']?['address'] ?? response.data['data'] ?? response.data;
      return CustomerAddress.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // Location Dropdowns
  Future<List<LocationEntity>> getCountries() async {
    try {
      final response = await _apiClient.dio.get('/platform/countries');
      final List data = response.data['data'] as List? ?? [];
      return data.map((e) => LocationEntity.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<LocationEntity>> getProvinces() async {
    try {
      final response = await _apiClient.dio.get('/platform/provinces');
      final List data = response.data['data'] as List? ?? [];
      return data.map((e) => LocationEntity.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<LocationEntity>> getDistricts([String? provinceId]) async {
    try {
      final response = await _apiClient.dio.get('/platform/districts', queryParameters: {
        if (provinceId != null) 'province_id': provinceId,
      });
      final List data = response.data['data'] as List? ?? [];
      return data.map((e) => LocationEntity.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<LocationEntity>> getMunicipalities([String? districtId]) async {
    try {
      final response = await _apiClient.dio.get('/platform/municipalities', queryParameters: {
        if (districtId != null) 'district_id': districtId,
      });
      final List data = response.data['data'] as List? ?? [];
      return data.map((e) => LocationEntity.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}
