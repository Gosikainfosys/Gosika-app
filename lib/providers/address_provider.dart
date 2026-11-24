import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../models/address.dart';
import '../services/address_service.dart';

final addressServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AddressService(apiClient);
});

final addressListProvider = StateNotifierProvider<AddressListNotifier, AsyncValue<List<CustomerAddress>>>((ref) {
  final service = ref.watch(addressServiceProvider);
  return AddressListNotifier(service, ref);
});

class AddressListNotifier extends StateNotifier<AsyncValue<List<CustomerAddress>>> {
  final AddressService _service;
  final Ref _ref;

  AddressListNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    fetchAddresses();

    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated && next.isAuthenticated) {
        fetchAddresses();
      }
    });
  }

  Future<void> fetchAddresses() async {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final addresses = await _service.getAddresses();
      state = AsyncValue.data(addresses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAddress(Map<String, dynamic> data) async {
    try {
      await _service.createAddress(data);
      await fetchAddresses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateAddress(id, data);
      await fetchAddresses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _service.deleteAddress(id);
      await fetchAddresses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String id) async {
    try {
      await _service.setDefaultAddress(id);
      await fetchAddresses();
    } catch (e) {
      rethrow;
    }
  }
}
