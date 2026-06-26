import 'package:flutter/material.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/core/widgets/shared_drawer.dart';
import 'package:ags_gold/features/legal/domain/privacy_policy_content.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ResponsiveNavigationWrapper(
      title: l10n.privacyPolicy,
      child: ColoredBox(
        color: AppTheme.profileBg,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              l10n.privacyPolicy,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.deepNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              PrivacyPolicyContent.intro,
              style: _bodyStyle,
            ),
            const SizedBox(height: 20),
            ...PrivacyPolicyContent.sections.map(_sectionCard),
            const SizedBox(height: 8),
            _contactCard(),
            const SizedBox(height: 20),
            Text(
              PrivacyPolicyContent.closing,
              style: _bodyStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(PrivacyPolicySection section) {
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
            ...section.paragraphs.map(
              (p) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(p, style: _bodyStyle),
              ),
            ),
            if (section.bullets != null) ...[
              const SizedBox(height: 8),
              ...section.bullets!.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
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
          ],
        ),
      ),
    );
  }

  Widget _contactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _contactRow(Icons.phone_outlined, PrivacyPolicyContent.contactPhone),
          const SizedBox(height: 10),
          _contactRow(Icons.language_outlined, 'aurumgold.co.in'),
          const SizedBox(height: 10),
          _contactRow(Icons.email_outlined, PrivacyPolicyContent.contactEmail),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: _bodyStyle.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  static final _bodyStyle = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: AppTheme.profileMuted,
  );
}
