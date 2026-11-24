class LocationEntity {
  final String id;
  final String name;

  LocationEntity({required this.id, required this.name});

  factory LocationEntity.fromJson(Map<String, dynamic> json) {
    return LocationEntity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
    );
  }
}

class CustomerAddress {
  final String id;
  final String addressType;
  final String? label;
  final String? fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final LocationEntity? country;
  final LocationEntity? province;
  final LocationEntity? district;
  final LocationEntity? municipality;
  final String? countryId;
  final String? provinceId;
  final String? districtId;
  final String? municipalityId;
  final String? postalCode;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerAddress({
    required this.id,
    this.addressType = 'shipping',
    this.label,
    this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    this.country,
    this.province,
    this.district,
    this.municipality,
    this.countryId,
    this.provinceId,
    this.districtId,
    this.municipalityId,
    this.postalCode,
    this.landmark,
    this.latitude,
    this.longitude,
    required this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    final countryObj = json['country'] is Map<String, dynamic> ? LocationEntity.fromJson(json['country']) : null;
    final provinceObj = json['province'] is Map<String, dynamic> ? LocationEntity.fromJson(json['province']) : null;
    final districtObj = json['district'] is Map<String, dynamic> ? LocationEntity.fromJson(json['district']) : null;
    final municipalityObj = json['municipality'] is Map<String, dynamic> ? LocationEntity.fromJson(json['municipality']) : null;

    return CustomerAddress(
      id: json['id']?.toString() ?? '',
      addressType: json['address_type']?.toString() ?? 'shipping',
      label: json['label']?.toString(),
      fullName: json['full_name']?.toString(),
      phone: json['phone']?.toString() ?? '',
      addressLine1: json['address_line_1']?.toString() ?? '',
      addressLine2: json['address_line_2']?.toString(),
      country: countryObj,
      province: provinceObj,
      district: districtObj,
      municipality: municipalityObj,
      countryId: json['country_id']?.toString() ?? countryObj?.id,
      provinceId: json['province_id']?.toString() ?? provinceObj?.id,
      districtId: json['district_id']?.toString() ?? districtObj?.id,
      municipalityId: json['municipality_id']?.toString() ?? municipalityObj?.id,
      postalCode: json['postal_code']?.toString(),
      landmark: json['landmark']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address_type': addressType,
      'phone': phone,
      'address_line_1': addressLine1,
      if (label != null && label!.isNotEmpty) 'label': label,
      if (fullName != null && fullName!.isNotEmpty) 'full_name': fullName,
      if (addressLine2 != null && addressLine2!.isNotEmpty) 'address_line_2': addressLine2,
      if (countryId != null && countryId!.isNotEmpty) 'country_id': countryId,
      if (provinceId != null && provinceId!.isNotEmpty) 'province_id': provinceId,
      if (districtId != null && districtId!.isNotEmpty) 'district_id': districtId,
      if (municipalityId != null && municipalityId!.isNotEmpty) 'municipality_id': municipalityId,
      if (postalCode != null && postalCode!.isNotEmpty) 'postal_code': postalCode,
      if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_default': isDefault,
    };
  }

  String get fullDisplayAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      if (municipality != null) municipality!.name,
      if (district != null) district!.name,
      if (province != null) province!.name,
    ].where((p) => p != null && p.isNotEmpty).join(', ');
    return parts.isNotEmpty ? parts : addressLine1;
  }
}
