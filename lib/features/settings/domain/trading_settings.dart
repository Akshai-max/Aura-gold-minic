class TradingSettings {
  const TradingSettings({
    required this.buyMargin,
    required this.sellMargin,
    required this.dailyLimit,
    required this.minimumPurchaseAmount,
    required this.maximumPurchaseAmount,
    required this.tradingEnabled,
  });

  final double buyMargin;
  final double sellMargin;
  final double dailyLimit;
  final double minimumPurchaseAmount;
  final double maximumPurchaseAmount;
  final bool tradingEnabled;

  factory TradingSettings.fromJson(Map<String, dynamic> json) {
    return TradingSettings(
      buyMargin: _double(json['buy_margin']),
      sellMargin: _double(json['sell_margin']),
      dailyLimit: _double(json['daily_limit']),
      minimumPurchaseAmount: _double(json['minimum_purchase_amount']),
      maximumPurchaseAmount: _double(json['maximum_purchase_amount']),
      tradingEnabled: json['trading_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'buy_margin': buyMargin,
      'sell_margin': sellMargin,
      'daily_limit': dailyLimit,
      'minimum_purchase_amount': minimumPurchaseAmount,
      'maximum_purchase_amount': maximumPurchaseAmount,
      'trading_enabled': tradingEnabled,
    };
  }

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
