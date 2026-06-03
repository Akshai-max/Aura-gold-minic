import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';

class PermissionGuard extends ConsumerWidget {
  const PermissionGuard({
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
    super.key,
  });

  final String permission;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(authControllerProvider).permissions;
    return permissions.contains(permission) ? child : fallback;
  }
}
