import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/responsive_page.dart';
import '../providers/treasury_provider.dart';

class AdminTreasuryScreen extends ConsumerStatefulWidget {
  const AdminTreasuryScreen({super.key});

  @override
  ConsumerState<AdminTreasuryScreen> createState() => _AdminTreasuryScreenState();
}

class _AdminTreasuryScreenState extends ConsumerState<AdminTreasuryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _availableController = TextEditingController();

  @override
  void dispose() {
    _availableController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final value = double.parse(_availableController.text);
    final success = await ref
        .read(treasuryControllerProvider.notifier)
        .updateAvailableGold(value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Treasury gold updated successfully.'
              : 'Failed to update treasury gold.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    if (success) {
      ref.invalidate(treasuryProvider);
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final treasuryState = ref.watch(treasuryControllerProvider);
    final theme = Theme.of(context);

    return treasuryState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Failed to load treasury: $error')),
      ),
      data: (treasury) {
        if (treasury == null) {
          return const Scaffold(body: Center(child: Text('Treasury unavailable')));
        }

        if (_availableController.text.isEmpty) {
          _availableController.text = treasury.availableGold.toStringAsFixed(4);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Gold Treasury'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/dashboard'),
            ),
          ),
          body: ResponsivePage(
            title: 'Treasury Management',
            subtitle: 'Set how much gold is available for users to buy',
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Current Treasury', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${treasury.availableGold.toStringAsFixed(4)} g',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: ${DateFormat.yMMMd().add_jm().format(treasury.updatedAt.toLocal())}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Update Available Gold',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Users can only buy gold up to this treasury balance. '
                          'When users sell gold, it is returned to the treasury.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _availableController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Available gold (grams)',
                            suffixText: 'g',
                          ),
                          validator: (value) {
                            final parsed = double.tryParse(value ?? '');
                            if (parsed == null || parsed < 0) {
                              return 'Enter a valid non-negative amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _save,
                          child: const Text('UPDATE TREASURY'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
