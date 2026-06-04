class GoldSettings {
  const GoldSettings({
    required this.autoPriceFeedEnabled,
    required this.currentProvider,
    required this.updateFrequency,
    required this.manualOverridePrice,
  });

  final bool autoPriceFeedEnabled;
  final String currentProvider;
  final String updateFrequency;
  final double manualOverridePrice;

  GoldSettings copyWith({
    bool? autoPriceFeedEnabled,
    String? currentProvider,
    String? updateFrequency,
    double? manualOverridePrice,
  }) {
    return GoldSettings(
      autoPriceFeedEnabled: autoPriceFeedEnabled ?? this.autoPriceFeedEnabled,
      currentProvider: currentProvider ?? this.currentProvider,
      updateFrequency: updateFrequency ?? this.updateFrequency,
      manualOverridePrice: manualOverridePrice ?? this.manualOverridePrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auto_price_feed_enabled': autoPriceFeedEnabled,
      'current_provider': currentProvider,
      'update_frequency': updateFrequency,
      'manual_override_price': manualOverridePrice,
    };
  }

  factory GoldSettings.fromJson(Map<String, dynamic> json) {
    return GoldSettings(
      autoPriceFeedEnabled: json['auto_price_feed_enabled'] as bool? ?? true,
      currentProvider:
          json['current_provider'] as String? ?? 'Manual Price Feed',
      updateFrequency: json['update_frequency'] as String? ?? '5 minutes',
      manualOverridePrice: _double(json['manual_override_price']),
    );
  }
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
