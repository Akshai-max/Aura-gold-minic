class AppConfig {
  const AppConfig._();

  static const appName = 'Aura Gold';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
}
