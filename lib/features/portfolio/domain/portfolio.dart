class PortfolioSummary {
  const PortfolioSummary({
    required this.portfolioValue,
    required this.currentPortfolioValue,
    required this.investedAmount,
    required this.profitLoss,
    required this.percentageReturn,
    required this.totalGoldHoldings,
    required this.averagePurchasePrice,
    required this.currentGoldPrice,
    required this.unrealizedGainLoss,
    required this.dailyChange,
    required this.weeklyChange,
    required this.monthlyChange,
    required this.growth,
  });

  final double portfolioValue;
  final double currentPortfolioValue;
  final double investedAmount;
  final double profitLoss;
  final double percentageReturn;
  final double totalGoldHoldings;
  final double averagePurchasePrice;
  final double currentGoldPrice;
  final double unrealizedGainLoss;
  final double dailyChange;
  final double weeklyChange;
  final double monthlyChange;
  final List<PortfolioPoint> growth;

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      portfolioValue: _double(json['portfolio_value']),
      currentPortfolioValue: _double(json['current_portfolio_value']),
      investedAmount: _double(json['invested_amount']),
      profitLoss: _double(json['profit_loss']),
      percentageReturn: _double(json['percentage_return']),
      totalGoldHoldings: _double(json['total_gold_holdings']),
      averagePurchasePrice: _double(json['average_purchase_price']),
      currentGoldPrice: _double(json['current_gold_price']),
      unrealizedGainLoss: _double(json['unrealized_gain_loss']),
      dailyChange: _double(json['daily_change']),
      weeklyChange: _double(json['weekly_change']),
      monthlyChange: _double(json['monthly_change']),
      growth: (json['growth'] as List<dynamic>? ?? [])
          .map((item) => PortfolioPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PortfolioPoint {
  const PortfolioPoint({required this.label, required this.value});

  final String label;
  final double value;

  factory PortfolioPoint.fromJson(Map<String, dynamic> json) {
    return PortfolioPoint(
      label: json['label'] as String? ?? '',
      value: _double(json['value']),
    );
  }
}

class PlatformPortfolioOverview {
  const PlatformPortfolioOverview({
    required this.totalGoldHoldings,
    required this.totalPlatformAssets,
    required this.totalPortfolioValue,
  });

  final double totalGoldHoldings;
  final double totalPlatformAssets;
  final double totalPortfolioValue;

  factory PlatformPortfolioOverview.fromJson(Map<String, dynamic> json) {
    return PlatformPortfolioOverview(
      totalGoldHoldings: _double(json['total_gold_holdings']),
      totalPlatformAssets: _double(json['total_platform_assets']),
      totalPortfolioValue: _double(json['total_portfolio_value']),
    );
  }
}

enum PortfolioRange {
  oneDay('1 Day'),
  oneWeek('1 Week'),
  oneMonth('1 Month'),
  threeMonths('3 Months'),
  oneYear('1 Year');

  const PortfolioRange(this.label);
  final String label;
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
