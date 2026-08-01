import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/data/models/achievement_faction_availability.dart';
import 'package:wow100/data/models/tracking_category.dart';
import 'package:wow100/data/models/tracking_item.dart';
import 'package:wow100/data/models/wow_expansion.dart';

void main() {
  test('hides Bloodmyst quest achievements for Horde characters', () {
    final item = _achievement(
      blizzardId: 4926,
      locationRef: 'wowhead-zone:3525',
    );

    expect(
      AchievementFactionAvailability.isUnavailableForFaction(item, 'Horde'),
      isTrue,
    );
    expect(
      AchievementFactionAvailability.isUnavailableForFaction(item, 'Alliance'),
      isFalse,
    );
  });

  test('hides Horde Kalimdor quest replacement for Alliance characters', () {
    final item = _achievement(blizzardId: 4927);

    expect(
      AchievementFactionAvailability.isUnavailableForFaction(item, 'Alliance'),
      isTrue,
    );
    expect(
      AchievementFactionAvailability.isUnavailableForFaction(item, 'Horde'),
      isFalse,
    );
  });

  test('hides Alliance Stonetalon quest achievement for Horde characters', () {
    final item = _achievement(blizzardId: 4936);

    expect(
      AchievementFactionAvailability.isUnavailableForFaction(item, 'Horde'),
      isTrue,
    );
    expect(
      AchievementFactionAvailability.isUnavailableForFaction(item, 'Alliance'),
      isFalse,
    );
  });

  test(
    'hides Alliance Eastern Kingdoms quest achievements for Horde characters',
    () {
      for (final id in [4899, 4902, 4903, 12429, 12430]) {
        final item = _achievement(blizzardId: id);

        expect(
          AchievementFactionAvailability.isUnavailableForFaction(item, 'Horde'),
          isTrue,
          reason: 'achievement_$id should be Alliance-only',
        );
        expect(
          AchievementFactionAvailability.isUnavailableForFaction(
            item,
            'Alliance',
          ),
          isFalse,
          reason: 'achievement_$id should remain visible for Alliance',
        );
      }
    },
  );

  test(
    'hides Horde Eastern Kingdoms quest achievements for Alliance characters',
    () {
      for (final id in [4894, 4895, 4908]) {
        final item = _achievement(blizzardId: id);

        expect(
          AchievementFactionAvailability.isUnavailableForFaction(
            item,
            'Alliance',
          ),
          isTrue,
          reason: 'achievement_$id should be Horde-only',
        );
        expect(
          AchievementFactionAvailability.isUnavailableForFaction(item, 'Horde'),
          isFalse,
          reason: 'achievement_$id should remain visible for Horde',
        );
      }
    },
  );

  test('keeps faction-specific items visible without a selected character', () {
    final item = _achievement(
      blizzardId: 860,
      locationRef: 'wowhead-zone:3524',
    );

    expect(
      AchievementFactionAvailability.isUnavailableForFaction(item, null),
      isFalse,
    );
  });

  test('hides Azuremyst and Bloodmyst exploration for Horde characters', () {
    final item = _achievement(
      blizzardId: 860,
      locationRef: 'wowhead-zone:3524',
    );

    expect(
      AchievementFactionAvailability.isUnavailableForFaction(item, 'Horde'),
      isTrue,
    );
  });
}

TrackingItem _achievement({required int blizzardId, String locationRef = ''}) {
  return TrackingItem(
    id: 'achievement_$blizzardId',
    name: 'Achievement $blizzardId',
    category: TrackingCategory.achievements,
    expansion: WowExpansion.vanilla,
    zone: 'Kalimdor',
    region: 'Kalimdor',
    world: 'Azeroth',
    locationRef: locationRef,
    instance: 'Kalimdor',
    source: '',
    groupRequired: false,
    weeklyLockout: false,
    obtained: false,
    blizzardId: blizzardId,
    boss: '',
  );
}
