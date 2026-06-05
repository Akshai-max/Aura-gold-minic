import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_page.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const users = [
      ('Admin User', 'admin@ags.com', 'ADMIN', true),
      ('Shareholder One', 'shareholder@ags.com', 'SHAREHOLDER', true),
      ('Demo User', 'user@ags.com', 'USER', false),
    ];
    return ResponsivePage(
      title: 'Users',
      actions: [
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Create'),
        ),
      ],
      children: [
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user.$1.characters.first)),
                title: Text(user.$1),
                subtitle: Text('${user.$2} - ${user.$3}'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: user.$4 ? 'Deactivate' : 'Activate',
                      onPressed: () {},
                      icon: Icon(
                        user.$4
                            ? Icons.toggle_on_outlined
                            : Icons.toggle_off_outlined,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reset password',
                      onPressed: () {},
                      icon: const Icon(Icons.lock_reset_outlined),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
