import 'package:flutter_test/flutter_test.dart';
import 'package:aura_gold/features/portfolio/domain/portfolio.dart';

void main() {
  group('Portfolio Unit Tests', () {
    test('PortfolioSummary parses valid JSON correctly', () {
      final json = {
        'portfolio_value': 10000.0,
        'current_portfolio_value': 12000.0,
        'invested_amount': '9000.0', // String representation
        'profit_loss': 3000.0,
        'percentage_return': 33.33,
        'total_gold_holdings': 1.637,
        'average_purchase_price': 5500.0,
        'current_gold_price': 7325.40,
        'unrealized_gain_loss': 3000.0,
        'daily_change': -150.0,
        'weekly_change': 500.0,
        'monthly_change': 1200.0,
        'growth': [
          {'label': '2026-06-01', 'value': 9000.0},
          {'label': '2026-06-02', 'value': 9500.0},
          {'label': '2026-06-03', 'value': 12000.0},
        ],
      };

      final summary = PortfolioSummary.fromJson(json);

      expect(summary.portfolioValue, equals(10000.0));
      expect(summary.currentPortfolioValue, equals(12000.0));
      expect(summary.investedAmount, equals(9000.0)); // Correct double conversion
      expect(summary.profitLoss, equals(3000.0));
      expect(summary.percentageReturn, equals(33.33));
      expect(summary.totalGoldHoldings, equals(1.637));
      expect(summary.growth.length, equals(3));
      expect(summary.growth[1].label, equals('2026-06-02'));
      expect(summary.growth[2].value, equals(12000.0));
    });

    test('PortfolioSummary handles empty growth lists and missing elements gracefully', () {
      final json = {
        'portfolio_value': 0.0,
        'current_portfolio_value': 0.0,
        'invested_amount': 0.0,
        'profit_loss': 0.0,
        'percentage_return': 0.0,
        'total_gold_holdings': 0.0,
        'average_purchase_price': 0.0,
        'current_gold_price': 0.0,
        'unrealized_gain_loss': 0.0,
        'daily_change': 0.0,
        'weekly_change': 0.0,
        'monthly_change': 0.0,
        'growth': null,
      };

      final summary = PortfolioSummary.fromJson(json);

      expect(summary.growth, isEmpty);
      expect(summary.currentPortfolioValue, equals(0.0));
    });

    test('PortfolioPoint parsing matches data', () {
      final point = PortfolioPoint.fromJson(const {
        'label': 'Point A',
        'value': '125.40',
      });

      expect(point.label, equals('Point A'));
      expect(point.value, equals(125.40));
    });
  });
}
