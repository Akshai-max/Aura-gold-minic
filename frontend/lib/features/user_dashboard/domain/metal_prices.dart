enum MetalType { gold, silver }

class MetalPricePoint {
  final String label;
  final double price;
  final String? date;

  const MetalPricePoint({
    required this.label,
    required this.price,
    this.date,
  });

  factory MetalPricePoint.fromJson(Map<String, dynamic> json) {
    return MetalPricePoint(
      label: json['label'] as String? ?? '',
      price: _parseDecimal(json['price']),
      date: json['date'] as String?,
    );
  }
}

class MetalRetailBreakdown {
  final String region;
  final String purity;
  final double internationalSpot;
  final double importDutyPercent;
  final double importDutyAmount;
  final double gstPercent;
  final double gstAmount;
  final double localPremiumPercent;
  final double localPremiumAmount;
  final double retailPrice;

  const MetalRetailBreakdown({
    required this.region,
    required this.purity,
    required this.internationalSpot,
    required this.importDutyPercent,
    required this.importDutyAmount,
    required this.gstPercent,
    required this.gstAmount,
    required this.localPremiumPercent,
    required this.localPremiumAmount,
    required this.retailPrice,
  });

  factory MetalRetailBreakdown.fromJson(Map<String, dynamic> json) {
    return MetalRetailBreakdown(
      region: json['region'] as String? ?? 'Tamil Nadu',
      purity: json['purity'] as String? ?? '24K',
      internationalSpot: _parseDecimal(json['international_spot']),
      importDutyPercent: _parseDecimal(json['import_duty_percent']),
      importDutyAmount: _parseDecimal(json['import_duty_amount']),
      gstPercent: _parseDecimal(json['gst_percent']),
      gstAmount: _parseDecimal(json['gst_amount']),
      localPremiumPercent: _parseDecimal(json['local_premium_percent']),
      localPremiumAmount: _parseDecimal(json['local_premium_amount']),
      retailPrice: _parseDecimal(json['retail_price']),
    );
  }
}

class MetalQuote {
  final MetalType metal;
  final String unit;
  final double spotPrice;
  final double changePercent;
  final double retailPrice;
  final MetalRetailBreakdown retail;
  final List<MetalPricePoint> trend;

  const MetalQuote({
    required this.metal,
    required this.unit,
    required this.spotPrice,
    required this.changePercent,
    required this.retailPrice,
    required this.retail,
    this.trend = const [],
  });

  factory MetalQuote.fromJson(Map<String, dynamic> json) {
    final metalName = json['metal'] as String? ?? 'gold';
    return MetalQuote(
      metal: metalName == 'silver' ? MetalType.silver : MetalType.gold,
      unit: json['unit'] as String? ?? 'INR/gm',
      spotPrice: _parseDecimal(json['spot_price']),
      changePercent: _parseDecimal(json['change_percent']),
      retailPrice: _parseDecimal(json['retail_price']),
      retail: MetalRetailBreakdown.fromJson(
        json['retail'] as Map<String, dynamic>? ?? {},
      ),
      trend: (json['trend'] as List<dynamic>? ?? [])
          .map((e) => MetalPricePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isUp => changePercent >= 0;

  /// Tamil Nadu market price (API spot + duty/GST/premium, calculated server-side).
  double get displayPrice {
    if (retailPrice > 0) return retailPrice;
    if (retail.retailPrice > 0) return retail.retailPrice;
    return spotPrice;
  }

  double localizeAmount(double amount) => amount > 0 ? amount : 0;
}

class MetalPrices {
  final DateTime refreshedAt;
  final MetalQuote gold;
  final MetalQuote silver;

  const MetalPrices({
    required this.refreshedAt,
    required this.gold,
    required this.silver,
  });

  factory MetalPrices.fromJson(Map<String, dynamic> json) {
    return MetalPrices(
      refreshedAt: DateTime.parse(json['refreshed_at'] as String),
      gold: MetalQuote.fromJson(json['gold'] as Map<String, dynamic>),
      silver: MetalQuote.fromJson(json['silver'] as Map<String, dynamic>),
    );
  }

  MetalQuote quoteFor(MetalType type) =>
      type == MetalType.silver ? silver : gold;
}

double _parseDecimal(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
