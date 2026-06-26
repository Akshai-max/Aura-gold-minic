import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/core/widgets/empty_state.dart';
import 'package:ags_gold/core/widgets/premium_skeleton.dart';
import 'package:ags_gold/core/widgets/shared_drawer.dart';
import 'package:ags_gold/features/admin/presentation/providers/sell_inquiries_provider.dart';
import 'package:ags_gold/features/user_dashboard/domain/sell_gold_inquiry.dart';
import 'package:ags_gold/services/api_client.dart';

class SellInquiriesScreen extends ConsumerWidget {
  const SellInquiriesScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'responded':
        return AppTheme.emerald;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showRespondDialog(
    BuildContext context,
    WidgetRef ref,
    AdminSellGoldInquiry inquiry,
  ) async {
    final controller = TextEditingController(
      text: inquiry.adminResponse ?? '',
    );
    final formKey = GlobalKey<FormState>();
    var loading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Respond to ${inquiry.name}'),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inquiry.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Your response',
                          alignLabelWithHint: true,
                        ),
                        minLines: 4,
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.trim().length < 5) {
                            return 'Enter a response (min 5 characters)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => loading = true);
                          try {
                            await ref.read(respondSellInquiryProvider)(
                              inquiryId: inquiry.id,
                              adminResponse: controller.text.trim(),
                            );
                            ref.invalidate(sellInquiriesListProvider);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } on ApiException catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => loading = false);
                            }
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send response'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiriesAsync = ref.watch(sellInquiriesListProvider);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return ResponsiveNavigationWrapper(
      title: 'Gold Sell Inquiries',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gold Sell Inquiries',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Review customer sell requests and send responses from here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: inquiriesAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.sell_outlined,
                      title: 'No sell inquiries yet',
                      subtitle:
                          'Customer gold sell requests will appear here.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(sellInquiriesListProvider);
                      await ref.read(sellInquiriesListProvider.future);
                    },
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final inquiry = items[index];
                        final statusColor = _statusColor(inquiry.status);

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        inquiry.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        inquiry.status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  inquiry.mobileNumber,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                if (inquiry.userEmail != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    inquiry.userEmail!,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.55),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Text(inquiry.message),
                                const SizedBox(height: 8),
                                Text(
                                  dateFormat.format(inquiry.createdAt.toLocal()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                if (inquiry.adminResponse != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.emerald.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Response: ${inquiry.adminResponse}',
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                    onPressed: () => _showRespondDialog(
                                      context,
                                      ref,
                                      inquiry,
                                    ),
                                    icon: const Icon(Icons.reply_outlined, size: 18),
                                    label: Text(
                                      inquiry.adminResponse == null
                                          ? 'Respond'
                                          : 'Update response',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const PremiumSkeletonList(itemCount: 5),
                error: (error, _) => Center(child: Text('Failed to load: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
