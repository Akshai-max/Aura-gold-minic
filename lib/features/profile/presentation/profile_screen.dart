import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_page.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return ResponsivePage(
      title: 'Profile',
      children: [
        TextFormField(
          initialValue: user?.firstName,
          decoration: const InputDecoration(labelText: 'First Name'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: user?.lastName,
          decoration: const InputDecoration(labelText: 'Last Name'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: user?.email,
          decoration: const InputDecoration(labelText: 'Email'),
          readOnly: true,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: user?.mobileNumber,
          decoration: const InputDecoration(labelText: 'Mobile Number'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Profile'),
        ),
        const SizedBox(height: 24),
        Text('Change Password', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(labelText: 'Current Password'),
        ),
        const SizedBox(height: 12),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(labelText: 'New Password'),
        ),
      ],
    );
  }
}
