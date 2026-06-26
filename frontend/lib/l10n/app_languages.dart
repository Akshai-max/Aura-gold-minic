/// Supported app UI languages shown in Settings / Profile.
class AppLanguageOption {
  final String code;
  final String nativeLabel;

  const AppLanguageOption(this.code, this.nativeLabel);
}

const kAppLanguageOptions = <AppLanguageOption>[
  AppLanguageOption('en', 'English'),
  AppLanguageOption('ta', 'தமிழ்'),
];
