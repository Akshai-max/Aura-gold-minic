import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_page.dart';

class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsivePage(
      title: 'Roles',
      children: [
        _RoleTile(
          name: 'ADMIN',
          permissions:
              'Manage Users, Manage Roles, Manage Permissions, Settings, Audit',
        ),
        SizedBox(height: 12),
        _RoleTile(name: 'SHAREHOLDER', permissions: 'Reports, Analytics'),
        SizedBox(height: 12),
        _RoleTile(name: 'USER', permissions: 'Dashboard, Profile'),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.name, required this.permissions});

  final String name;
  final String permissions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.verified_user_outlined),
        title: Text(name),
        subtitle: Text(permissions),
        trailing: IconButton(
          tooltip: 'Manage',
          onPressed: () {},
          icon: const Icon(Icons.tune_outlined),
        ),
      ),
    );
  }
}
