import '../core/api_client.dart';

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatar;
  final String status;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final List<String> roles;
  final String? gender;
  final String? dateOfBirth;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatar,
    required this.status,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    required this.roles,
    this.gender,
    this.dateOfBirth,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawFirst = json['first_name']?.toString() ?? '';
    final rawLast = json['last_name']?.toString() ?? '';
    final rawFull = json['full_name']?.toString() ?? json['name']?.toString() ?? '$rawFirst $rawLast'.trim();

    return User(
      id: json['id']?.toString() ?? json['uuid']?.toString() ?? '',
      firstName: rawFirst,
      lastName: rawLast,
      fullName: rawFull.isNotEmpty ? rawFull : 'User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
      status: json['status']?.toString() ?? 'active',
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'].toString())
          : null,
      phoneVerifiedAt: json['phone_verified_at'] != null
          ? DateTime.tryParse(json['phone_verified_at'].toString())
          : null,
      roles: json['roles'] != null
          ? List<String>.from(json['roles'])
          : ['customer'],
      gender: json['gender']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'status': status,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'roles': roles,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String? get avatarUrl {
    if (avatar == null || avatar!.isEmpty) return null;
    return ApiClient.apiImage(avatar);
  }

  String get initials {
    final name = (fullName.isNotEmpty ? fullName : email).trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  bool get isCustomer => roles.contains('customer');
  bool get isDeliveryPartner => roles.contains('delivery_partner');
}
