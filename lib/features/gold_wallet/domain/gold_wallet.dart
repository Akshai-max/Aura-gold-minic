class GoldWallet {
  const GoldWallet({
    required this.walletId,
    required this.userId,
    required this.goldBalance,
    required this.availableGold,
    required this.lockedGold,
    required this.pendingGold,
    required this.totalInvested,
    required this.currentValue,
    required this.profitLoss,
    required this.createdAt,
    required this.updatedAt,
    this.isOffline = false,
  });

  final String walletId;
  final String userId;
  final double goldBalance;
  final double availableGold;
  final double lockedGold;
  final double pendingGold;
  final double totalInvested;
  final double currentValue;
  final double profitLoss;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOffline;

  factory GoldWallet.fromJson(Map<String, dynamic> json) {
    return GoldWallet(
      walletId: json['wallet_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      goldBalance: _double(json['gold_balance']),
      availableGold: _double(json['available_gold']),
      lockedGold: _double(json['locked_gold']),
      pendingGold: _double(json['pending_gold']),
      totalInvested: _double(json['total_invested']),
      currentValue: _double(json['current_value']),
      profitLoss: _double(json['profitLoss'] ?? json['profit_loss']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      isOffline: json['is_offline'] as bool? ?? false,
    );
  }
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
