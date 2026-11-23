class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String status;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final List<String> roles;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.status,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';
    final nameParts = rawName.trim().split(' ');
    final defaultFirst = nameParts.isNotEmpty ? nameParts.first : 'User';
    final defaultLast = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return User(
      id: json['id']?.toString() ?? json['uuid']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? defaultFirst,
      lastName: json['last_name']?.toString() ?? defaultLast,
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'status': status,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'roles': roles,
    };
  }

  String get fullName => '$firstName $lastName';
  bool get isCustomer => roles.contains('customer');
  bool get isDeliveryPartner => roles.contains('delivery_partner');
}
