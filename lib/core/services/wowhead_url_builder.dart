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
      return item.externalUrl;
    }

    return 'https://www.wowhead.com$localePath';
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
