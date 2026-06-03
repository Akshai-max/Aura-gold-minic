class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.role,
    required this.isActive,
    required this.emailVerified,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String role;
  final bool isActive;
  final bool emailVerified;

  String get fullName => '$firstName $lastName';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String,
      mobileNumber: json['mobile_number'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
      isActive: json['is_active'] as bool? ?? true,
      emailVerified: json['email_verified'] as bool? ?? false,
    );
  }
}
