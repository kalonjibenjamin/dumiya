class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'DUMIYA_BASE_URL',
    defaultValue: 'https://microfinance-rdc.online',
  );

  static const String db = String.fromEnvironment(
    'DUMIYA_DB',
    defaultValue: 'finance',
  );
}
