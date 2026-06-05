import '../../data/models/tracking_item.dart';

class WowheadUrlBuilder {
  static String build({required TrackingItem item, String locale = 'fr'}) {
    if (item.externalUrl.isNotEmpty) {
      return item.externalUrl;
    }

    final localePath = locale == 'en' ? '' : '/$locale';

    if (item.wowheadItemId != null) {
      return 'https://www.wowhead.com$localePath/item=${item.wowheadItemId}';
    }

    if (item.wowheadAchievementId != null) {
      return 'https://www.wowhead.com$localePath/achievement=${item.wowheadAchievementId}';
    }

    return 'https://www.wowhead.com$localePath';
  }
}
