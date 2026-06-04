enum OrderType {
  buy,
  sell;

  String get apiValue => name.toUpperCase();

  static OrderType fromString(String? value) {
    final clean = value?.toUpperCase().trim();
    if (clean == 'SELL') return OrderType.sell;
    return OrderType.buy;
  }
}

enum OrderStatus {
  created,
  pendingPayment,
  processing,
  completed,
  failed,
  cancelled;

  String get apiValue => switch (this) {
    OrderStatus.created => 'CREATED',
    OrderStatus.pendingPayment => 'PENDING_PAYMENT',
    OrderStatus.processing => 'PROCESSING',
    OrderStatus.completed => 'COMPLETED',
    OrderStatus.failed => 'FAILED',
    OrderStatus.cancelled => 'CANCELLED',
  };

  static OrderStatus fromString(String? value) {
    return switch (value?.toUpperCase().trim()) {
      'CREATED' => OrderStatus.created,
      'PENDING_PAYMENT' => OrderStatus.pendingPayment,
      'PROCESSING' => OrderStatus.processing,
      'COMPLETED' => OrderStatus.completed,
      'FAILED' => OrderStatus.failed,
      'CANCELLED' => OrderStatus.cancelled,
      _ => OrderStatus.failed,
    };
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.orderType,
    required this.goldQuantity,
    required this.price,
    required this.amount,
    required this.fees,
    required this.taxes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int userId;
  final OrderType orderType;
  final double goldQuantity;
  final double price;
  final double amount;
  final double fees;
  final double taxes;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      orderType: OrderType.fromString(json['order_type']?.toString()),
      goldQuantity: _double(json['gold_quantity']),
      price: _double(json['price']),
      amount: _double(json['amount']),
      fees: _double(json['fees']),
      taxes: _double(json['taxes']),
      status: OrderStatus.fromString(json['status']?.toString()),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
