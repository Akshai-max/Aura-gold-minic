import 'package:aura_gold/features/auth/domain/auth_inputs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email validation rejects invalid values', () {
    expect(const EmailInput.dirty('bad').isValid, isFalse);
    expect(const EmailInput.dirty('user@example.com').isValid, isTrue);
  });

  test('password validation enforces minimum length', () {
    expect(const PasswordInput.dirty('short').isValid, isFalse);
    expect(const PasswordInput.dirty('Admin@123').isValid, isTrue);
  });
}
