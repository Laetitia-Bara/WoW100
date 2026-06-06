import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/core/config/app_config.dart';

void main() {
  group('AppConfig.normalizeApiBaseUrl', () {
    test('keeps absolute http URLs', () {
      expect(
        AppConfig.normalizeApiBaseUrl('https://wow100.cosmos-lty.fr/api/'),
        'https://wow100.cosmos-lty.fr/api',
      );
    });

    test('keeps root-relative API paths', () {
      expect(AppConfig.normalizeApiBaseUrl('/api/'), '/api');
    });

    test('converts simple relative API paths to root-relative paths', () {
      expect(AppConfig.normalizeApiBaseUrl('api'), '/api');
    });

    test('rejects accidental Windows paths', () {
      expect(
        AppConfig.normalizeApiBaseUrl(r'C:\Users\baral\Documents\DEV\Git\api'),
        '/api',
      );
    });

    test('rejects file URLs', () {
      expect(AppConfig.normalizeApiBaseUrl('file:///tmp/api'), '/api');
    });
  });

  group('AppConfig.normalizeAppBaseUrl', () {
    test('keeps absolute http URLs without trailing slash', () {
      expect(
        AppConfig.normalizeAppBaseUrl('https://wow100.cosmos-lty.fr/'),
        'https://wow100.cosmos-lty.fr',
      );
    });

    test('rejects relative URLs', () {
      expect(AppConfig.normalizeAppBaseUrl('/callback'), isNull);
    });

    test('rejects file URLs', () {
      expect(AppConfig.normalizeAppBaseUrl('file:///'), isNull);
    });
  });

  group('AppConfig runtime defaults', () {
    test('uses an absolute API URL outside Flutter Web', () {
      expect(AppConfig.apiBaseUrl, 'https://wow100.cosmos-lty.fr/api');
    });

    test('uses an HTTPS Battle.net redirect URL', () {
      expect(
        AppConfig.battleNetRedirectUri,
        'https://wow100.cosmos-lty.fr/callback',
      );
    });
  });
}
