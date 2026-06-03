import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';

class RoleGuard extends ConsumerWidget {
  const RoleGuard({
    required this.roles,
    required this.child,
    this.fallback = const SizedBox.shrink(),
    super.key,
  });

  final Set<String> roles;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).user?.role;
    return role != null && roles.contains(role) ? child : fallback;
  }
}
