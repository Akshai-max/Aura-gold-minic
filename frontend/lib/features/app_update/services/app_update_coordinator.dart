import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ags_gold/features/app_update/domain/android_app_release.dart';
import 'package:ags_gold/features/app_update/domain/app_update_utils.dart';
import 'package:ags_gold/features/app_update/presentation/providers/app_update_provider.dart';
import 'package:ags_gold/features/app_update/presentation/widgets/app_update_prompt.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

class AppUpdateCoordinator {
  AppUpdateCoordinator(this._ref);

  final Ref _ref;
  bool _promptVisible = false;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> checkAndPrompt(
    BuildContext context, {
    bool manual = false,
  }) async {
    if (!isSupported || !context.mounted) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;
      final release = await _ref
          .read(appUpdateRepositoryProvider)
          .fetchAndroidRelease();

      if (!context.mounted) return;

      if (release == null) {
        if (manual) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.appUpdateNotConfigured)),
          );
        }
        return;
      }

      final updateAvailable = isAppUpdateAvailable(
        currentVersionCode: currentCode,
        remoteVersionCode: release.versionCode,
      );

      if (!updateAvailable) {
        if (manual) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.appUpdateUpToDate)),
          );
        }
        return;
      }

      if (_promptVisible) return;
      _promptVisible = true;

      final accepted = await showAppUpdatePrompt(
        context: context,
        release: release,
        currentVersionName: packageInfo.version,
      );

      _promptVisible = false;
      if (!accepted || !context.mounted) return;

      await _downloadAndInstall(context, release);
    } catch (_) {
      if (manual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.appUpdateFailed)),
        );
      }
    }
  }

  Future<void> _downloadAndInstall(
    BuildContext context,
    AndroidAppRelease release,
  ) async {
    if (!context.mounted) return;

    final progressNotifier = ValueNotifier<double?>(null);
    unawaited(
      showAppUpdateProgressSheet(
        context: context,
        progress: progressNotifier,
      ),
    );

    try {
      await for (final event in OtaUpdate().execute(
        release.apkUrl,
        destinationFilename: 'ags_gold_update.apk',
      )) {
        switch (event.status) {
          case OtaStatus.DOWNLOADING:
            final raw = event.value;
            if (raw != null) {
              progressNotifier.value = (raw as num).toDouble();
            }
          case OtaStatus.INSTALLING:
            progressNotifier.value = 100;
          case OtaStatus.INSTALLATION_DONE:
          case OtaStatus.CANCELED:
          case OtaStatus.ALREADY_RUNNING_ERROR:
            return;
          case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).maybePop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.appUpdatePermissionError)),
              );
            }
            return;
          case OtaStatus.DOWNLOAD_ERROR:
          case OtaStatus.CHECKSUM_ERROR:
          case OtaStatus.INTERNAL_ERROR:
          case OtaStatus.INSTALLATION_ERROR:
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).maybePop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.appUpdateFailed)),
              );
            }
            return;
        }
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    }
  }
}

final appUpdateCoordinatorProvider = Provider<AppUpdateCoordinator>((ref) {
  return AppUpdateCoordinator(ref);
});
