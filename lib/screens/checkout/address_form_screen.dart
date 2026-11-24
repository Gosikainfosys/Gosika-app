import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../widgets/custom_text_field.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  final CustomerAddress? address;
  const AddressFormScreen({super.key, this.address});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _postalCodeController;
  late TextEditingController _landmarkController;

  String _addressType = 'shipping';
  String? _selectedCountryId;
  String? _selectedProvinceId;
  String? _selectedDistrictId;
  String? _selectedMunicipalityId;
  bool _isDefault = false;
  bool _isSaving = false;

  List<LocationEntity> _countries = [];
  List<LocationEntity> _provinces = [];
  List<LocationEntity> _districts = [];
  List<LocationEntity> _municipalities = [];

  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    final addr = widget.address;
    _addressType = addr?.addressType ?? 'shipping';
    _labelController = TextEditingController(text: addr?.label ?? '');
    _nameController = TextEditingController(text: addr?.fullName ?? '');
    _phoneController = TextEditingController(text: addr?.phone ?? '');
    _address1Controller = TextEditingController(text: addr?.addressLine1 ?? '');
    _address2Controller = TextEditingController(text: addr?.addressLine2 ?? '');
    _postalCodeController = TextEditingController(text: addr?.postalCode ?? '');
    _landmarkController = TextEditingController(text: addr?.landmark ?? '');
    _selectedCountryId = addr?.countryId;
    _selectedProvinceId = addr?.provinceId;
    _selectedDistrictId = addr?.districtId;
    _selectedMunicipalityId = addr?.municipalityId;
    _isDefault = addr?.isDefault ?? false;

    _loadInitialLocations();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _postalCodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialLocations() async {
    setState(() => _isLoadingLocations = true);
    final service = ref.read(addressServiceProvider);

    final countries = await service.getCountries();
    final provinces = await service.getProvinces();

    List<LocationEntity> districts = [];
    if (_selectedProvinceId != null) {
      districts = await service.getDistricts(_selectedProvinceId);
    }

    List<LocationEntity> municipalities = [];
    if (_selectedDistrictId != null) {
      municipalities = await service.getMunicipalities(_selectedDistrictId);
    }

    if (mounted) {
      setState(() {
        _countries = countries;
        _provinces = provinces;
        _districts = districts;
        _municipalities = municipalities;
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _onProvinceChanged(String? provinceId) async {
    setState(() {
      _selectedProvinceId = provinceId;
      _selectedDistrictId = null;
      _selectedMunicipalityId = null;
      _districts = [];
      _municipalities = [];
    });

    if (provinceId != null) {
      final districts = await ref.read(addressServiceProvider).getDistricts(provinceId);
      if (mounted) {
        setState(() => _districts = districts);
      }
    }
  }

  Future<void> _onDistrictChanged(String? districtId) async {
    setState(() {
      _selectedDistrictId = districtId;
      _selectedMunicipalityId = null;
      _municipalities = [];
    });

    if (districtId != null) {
      final municipalities = await ref.read(addressServiceProvider).getMunicipalities(districtId);
      if (mounted) {
        setState(() => _municipalities = municipalities);
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = {
        'address_type': _addressType,
        'phone': _phoneController.text.trim(),
        'address_line_1': _address1Controller.text.trim(),
        if (_labelController.text.trim().isNotEmpty) 'label': _labelController.text.trim(),
        if (_nameController.text.trim().isNotEmpty) 'full_name': _nameController.text.trim(),
        if (_address2Controller.text.trim().isNotEmpty) 'address_line_2': _address2Controller.text.trim(),
        if (_selectedCountryId != null) 'country_id': _selectedCountryId,
        if (_selectedProvinceId != null) 'province_id': _selectedProvinceId,
        if (_selectedDistrictId != null) 'district_id': _selectedDistrictId,
        if (_selectedMunicipalityId != null) 'municipality_id': _selectedMunicipalityId,
        if (_postalCodeController.text.trim().isNotEmpty) 'postal_code': _postalCodeController.text.trim(),
        if (_landmarkController.text.trim().isNotEmpty) 'landmark': _landmarkController.text.trim(),
        'is_default': _isDefault,
      };

      if (widget.address != null) {
        await ref.read(addressListProvider.notifier).updateAddress(widget.address!.id, payload);
      } else {
        await ref.read(addressListProvider.notifier).addAddress(payload);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.address != null ? 'Edit Address' : 'Add New Address',
          style: const TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 18),
        ),
      ),
      body: _isLoadingLocations
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(kPad),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address Type Toggle
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Shipping'),
                          selected: _addressType == 'shipping',
                          selectedColor: AppColors.primaryOrange,
                          labelStyle: TextStyle(color: _addressType == 'shipping' ? Colors.white : kNavy),
                          onSelected: (val) => setState(() => _addressType = 'shipping'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Billing'),
                          selected: _addressType == 'billing',
                          selectedColor: AppColors.primaryOrange,
                          labelStyle: TextStyle(color: _addressType == 'billing' ? Colors.white : kNavy),
                          onSelected: (val) => setState(() => _addressType = 'billing'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _labelController,
                      label: 'Address Label (optional)',
                      hint: 'Home, Work, etc.',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Recipient Full Name (optional)',
                      hint: 'Full name',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: '98xxxxxxxx',
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Phone number is required';
                        if (v.trim().length > 20) return 'Max 20 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Province Dropdown
                    if (_provinces.isNotEmpty) ...[
                      const Text('Province', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedProvinceId,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          fillColor: Colors.grey[100],
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        hint: const Text('Select Province'),
                        items: _provinces.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                        onChanged: _onProvinceChanged,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // District Dropdown
                    if (_districts.isNotEmpty) ...[
                      const Text('District', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedDistrictId,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          fillColor: Colors.grey[100],
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        hint: const Text('Select District'),
                        items: _districts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                        onChanged: _onDistrictChanged,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Municipality Dropdown
                    if (_municipalities.isNotEmpty) ...[
                      const Text('Municipality', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedMunicipalityId,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          fillColor: Colors.grey[100],
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        hint: const Text('Select Municipality'),
                        items: _municipalities.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                        onChanged: (val) => setState(() => _selectedMunicipalityId = val),
                      ),
                      const SizedBox(height: 16),
                    ],

                    CustomTextField(
                      controller: _address1Controller,
                      label: 'Street Address Line 1',
                      hint: 'House No., Tole, Area Name',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Street address is required';
                        if (v.trim().length > 255) return 'Max 255 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _address2Controller,
                      label: 'Address Line 2 (optional)',
                      hint: 'Apartment, suite, unit',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _landmarkController,
                      label: 'Landmark (optional)',
                      hint: 'Near bank, school, park, etc.',
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Set as Default Address', style: TextStyle(fontWeight: FontWeight.w600, color: kNavy)),
                      value: _isDefault,
                      onChanged: (val) => setState(() => _isDefault = val),
                      activeColor: AppColors.primaryOrange,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving ? null : _handleSave,
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
