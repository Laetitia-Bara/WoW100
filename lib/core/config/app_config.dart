class AppConfig {
  static const battleNetClientId = 'd1a63c10c180407c9ce681b2faee7b5d';

  static const _apiBaseUrl = String.fromEnvironment(
    'WOW100_API_BASE_URL',
    defaultValue: '/api',
  );

  static const _appBaseUrl = String.fromEnvironment(
    'WOW100_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl => _apiBaseUrl;

  static String get appBaseUrl {
    if (_appBaseUrl.isNotEmpty) {
      return _appBaseUrl;
    }

    return Uri.base.origin;
  }

  static String get battleNetRedirectUri => '$appBaseUrl/callback';
}
