class GoldTreasury {
  const GoldTreasury({
    required this.availableGold,
    required this.totalSupplied,
    required this.updatedAt,
  });

  final double availableGold;
  final double totalSupplied;
  final DateTime updatedAt;

  factory GoldTreasury.fromJson(Map<String, dynamic> json) {
    return GoldTreasury(
      availableGold: _double(json['available_gold']),
      totalSupplied: _double(json['total_supplied']),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'available_gold': availableGold,
      };

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }
}
