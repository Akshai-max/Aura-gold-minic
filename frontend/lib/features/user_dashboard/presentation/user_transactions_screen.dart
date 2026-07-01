import 'package:flutter/material.dart';
import 'package:ags_gold/core/theme/aurum_consumer_theme.dart';
import 'package:ags_gold/core/widgets/shared_drawer.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

class UserTransactionsScreen extends StatelessWidget {
  const UserTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ResponsiveNavigationWrapper(
      title: l10n.myTransactions,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: AurumConsumerTheme.muted(context),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noTransactionsYet,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AurumConsumerTheme.muted(context),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
