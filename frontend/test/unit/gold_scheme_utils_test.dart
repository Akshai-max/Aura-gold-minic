import 'package:flutter_test/flutter_test.dart';
import 'package:ags_gold/features/user_dashboard/domain/gold_scheme.dart';
import 'package:ags_gold/features/user_dashboard/domain/gold_scheme_utils.dart';

void main() {
  group('goldSchemeUpgradeOptions', () {
    test('returns 5 and 10 after completing 1g plan', () {
      const scheme = GoldScheme(
        status: GoldSchemeStatus.completed,
        targetGrams: 1,
        savedGrams: 1,
      );

      expect(goldSchemeUpgradeOptions(scheme), [5, 10]);
    });

    test('returns 10 after completing 5g plan', () {
      const scheme = GoldScheme(
        status: GoldSchemeStatus.completed,
        targetGrams: 5,
        savedGrams: 5,
      );

      expect(goldSchemeUpgradeOptions(scheme), [10]);
    });

    test('returns empty after completing 10g plan', () {
      const scheme = GoldScheme(
        status: GoldSchemeStatus.completed,
        targetGrams: 10,
        savedGrams: 10,
      );

      expect(goldSchemeUpgradeOptions(scheme), isEmpty);
    });
  });
}
