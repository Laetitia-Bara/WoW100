import '../../data/models/tracking_item.dart';
import '../../data/models/tracking_category.dart';

class WowheadUrlBuilder {
  static const Set<String> _supportedLocales = {
    'de',
    'es',
    'fr',
    'it',
    'ko',
    'pt',
    'ru',
  };

  static String build({required TrackingItem item, String locale = 'fr'}) {
    final localePath = _localePath(locale);

    if (item.wowheadItemId != null) {
      return 'https://www.wowhead.com$localePath/item=${item.wowheadItemId}';
    }

    if (item.wowheadAchievementId != null) {
      return 'https://www.wowhead.com$localePath/achievement=${item.wowheadAchievementId}';
    }

    if (item.blizzardId != null) {
      switch (item.category) {
        case TrackingCategory.achievements:
          return 'https://www.wowhead.com$localePath/achievement=${item.blizzardId}';
        case TrackingCategory.mounts:
          return 'https://www.wowhead.com$localePath/mount/${item.blizzardId}';
        case TrackingCategory.pets:
          return 'https://www.wowhead.com$localePath/battle-pet/${item.blizzardId}';
        default:
          break;
      }
    }

    if (item.externalUrl.isNotEmpty) {
      return localizeUrl(item.externalUrl, locale: locale);
    }

    return 'https://www.wowhead.com$localePath';
  }

  static String localizeUrl(String url, {String locale = 'fr'}) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';

    final match = RegExp(
      r'^(https?://)(?:(?:www|[a-z]{2})\.)?wowhead\.com(/.*)?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match == null) return url;

    final localePath = _localePath(locale);
    final path = _withLocalePath(match.group(2) ?? '', localePath);

    return '${match.group(1)}www.wowhead.com$path';
  }

  static String preferredLocaleCode(
    Iterable<String> localeCodes, {
    String fallback = 'en',
  }) {
    for (final localeCode in localeCodes) {
      final normalized = _normalizeLocale(localeCode);
      if (normalized != null) return normalized;
    }

    return _normalizeLocale(fallback) ?? 'en';
  }

  static String _localePath(String locale) {
    final normalized = _normalizeLocale(locale);
    return normalized == null || normalized == 'en' ? '' : '/$normalized';
  }

  static String _withLocalePath(String path, String localePath) {
    final localePrefix = RegExp(r'^/(?:de|es|fr|it|ko|pt|ru)(?=/|$)');
    final pathWithoutLocale = path.replaceFirst(localePrefix, '');

    if (localePath.isEmpty) return pathWithoutLocale;
    if (pathWithoutLocale.isEmpty) return localePath;

    return '$localePath$pathWithoutLocale';
  }

  static String? _normalizeLocale(String locale) {
    final languageCode = locale
        .split(RegExp('[-_]'))
        .first
        .trim()
        .toLowerCase();

    if (languageCode == 'en') return 'en';
    if (_supportedLocales.contains(languageCode)) return languageCode;

    return null;
  }
}
