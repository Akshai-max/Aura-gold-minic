import 'package:flutter/widgets.dart';
import 'package:ags_gold/l10n/app_localizations.dart';

export 'package:ags_gold/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
