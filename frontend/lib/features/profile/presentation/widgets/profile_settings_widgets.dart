import 'package:flutter/material.dart';
import 'package:ags_gold/core/theme/app_theme.dart';

class ProfileSectionHeader extends StatelessWidget {
  final String title;

  const ProfileSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.deepNavy,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class ProfileSettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const ProfileSettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          ],
        ],
      ),
    );
  }
}

class ProfileSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProfileSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppTheme.deepNavy),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.deepNavy,
                  ),
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.profileMuted.withValues(alpha: 0.8),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileHeaderCard extends StatelessWidget {
  final String displayName;
  final String contactLine;
  final String memberSinceLine;
  final String initials;
  final bool showVerifiedBadge;
  final VoidCallback? onAvatarTap;

  const ProfileHeaderCard({
    super.key,
    required this.displayName,
    required this.contactLine,
    required this.memberSinceLine,
    required this.initials,
    this.showVerifiedBadge = false,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onAvatarTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppTheme.auraPurple,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showVerifiedBadge)
                Positioned(
                  right: -2,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.emerald,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.deepNavy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          contactLine,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.deepNavy,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          memberSinceLine,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.auraPurple,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
