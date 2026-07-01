import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/features/app_update/services/app_update_coordinator.dart';

/// Checks for APK updates on Android startup and shows an in-app prompt.
class AppUpdateListener extends ConsumerStatefulWidget {
  const AppUpdateListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdateListener> createState() => _AppUpdateListenerState();
}

class _AppUpdateListenerState extends ConsumerState<AppUpdateListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appUpdateCoordinatorProvider).checkAndPrompt(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
