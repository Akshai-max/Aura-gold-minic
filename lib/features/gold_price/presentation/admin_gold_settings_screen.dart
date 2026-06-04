import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/responsive_page.dart';
import '../data/gold_price_repository.dart';
import '../domain/gold_settings.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

class AdminGoldSettingsScreen extends ConsumerStatefulWidget {
  const AdminGoldSettingsScreen({super.key});

  @override
  ConsumerState<AdminGoldSettingsScreen> createState() =>
      _AdminGoldSettingsScreenState();
}

class _AdminGoldSettingsScreenState
    extends ConsumerState<AdminGoldSettingsScreen> {
  final _priceController = TextEditingController();
  GoldSettings? _draft;
  bool _saving = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = ref.watch(goldPriceProvider);
    final settings = ref.watch(goldSettingsProvider);
    return ResponsivePage(
      title: 'Gold Settings',
      children: [
        price.when(
          loading: () => const Card(child: SizedBox(height: 96)),
          error: (_, __) => const SizedBox.shrink(),
          data: (data) => Card(
            child: ListTile(
              leading:
                  const Icon(Icons.currency_rupee, color: Color(0xFFD4AF37)),
              title: const Text('Current Gold Price'),
              subtitle: Text(data.source),
              trailing: Text(
                '${_currency.format(data.currentPrice)} / g',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        settings.when(
          loading: () => const Card(child: SizedBox(height: 260)),
          error: (error, _) => Text('Unable to load settings: $error'),
          data: (data) {
            _draft ??= data;
            if (_priceController.text.isEmpty) {
              _priceController.text = data.manualOverridePrice == 0
                  ? ''
                  : data.manualOverridePrice.toStringAsFixed(2);
            }
            final draft = _draft!;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: draft.autoPriceFeedEnabled,
                      onChanged: (value) {
                        setState(() {
                          _draft = draft.copyWith(autoPriceFeedEnabled: value);
                        });
                      },
                      title: const Text('Auto Price Feed Enabled'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: draft.currentProvider,
                      decoration:
                          const InputDecoration(labelText: 'Current Provider'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Manual Price Feed',
                          child: Text('Manual Price Feed'),
                        ),
                        DropdownMenuItem(
                          value: 'MetalPriceAPI',
                          child: Text('MetalPriceAPI'),
                        ),
                        DropdownMenuItem(
                          value: 'GoldAPI',
                          child: Text('GoldAPI'),
                        ),
                        DropdownMenuItem(
                          value: 'Custom Admin Price Feed',
                          child: Text('Custom Admin Price Feed'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(
                          () => _draft = draft.copyWith(currentProvider: value),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: draft.updateFrequency,
                      decoration:
                          const InputDecoration(labelText: 'Update Frequency'),
                      items: const [
                        DropdownMenuItem(
                          value: '1 minute',
                          child: Text('1 minute'),
                        ),
                        DropdownMenuItem(
                          value: '5 minutes',
                          child: Text('5 minutes'),
                        ),
                        DropdownMenuItem(
                          value: '15 minutes',
                          child: Text('15 minutes'),
                        ),
                        DropdownMenuItem(
                          value: '1 hour',
                          child: Text('1 hour'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(
                          () => _draft = draft.copyWith(updateFrequency: value),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Manual Override Price',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _save(draft),
                        icon: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save Gold Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _save(GoldSettings draft) async {
    setState(() => _saving = true);
    final next = draft.copyWith(
      manualOverridePrice: double.tryParse(_priceController.text) ?? 0,
    );
    try {
      await ref.read(goldPriceRepositoryProvider).saveSettings(next);
      ref.invalidate(goldSettingsProvider);
      ref.invalidate(goldPriceProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gold settings saved')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
