import 'package:flutter/foundation.dart';

class AppConfig {
  static const battleNetClientId = 'd1a63c10c180407c9ce681b2faee7b5d';
  static const _defaultApiBaseUrl = '/api';
  static const _defaultRemoteApiBaseUrl = 'https://wow100.cosmos-lty.fr/api';
  static const _defaultAppBaseUrl = 'https://wow100.cosmos-lty.fr';

  static const _apiBaseUrl = String.fromEnvironment(
    'WOW100_API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  static const _appBaseUrl = String.fromEnvironment(
    'WOW100_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    final normalized = normalizeApiBaseUrl(_apiBaseUrl);

    if (kIsWeb && normalized.startsWith('/') && _isFlutterLocalDevHost()) {
      return _defaultRemoteApiBaseUrl;
    }

    if (!kIsWeb && normalized.startsWith('/')) {
      return '$appBaseUrl$normalized';
    }

    return normalized;
  }

  static String get appBaseUrl {
    final configuredBaseUrl = normalizeAppBaseUrl(_appBaseUrl);
    if (configuredBaseUrl != null) {
      return configuredBaseUrl;
    }

    if (Uri.base.hasScheme &&
        (Uri.base.scheme == 'http' || Uri.base.scheme == 'https')) {
      return Uri.base.origin;
    }

    return _defaultAppBaseUrl;
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

  static String? normalizeAppBaseUrl(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty || _looksLikeLocalFilePath(trimmed)) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    final scheme = uri.scheme.toLowerCase();
    if ((scheme != 'http' && scheme != 'https') || uri.host.isEmpty) {
      return null;
    }

    return _withoutTrailingSlash(uri.origin);
  }

  static bool _looksLikeLocalFilePath(String value) {
    final normalized = value.replaceAll('\\', '/');
    return RegExp(r'^[a-zA-Z]:/').hasMatch(normalized) ||
        normalized.startsWith('file:/');
  }

  static bool _isFlutterLocalDevHost() {
    final uri = Uri.base;
    final host = uri.host.toLowerCase();
    final isLocalHost =
        host == 'localhost' || host == '127.0.0.1' || host == '::1';

    if (!isLocalHost) {
      return false;
    }

    return uri.port != 8788;
  }

  static String _withoutTrailingSlash(String value) {
    if (value.length <= 1 || !value.endsWith('/')) {
      return value;
    }

    return value.substring(0, value.length - 1);
  }
}
