import 'package:flutter_test/flutter_test.dart';
import 'package:ags_gold/features/app_update/domain/app_update_utils.dart';

void main() {
  group('isAppUpdateAvailable', () {
    test('returns true when remote build is higher', () {
      expect(
        isAppUpdateAvailable(currentVersionCode: 1, remoteVersionCode: 2),
        isTrue,
      );
    });

    test('returns false when builds match', () {
      expect(
        isAppUpdateAvailable(currentVersionCode: 3, remoteVersionCode: 3),
        isFalse,
      );
    });

    test('returns false when remote build is lower', () {
      expect(
        isAppUpdateAvailable(currentVersionCode: 5, remoteVersionCode: 4),
        isFalse,
      );
    });
  });
}
