class AppConfig {
  static const battleNetClientId = 'd1a63c10c180407c9ce681b2faee7b5d';
  static const _defaultApiBaseUrl = '/api';

  static const _apiBaseUrl = String.fromEnvironment(
    'WOW100_API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  static const _appBaseUrl = String.fromEnvironment(
    'WOW100_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl => normalizeApiBaseUrl(_apiBaseUrl);

  static String get appBaseUrl {
    if (_appBaseUrl.isNotEmpty) {
      return _appBaseUrl;
    }

    return Uri.base.origin;
  }

  static String get battleNetRedirectUri => '$appBaseUrl/callback';

  static String normalizeApiBaseUrl(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty || _looksLikeLocalFilePath(trimmed)) {
      return _defaultApiBaseUrl;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return _defaultApiBaseUrl;
    }

    if (uri.hasScheme) {
      final scheme = uri.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') {
        return _withoutTrailingSlash(trimmed);
      }

      return _defaultApiBaseUrl;
    }

    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return _withoutTrailingSlash(path);
  }

  static bool _looksLikeLocalFilePath(String value) {
    final normalized = value.replaceAll('\\', '/');
    return RegExp(r'^[a-zA-Z]:/').hasMatch(normalized) ||
        normalized.startsWith('file:/');
  }

  static String _withoutTrailingSlash(String value) {
    if (value.length <= 1 || !value.endsWith('/')) {
      return value;
    }

    return value.substring(0, value.length - 1);
  }
}
