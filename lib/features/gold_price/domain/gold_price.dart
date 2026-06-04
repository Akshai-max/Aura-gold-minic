class GoldPrice {
  const GoldPrice({
    required this.currentPrice,
    required this.price24k,
    required this.price22k,
    required this.priceChange,
    required this.percentageChange,
    required this.todaysHigh,
    required this.todaysLow,
    required this.openingPrice,
    required this.source,
    required this.lastUpdated,
    required this.history,
  });

  final double currentPrice;
  final double price24k;
  final double price22k;
  final double priceChange;
  final double percentageChange;
  final double todaysHigh;
  final double todaysLow;
  final double openingPrice;
  final String source;
  final DateTime lastUpdated;
  final List<GoldPricePoint> history;

  factory GoldPrice.fromJson(Map<String, dynamic> json) {
    return GoldPrice(
      currentPrice: _double(json['current_price']),
      price24k: _double(json['price_24k']),
      price22k: _double(json['price_22k']),
      priceChange: _double(json['price_change']),
      percentageChange: _double(json['percentage_change']),
      todaysHigh: _double(json['todays_high']),
      todaysLow: _double(json['todays_low']),
      openingPrice: _double(json['opening_price']),
      source: json['source'] as String? ?? 'No price configured',
      lastUpdated: DateTime.tryParse(json['last_updated']?.toString() ?? '') ??
          DateTime.now(),
      history: (json['history'] as List<dynamic>? ?? [])
          .map((item) => GoldPricePoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GoldPricePoint {
  const GoldPricePoint({required this.label, required this.price});

  final String label;
  final double price;

  factory GoldPricePoint.fromJson(Map<String, dynamic> json) {
    return GoldPricePoint(
      label: json['label'] as String? ?? '',
      price: _double(json['price']),
    );
  }
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
