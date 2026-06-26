import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/core/widgets/shared_drawer.dart';
import 'package:ags_gold/features/legal/domain/digi_gold_terms.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';
import 'package:ags_gold/services/service_providers.dart';

class DigiGoldTermsScreen extends ConsumerWidget {
  const DigiGoldTermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isAuthenticated =
        ref.watch(authNotifierProvider).value == AuthStatus.authenticated;
    final content = _TermsBody(title: l10n.digiGoldTermsTitle);

    if (isAuthenticated) {
      return ResponsiveNavigationWrapper(
        title: l10n.digiGoldTermsTitle,
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.digiGoldTermsTitle)),
      body: content,
    );
  }
}

class _TermsBody extends StatelessWidget {
  final String title;

  const _TermsBody({required this.title});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.profileBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(DigiGoldTermsContent.intro, style: _bodyStyle),
          const SizedBox(height: 20),
          ...DigiGoldTermsContent.sections.map(_sectionCard),
        ],
      ),
    );
  }

  Widget _sectionCard(DigiGoldTermsSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.deepNavy,
              ),
            ),
            ...section.bullets.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(fontSize: 15)),
                    Expanded(child: Text(item, style: _bodyStyle)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final _bodyStyle = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: AppTheme.profileMuted,
  );
}
