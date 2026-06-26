class SellGoldInquiry {
  final String id;
  final String name;
  final String mobileNumber;
  final String message;
  final String status;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const SellGoldInquiry({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.message,
    required this.status,
    this.adminResponse,
    required this.createdAt,
    this.respondedAt,
  });

  factory SellGoldInquiry.fromJson(Map<String, dynamic> json) {
    return SellGoldInquiry(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      mobileNumber: json['mobile_number'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      adminResponse: json['admin_response'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }
}

class AdminSellGoldInquiry extends SellGoldInquiry {
  final String userId;
  final String? userEmail;

  const AdminSellGoldInquiry({
    required super.id,
    required this.userId,
    required super.name,
    required super.mobileNumber,
    required super.message,
    required super.status,
    super.adminResponse,
    required super.createdAt,
    super.respondedAt,
    this.userEmail,
  });

  factory AdminSellGoldInquiry.fromJson(Map<String, dynamic> json) {
    return AdminSellGoldInquiry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? '',
      mobileNumber: json['mobile_number'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      adminResponse: json['admin_response'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      userEmail: json['user_email'] as String?,
    );
  }
}
