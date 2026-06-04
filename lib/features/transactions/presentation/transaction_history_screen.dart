import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_page.dart';
import '../data/transaction_repository.dart';
import '../domain/ledger_transaction.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
final _date = DateFormat('dd MMM yyyy');
final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(transactionProvider.future),
        child: ResponsivePage(
          title: 'Transactions',
          actions: [
            IconButton(
              tooltip: 'Filter transactions',
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterSheet(context, ref),
            ),
          ],
          children: [
            transactions.when(
              loading: () => const _TransactionSkeleton(),
              error: (error, _) => _ErrorCard(
                message: 'Failed to load transactions: $error',
                onRetry: () => ref.invalidate(transactionProvider),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyTransactions()
                  : Column(
                      children: [
                        _FilterSummaryRow(),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return _TransactionCard(item: items[index]);
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _FilterBottomSheet(),
    );
  }
}

/// A summary row showing active filters and clear button
class _FilterSummaryRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final theme = Theme.of(context);

    if (filter.date == null && filter.type == null && filter.status == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (filter.date != null)
                  _FilterChip(label: 'Since ${_date.format(filter.date!)}'),
                if (filter.type != null)
                  _FilterChip(label: 'Type: ${filter.type!.apiValue}'),
                if (filter.status != null)
                  _FilterChip(label: 'Status: ${filter.status}'),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(transactionFilterProvider.notifier).state = const TransactionFilter();
            },
            child: Text(
              'Clear All',
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Redesigned premium Transaction Card
class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.item});

  final LedgerTransaction item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get color and icon based on transaction type
    final typeIconInfo = _getTypeIconInfo(item.transactionType, theme);
    final statusBadgeInfo = _getStatusBadgeInfo(item.status, theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: typeIconInfo.color.withValues(alpha: 0.12),
              child: Icon(typeIconInfo.icon, color: typeIconInfo.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTypeLabel(item.transactionType),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currency.format(item.amount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: typeIconInfo.isIncoming ? theme.colorScheme.success : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.goldAmount.toStringAsFixed(3)} g at ${_currency.format(item.goldPrice)} / g',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dateTime.format(item.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBadgeInfo.bgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusBadgeInfo.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusBadgeInfo.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(TransactionType type) {
    return switch (type) {
      TransactionType.buy => 'Buy Gold',
      TransactionType.sell => 'Sell Gold',
      TransactionType.sip => 'Gold SIP',
      TransactionType.stake => 'Stake Gold',
      TransactionType.unstake => 'Unstake Gold',
      TransactionType.reward => 'Gold Reward',
      TransactionType.redeem => 'Redeem Gold',
    };
  }

  _TypeIconInfo _getTypeIconInfo(TransactionType type, ThemeData theme) {
    return switch (type) {
      TransactionType.buy => _TypeIconInfo(Icons.arrow_downward, theme.colorScheme.primary, false),
      TransactionType.sell => _TypeIconInfo(Icons.arrow_upward, theme.colorScheme.error, true),
      TransactionType.sip => _TypeIconInfo(Icons.loop, theme.colorScheme.primary, false),
      TransactionType.stake => _TypeIconInfo(Icons.lock_outline, Colors.blue, false),
      TransactionType.unstake => _TypeIconInfo(Icons.lock_open_outlined, Colors.purple, true),
      TransactionType.reward => _TypeIconInfo(Icons.card_giftcard, theme.colorScheme.success, true),
      TransactionType.redeem => _TypeIconInfo(Icons.money_outlined, Colors.teal, true),
    };
  }

  _StatusBadgeInfo _getStatusBadgeInfo(String status, ThemeData theme) {
    final clean = status.toUpperCase().trim();
    if (clean == 'COMPLETED') {
      return _StatusBadgeInfo('Completed', theme.colorScheme.success.withValues(alpha: 0.12), theme.colorScheme.success);
    }
    if (clean == 'FAILED') {
      return _StatusBadgeInfo('Failed', theme.colorScheme.error.withValues(alpha: 0.12), theme.colorScheme.error);
    }
    return _StatusBadgeInfo('Pending', Colors.amber.withValues(alpha: 0.12), Colors.amber);
  }
}

class _TypeIconInfo {
  const _TypeIconInfo(this.icon, this.color, this.isIncoming);
  final IconData icon;
  final Color color;
  final bool isIncoming;
}

class _StatusBadgeInfo {
  const _StatusBadgeInfo(this.label, this.bgColor, this.textColor);
  final String label;
  final Color bgColor;
  final Color textColor;
}

/// Filter Bottom Sheet displaying selectors
class _FilterBottomSheet extends ConsumerStatefulWidget {
  const _FilterBottomSheet();

  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  DateTime? _selectedDate;
  TransactionType? _selectedType;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(transactionFilterProvider);
    _selectedDate = currentFilter.date;
    _selectedType = currentFilter.type;
    _selectedStatus = currentFilter.status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Transactions',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date Filter
          Text('Transaction Date', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                initialDate: _selectedDate ?? DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _selectedDate == null ? 'Show Transactions Since Date' : 'Since: ${_date.format(_selectedDate!)}',
            ),
          ),
          const SizedBox(height: 16),
          // Type Filter
          Text('Transaction Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<TransactionType?>(
            value: _selectedType,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Types')),
              ...TransactionType.values.map(
                (type) => DropdownMenuItem(value: type, child: Text(type.name.toUpperCase())),
              ),
            ],
            onChanged: (val) {
              setState(() {
                _selectedType = val;
              });
            },
          ),
          const SizedBox(height: 16),
          // Status Filter
          Text('Transaction Status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _selectedStatus,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Statuses')),
              DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
              DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
              DropdownMenuItem(value: 'FAILED', child: Text('Failed')),
            ],
            onChanged: (val) {
              setState(() {
                _selectedStatus = val;
              });
            },
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                      _selectedType = null;
                      _selectedStatus = null;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ref.read(transactionFilterProvider.notifier).state = TransactionFilter(
                      date: _selectedDate,
                      type: _selectedType,
                      status: _selectedStatus,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Transactions Found',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No records match your active filters. Try adjusting dates or types.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Clear filters
              },
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionSkeleton extends StatefulWidget {
  const _TransactionSkeleton();

  @override
  State<_TransactionSkeleton> createState() => _TransactionSkeletonState();
}

class _TransactionSkeletonState extends State<_TransactionSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.8).animate(_controller),
      child: Column(
        children: List.generate(
          4,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Card(child: SizedBox(height: 96, width: double.infinity)),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
