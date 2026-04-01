class AppConfig {
  static const String baseUrl = 'https://microfinance-rdc.online';
  static const String db = 'finance';

  static String get normalizedBaseUrl {
    final url = baseUrl.trim();
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }
}
