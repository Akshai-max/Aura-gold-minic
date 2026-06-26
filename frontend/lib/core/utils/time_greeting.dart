import 'package:ags_gold/l10n/app_localizations.dart';

/// Time-of-day salutation for dashboard greetings (uses device local time).
String timeSalutation(AppLocalizations l10n, [DateTime? when]) {
  final hour = (when ?? DateTime.now()).hour;
  if (hour < 12) return l10n.goodMorning;
  if (hour < 17) return l10n.goodAfternoon;
  return l10n.goodEvening;
}

String greetingWithName(AppLocalizations l10n, String name, [DateTime? when]) {
  return l10n.greetingWithName(timeSalutation(l10n, when), name);
}
