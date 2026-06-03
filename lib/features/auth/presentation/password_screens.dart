import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(authRepositoryProvider)
                  .forgotPassword(_email.text.trim());
              setState(() => _sent = true);
            },
            child: const Text('Send reset link'),
          ),
          if (_sent) const Text('Reset instructions have been sent.'),
        ],
      ),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(authRepositoryProvider)
                  .resetPassword(token: widget.token, password: _password.text);
              setState(() => _done = true);
            },
            child: const Text('Reset password'),
          ),
          if (_done) const Text('Password updated.'),
        ],
      ),
    );
  }
}
