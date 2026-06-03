import 'package:formz/formz.dart';

enum RequiredInputError { empty }

enum EmailInputError { empty, invalid }

enum PasswordInputError { empty, weak }

class RequiredInput extends FormzInput<String, RequiredInputError> {
  const RequiredInput.pure() : super.pure('');
  const RequiredInput.dirty([super.value = '']) : super.dirty();

  @override
  RequiredInputError? validator(String value) {
    return value.trim().isEmpty ? RequiredInputError.empty : null;
  }
}

class EmailInput extends FormzInput<String, EmailInputError> {
  const EmailInput.pure() : super.pure('');
  const EmailInput.dirty([super.value = '']) : super.dirty();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  EmailInputError? validator(String value) {
    if (value.trim().isEmpty) return EmailInputError.empty;
    if (!_emailRegex.hasMatch(value.trim())) return EmailInputError.invalid;
    return null;
  }
}

class PasswordInput extends FormzInput<String, PasswordInputError> {
  const PasswordInput.pure() : super.pure('');
  const PasswordInput.dirty([super.value = '']) : super.dirty();

  @override
  PasswordInputError? validator(String value) {
    if (value.isEmpty) return PasswordInputError.empty;
    if (value.length < 8) return PasswordInputError.weak;
    return null;
  }
}
