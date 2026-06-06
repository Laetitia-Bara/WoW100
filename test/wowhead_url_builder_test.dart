import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/core/services/wowhead_url_builder.dart';
import 'package:wow100/data/models/tracking_category.dart';
import 'package:wow100/data/models/tracking_item.dart';
import 'package:wow100/data/models/wow_expansion.dart';

void main() {
  group('WowheadUrlBuilder', () {
    test('builds localized item URLs first when an item id exists', () {
      final item = _trackingItem(
        category: TrackingCategory.mounts,
        blizzardId: 2435,
        wowheadItemId: 232639,
      );

      expect(
        WowheadUrlBuilder.build(item: item, locale: 'fr-FR'),
        'https://www.wowhead.com/fr/item=232639',
      );
    });

    test('builds localized achievement URLs', () {
      final item = _trackingItem(
        category: TrackingCategory.achievements,
        blizzardId: 1286,
      );

      expect(
        WowheadUrlBuilder.build(item: item, locale: 'fr'),
        'https://www.wowhead.com/fr/achievement=1286',
      );
    });

    test('builds localized Blizzard mount URLs', () {
      final item = _trackingItem(
        category: TrackingCategory.mounts,
        blizzardId: 2435,
      );

      expect(
        WowheadUrlBuilder.build(item: item, locale: 'fr'),
        'https://www.wowhead.com/fr/mount/2435',
      );
    });

    test('builds localized Blizzard battle pet URLs', () {
      final item = _trackingItem(
        category: TrackingCategory.pets,
        blizzardId: 159,
      );

      expect(
        WowheadUrlBuilder.build(item: item, locale: 'fr'),
        'https://www.wowhead.com/fr/battle-pet/159',
      );
    });

    test('falls back to English for unsupported locales', () {
      final item = _trackingItem(
        category: TrackingCategory.mounts,
        blizzardId: 2435,
      );

      expect(
        WowheadUrlBuilder.build(item: item, locale: 'nl-NL'),
        'https://www.wowhead.com/mount/2435',
      );
    });

    test('selects the first Wowhead-supported user locale', () {
      expect(WowheadUrlBuilder.preferredLocaleCode(['nl-NL', 'fr-FR']), 'fr');
    });
  });
}

TrackingItem _trackingItem({
  required TrackingCategory category,
  int? blizzardId,
  int? wowheadItemId,
  int? wowheadAchievementId,
}) {
  return TrackingItem(
    id: 'item',
    name: 'Item',
    category: category,
    expansion: WowExpansion.total,
    zone: '',
    instance: '',
    source: '',
    wowheadItemId: wowheadItemId,
    wowheadAchievementId: wowheadAchievementId,
    groupRequired: false,
    weeklyLockout: false,
    obtained: false,
    blizzardId: blizzardId,
    boss: '',
  );
}
