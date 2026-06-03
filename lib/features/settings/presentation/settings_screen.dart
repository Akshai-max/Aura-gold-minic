import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_page.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return ResponsivePage(
      title: 'Settings',
      children: [
        const TextField(
          decoration: InputDecoration(labelText: 'Platform Name'),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(labelText: 'Support Email'),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(labelText: 'Contact Number'),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: false,
          onChanged: (_) {},
          title: const Text('Maintenance Mode'),
        ),
        const SizedBox(height: 12),
        const TextField(
          readOnly: true,
          decoration: InputDecoration(labelText: 'App Version'),
        ),
        const SizedBox(height: 24),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
          ],
          selected: {themeMode},
          onSelectionChanged: (value) {
            ref.read(themeModeProvider.notifier).setMode(value.first);
          },
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Settings'),
        ),
      ],
    );
  }
}
