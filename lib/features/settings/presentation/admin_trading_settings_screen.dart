import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/responsive_page.dart';
import '../domain/trading_settings.dart';
import '../providers/trading_settings_provider.dart';

class AdminTradingSettingsScreen extends ConsumerStatefulWidget {
  const AdminTradingSettingsScreen({super.key});

  @override
  ConsumerState<AdminTradingSettingsScreen> createState() => _AdminTradingSettingsScreenState();
}

class _AdminTradingSettingsScreenState extends ConsumerState<AdminTradingSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _buyMarginController = TextEditingController();
  final _sellMarginController = TextEditingController();
  final _dailyLimitController = TextEditingController();
  final _minPurchaseController = TextEditingController();
  final _maxPurchaseController = TextEditingController();
  bool _tradingEnabled = true;

  @override
  void dispose() {
    _buyMarginController.dispose();
    _sellMarginController.dispose();
    _dailyLimitController.dispose();
    _minPurchaseController.dispose();
    _maxPurchaseController.dispose();
    super.dispose();
  }

  void _populateFields(TradingSettings settings) {
    _buyMarginController.text = settings.buyMargin.toString();
    _sellMarginController.text = settings.sellMargin.toString();
    _dailyLimitController.text = settings.dailyLimit.toString();
    _minPurchaseController.text = settings.minimumPurchaseAmount.toString();
    _maxPurchaseController.text = settings.maximumPurchaseAmount.toString();
    _tradingEnabled = settings.tradingEnabled;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = TradingSettings(
      buyMargin: double.parse(_buyMarginController.text),
      sellMargin: double.parse(_sellMarginController.text),
      dailyLimit: double.parse(_dailyLimitController.text),
      minimumPurchaseAmount: double.parse(_minPurchaseController.text),
      maximumPurchaseAmount: double.parse(_maxPurchaseController.text),
      tradingEnabled: _tradingEnabled,
    );

    final success = await ref.read(tradingSettingsControllerProvider.notifier).updateSettings(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Trading settings updated successfully!' : 'Failed to update trading settings.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        ref.invalidate(tradingSettingsProvider);
        context.go('/settings');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tradingSettingsControllerProvider);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Trading Settings'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading configurations: $err'),
          ),
        ),
        data: (settings) {
          // Populate fields only once when loaded
          if (_buyMarginController.text.isEmpty) {
            _populateFields(settings);
          }

          return ResponsivePage(
            title: 'Configure Trading Engine',
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Global Switch Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Enable Trading Workflow', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                                Text('Globally enables or disables BUY & SELL features', style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
                              ],
                            ),
                            Switch(
                              value: _tradingEnabled,
                              onChanged: (val) {
                                setState(() {
                                  _tradingEnabled = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Margins Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trading Margins (%)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const Divider(height: 24),
                            TextFormField(
                              controller: _buyMarginController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Buy Premium Margin (%)',
                                hintText: '1.50',
                                suffixText: '%',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || double.tryParse(val) == null) return 'Please enter a valid percentage';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _sellMarginController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Sell Markdown Margin (%)',
                                hintText: '1.00',
                                suffixText: '%',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || double.tryParse(val) == null) return 'Please enter a valid percentage';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Limits Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Purchase Caps & Thresholds (₹)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const Divider(height: 24),
                            TextFormField(
                              controller: _dailyLimitController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Daily Cumulative Purchase Cap',
                                hintText: '100000.00',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || double.tryParse(val) == null) return 'Please enter a valid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _minPurchaseController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Minimum Single Purchase Amount',
                                hintText: '10.00',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || double.tryParse(val) == null) return 'Please enter a valid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _maxPurchaseController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Maximum Single Purchase Amount',
                                hintText: '50000.00',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || double.tryParse(val) == null) return 'Please enter a valid number';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: state.isLoading ? null : _saveSettings,
                      child: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
