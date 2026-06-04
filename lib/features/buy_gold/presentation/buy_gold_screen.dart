import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../gold_price/data/gold_price_repository.dart';
import '../../settings/providers/trading_settings_provider.dart';
import '../providers/buy_gold_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

class BuyGoldScreen extends ConsumerStatefulWidget {
  const BuyGoldScreen({super.key});

  @override
  ConsumerState<BuyGoldScreen> createState() => _BuyGoldScreenState();
}

class _BuyGoldScreenState extends ConsumerState<BuyGoldScreen> {
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _ignoreControllerCallbacks = false;

  @override
  void initState() {
    super.initState();
    // Reset notifier on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(buyGoldNotifierProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    if (_ignoreControllerCallbacks) return;
    final parsed = double.tryParse(val) ?? 0.0;
    
    // Update amount in provider
    ref.read(buyGoldNotifierProvider.notifier).updateAmount(parsed);
    
    // Auto-update quantity text field
    final state = ref.read(buyGoldNotifierProvider);
    _ignoreControllerCallbacks = true;
    if (state.goldQuantity > 0) {
      _quantityController.text = state.goldQuantity.toStringAsFixed(4);
    } else {
      _quantityController.clear();
    }
    _ignoreControllerCallbacks = false;
  }

  void _onQuantityChanged(String val) {
    if (_ignoreControllerCallbacks) return;
    final parsed = double.tryParse(val) ?? 0.0;

    // Update quantity in provider
    ref.read(buyGoldNotifierProvider.notifier).updateQuantity(parsed);

    // Auto-update amount text field
    final state = ref.read(buyGoldNotifierProvider);
    _ignoreControllerCallbacks = true;
    if (state.amount > 0) {
      _amountController.text = state.amount.toStringAsFixed(2);
    } else {
      _amountController.clear();
    }
    _ignoreControllerCallbacks = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final buyState = ref.watch(buyGoldNotifierProvider);
    final settingsAsync = ref.watch(tradingSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Gold'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load settings: $err')),
        data: (settings) {
          if (!settings.tradingEnabled) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Trading is disabled',
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Buy and sell trading flows are temporarily disabled by the administrator.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ResponsivePage(
            title: 'Enter Amount or Grams',
            children: [
              // Live Rate Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Purchase Rate (incl. margin)',
                            style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_currency.format(buyState.buyRate)} / gram',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.show_chart, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Inputs Row
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Amount Input
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: textTheme.headlineSmall,
                        decoration: InputDecoration(
                          labelText: 'Buy Amount',
                          prefixText: '₹ ',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _amountController.clear();
                              _onAmountChanged('');
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: _onAmountChanged,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.outlineVariant,
                          child: const Icon(Icons.swap_vert, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Grams Input
                      TextField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: textTheme.headlineSmall,
                        decoration: InputDecoration(
                          labelText: 'Gold Quantity',
                          suffixText: 'grams',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _quantityController.clear();
                              _onQuantityChanged('');
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: _onQuantityChanged,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Limits Info Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Min: ${_currency.format(settings.minimumPurchaseAmount)}',
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    Text(
                      'Max: ${_currency.format(settings.maximumPurchaseAmount)}',
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    Text(
                      'Daily Limit: ${_currency.format(settings.dailyLimit)}',
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error banner
              if (buyState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          buyState.error!,
                          style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Next/Proceed Button
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: buyState.error != null || buyState.amount <= 0 || buyState.submitting
                    ? null
                    : () {
                        // Go to review screen
                        context.push('/buy-review');
                      },
                child: buyState.submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Review Purchase',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
