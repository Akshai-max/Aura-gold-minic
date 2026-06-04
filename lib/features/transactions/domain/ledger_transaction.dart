enum TransactionType {
  buy,
  sell,
  sip,
  stake,
  unstake,
  reward,
  redeem;

  String get apiValue => name.toUpperCase();
}

class LedgerTransaction {
  const LedgerTransaction({
    required this.transactionId,
    required this.userId,
    required this.transactionType,
    required this.goldAmount,
    required this.goldPrice,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String transactionId;
  final String userId;
  final TransactionType transactionType;
  final double goldAmount;
  final double goldPrice;
  final double amount;
  final String status;
  final DateTime createdAt;

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) {
    return LedgerTransaction(
      transactionId:
          json['transaction_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      transactionType: _type(json['transaction_type']?.toString()),
      goldAmount: _double(json['gold_amount']),
      goldPrice: _double(json['gold_price']),
      amount: _double(json['amount']),
      status: json['status'] as String? ?? 'PENDING',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class TransactionFilter {
  const TransactionFilter({this.date, this.type, this.status});

  final DateTime? date;
  final TransactionType? type;
  final String? status;

  Map<String, dynamic> toQuery() {
    return {
      if (date != null) 'date': date!.toIso8601String(),
      if (type != null) 'type': type!.apiValue,
      if (status != null && status!.isNotEmpty) 'status': status,
    };
  }
}

TransactionType _type(String? value) {
  return TransactionType.values.firstWhere(
    (item) => item.apiValue == value,
    orElse: () => TransactionType.buy,
  );
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
