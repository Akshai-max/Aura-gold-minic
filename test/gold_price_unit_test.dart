import 'package:flutter_test/flutter_test.dart';
import 'package:aura_gold/features/gold_price/domain/gold_price.dart';
import 'package:aura_gold/features/gold_price/domain/gold_settings.dart';

void main() {
  group('Gold Price Unit Tests', () {
    test('GoldPrice parses complex historical charts JSON correctly', () {
      final json = {
        'current_price': '7325.40',
        'price_24k': 7325.40,
        'price_22k': 6714.95,
        'price_change': 84.20,
        'percentage_change': 1.16,
        'todays_high': 7364.90,
        'todays_low': 7241.20,
        'opening_price': 7241.20,
        'source': 'Admin Price Feed',
        'last_updated': '2026-06-04T10:00:00Z',
        'history': [
          {'label': '1D', 'price': 7241.20},
          {'label': '1W', 'price': 7280.00},
          {'label': '1M', 'price': 7325.40},
        ],
      };

      final price = GoldPrice.fromJson(json);

      expect(price.currentPrice, equals(7325.40));
      expect(price.price24k, equals(7325.40));
      expect(price.history.length, equals(3));
      expect(price.history[0].label, equals('1D'));
      expect(price.history[0].price, equals(7241.20));
    });

    test('GoldSettings parsing and copyWith functions work correctly', () {
      final settings = GoldSettings.fromJson(const {
        'auto_price_feed_enabled': true,
        'current_provider': 'MetalPriceAPI',
        'update_frequency': '5 minutes',
        'manual_override_price': 7300.0,
      });

      expect(settings.autoPriceFeedEnabled, isTrue);
      expect(settings.currentProvider, equals('MetalPriceAPI'));
      expect(settings.manualOverridePrice, equals(7300.0));

      final updated = settings.copyWith(
        autoPriceFeedEnabled: false,
        manualOverridePrice: 0.0,
      );

      expect(updated.autoPriceFeedEnabled, isFalse);
      expect(updated.currentProvider, equals('MetalPriceAPI'));
      expect(updated.manualOverridePrice, equals(0.0));

      final map = updated.toJson();
      expect(map['auto_price_feed_enabled'], isFalse);
      expect(map['manual_override_price'], equals(0.0));
    });
  });
}
