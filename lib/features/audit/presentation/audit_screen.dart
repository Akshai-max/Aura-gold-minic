import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_page.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const events = [
      'Login',
      'Logout',
      'User Creation',
      'User Updates',
      'Role Assignment',
      'Password Changes',
      'Settings Changes',
    ];
    return ResponsivePage(
      title: 'Audit Logs',
      children: [
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(events[index]),
              subtitle: const Text('Tracked by backend audit service'),
              trailing: const Text('Today'),
            ),
          ),
        ),
      ],
    );
  }
}
