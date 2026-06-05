import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RoyalBrandMark extends StatelessWidget {
  const RoyalBrandMark({
    this.size = RoyalBrandSize.medium,
    this.showTagline = false,
    super.key,
  });

  final RoyalBrandSize size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleSize = switch (size) {
      RoyalBrandSize.small => 18.0,
      RoyalBrandSize.medium => 24.0,
      RoyalBrandSize.large => 32.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: titleSize * 0.9,
              height: titleSize * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.royalGold.withValues(alpha: 0.45),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.royalGold.withValues(alpha: isDark ? 0.22 : 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.diamond_outlined,
                color: AppColors.royalGold,
                size: titleSize * 0.5,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AGS',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: titleSize,
                    letterSpacing: 3.2,
                    fontWeight: FontWeight.w300,
                    color: isDark ? Colors.white : const Color(0xFF1C1E24),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: titleSize * 2.2,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.royalGold,
                        AppColors.royalGold.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 10),
          Text(
            'Refined wealth management',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onDarkMuted : AppColors.onLightMuted,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }
}

enum RoyalBrandSize { small, medium, large }

class RoyalPageHeader extends StatelessWidget {
  const RoyalPageHeader({
    required this.title,
    this.subtitle,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.brightness == Brightness.dark
        ? AppColors.onDarkMuted
        : AppColors.onLightMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  ],
                ],
              ),
            ),
            ...actions,
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.royalGold.withValues(alpha: 0.55),
                AppColors.royalGold.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RoyalAuthScaffold extends StatelessWidget {
  const RoyalAuthScaffold({
    required this.child,
    this.showBrand = true,
    super.key,
  });

  final Widget child;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkBg,
                    const Color(0xFF12151C),
                    AppColors.darkBg,
                  ]
                : [
                    AppColors.lightBg,
                    const Color(0xFFF0EBE2),
                    AppColors.lightBg,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBrand) ...[
                      const RoyalBrandMark(
                        size: RoyalBrandSize.large,
                        showTagline: true,
                      ),
                      const SizedBox(height: 36),
                    ],
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.royalGold.withValues(
                            alpha: isDark ? 0.22 : 0.28,
                          ),
                        ),
                        color: isDark
                            ? AppColors.darkSurface.withValues(alpha: 0.92)
                            : AppColors.lightSurface.withValues(alpha: 0.96),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.royalGoldDeep.withValues(
                              alpha: isDark ? 0.08 : 0.06,
                            ),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoyalDrawerHeader extends StatelessWidget {
  const RoyalDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.royalGold.withValues(alpha: 0.18),
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.royalGold.withValues(alpha: isDark ? 0.1 : 0.07),
            Colors.transparent,
          ],
        ),
      ),
      child: const RoyalBrandMark(size: RoyalBrandSize.small),
    );
  }
}

class RoyalGoldDivider extends StatelessWidget {
  const RoyalGoldDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.royalGold.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
