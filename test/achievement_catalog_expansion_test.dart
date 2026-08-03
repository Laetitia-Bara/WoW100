import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/data/models/achievement_group_hierarchy.dart';
import 'package:wow100/data/models/tracking_category.dart';
import 'package:wow100/data/models/tracking_item.dart';
import 'package:wow100/data/models/wow_expansion.dart';
import 'package:wow100/data/repositories/planner_repository.dart';

const _vanillaGuildAchievementIds = {
  5037,
  5038,
  5039,
  5040,
  5041,
  5042,
  5043,
  5044,
  5045,
  5046,
  5047,
  5048,
  5049,
  5050,
  5051,
  5052,
  5053,
  5054,
  5055,
  5056,
  5057,
  5058,
  5059,
  7434,
};

const _worldEventCategoryIds = {
  155,
  156,
  158,
  159,
  160,
  161,
  162,
  163,
  187,
  14981,
  15101,
  15416,
  15454,
  15532,
  15545,
  15567,
  15574,
};

const _tbcArenaMountAchievementIds = {886, 887, 888, 2316};

const _extensionContentCategoryIds = {
  14941,
  15075,
  15222,
  15271,
  15301,
  15302,
  15303,
  15304,
  15307,
  15308,
  15411,
  15417,
  15426,
  15440,
  15441,
  15462,
  15546,
  15552,
  15605,
  15608,
  15610,
};

const _petBattleAchievementExpansionById = {
  6558: WowExpansion.mop,
  6559: WowExpansion.mop,
  6560: WowExpansion.mop,
  6585: WowExpansion.mop,
  6601: WowExpansion.mop,
  6602: WowExpansion.mop,
  6612: WowExpansion.mop,
  7498: WowExpansion.mop,
  7499: WowExpansion.mop,
  61041: WowExpansion.midnight,
  61042: WowExpansion.midnight,
  61043: WowExpansion.midnight,
  61044: WowExpansion.midnight,
  61045: WowExpansion.midnight,
  61046: WowExpansion.midnight,
  61047: WowExpansion.midnight,
  61048: WowExpansion.midnight,
  61049: WowExpansion.midnight,
  61050: WowExpansion.midnight,
  61051: WowExpansion.midnight,
};

const _extensionContentAchievementExpansionById = {
  12870: WowExpansion.bfa,
  12899: WowExpansion.bfa,
  17712: WowExpansion.dragonflight,
  17713: WowExpansion.dragonflight,
  17714: WowExpansion.dragonflight,
  17715: WowExpansion.dragonflight,
  17716: WowExpansion.dragonflight,
  17717: WowExpansion.dragonflight,
  17718: WowExpansion.dragonflight,
  17719: WowExpansion.dragonflight,
  17720: WowExpansion.dragonflight,
  17721: WowExpansion.dragonflight,
  17722: WowExpansion.dragonflight,
  17723: WowExpansion.dragonflight,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps Cataclysm Kalimdor achievements out of Vanilla', () async {
    final repository = JsonPlannerRepository();
    final cataclysmAchievementIds = {4827, 5453, 5868};

    final vanillaAchievements = await repository.getItems(
      WowExpansion.vanilla,
      category: TrackingCategory.achievements,
    );
    final vanillaIds = vanillaAchievements.map((item) => item.blizzardId);

    for (final achievementId in cataclysmAchievementIds) {
      expect(vanillaIds, isNot(contains(achievementId)));
    }

    final cataclysmAchievements = await repository.getItems(
      WowExpansion.cataclysm,
      category: TrackingCategory.achievements,
    );

    for (final achievementId in cataclysmAchievementIds) {
      final achievement = cataclysmAchievements.singleWhere(
        (item) => item.blizzardId == achievementId,
      );

      expect(achievement.expansion, WowExpansion.cataclysm);
    }
  });

  test('keeps global exploration achievement out of Vanilla', () async {
    final repository = JsonPlannerRepository();

    final vanillaAchievements = await repository.getItems(
      WowExpansion.vanilla,
      category: TrackingCategory.achievements,
    );
    expect(
      vanillaAchievements.map((item) => item.blizzardId),
      isNot(contains(46)),
    );

    final allAchievements = await repository.getItems(
      WowExpansion.allAchievements,
      category: TrackingCategory.achievements,
    );
    final universeExplorer = allAchievements.singleWhere(
      (item) => item.blizzardId == 46,
    );

    expect(universeExplorer.expansion, WowExpansion.allAchievements);
  });

  test('keeps Vanilla guild achievements in the global guild group', () async {
    final repository = JsonPlannerRepository();

    final vanillaAchievements = await repository.getItems(
      WowExpansion.vanilla,
      category: TrackingCategory.achievements,
    );
    final vanillaIds = vanillaAchievements.map((item) => item.blizzardId);

    for (final achievementId in _vanillaGuildAchievementIds) {
      expect(vanillaIds, isNot(contains(achievementId)));
    }

    final allAchievements = await repository.getItems(
      WowExpansion.allAchievements,
      category: TrackingCategory.achievements,
    );
    final allById = {
      for (final item in allAchievements)
        if (item.blizzardId != null) item.blizzardId!: item,
    };

    for (final achievementId in _vanillaGuildAchievementIds) {
      final achievement = allById[achievementId];

      expect(achievement, isNotNull);
      expect(achievement!.expansion, WowExpansion.allAchievements);
      expect(achievement.instance, 'Guilde');
      expect(achievement.blizzardCategoryName, 'Guilde');
    }
  });

  test('keeps world event achievements out of expansion planners', () async {
    final repository = JsonPlannerRepository();
    const expansionPlanners = [
      WowExpansion.vanilla,
      WowExpansion.tbc,
      WowExpansion.wrath,
      WowExpansion.cataclysm,
      WowExpansion.mop,
      WowExpansion.wod,
      WowExpansion.legion,
      WowExpansion.bfa,
      WowExpansion.shadowlands,
      WowExpansion.dragonflight,
      WowExpansion.warWithin,
      WowExpansion.midnight,
    ];

    for (final expansion in expansionPlanners) {
      final achievements = await repository.getItems(
        expansion,
        category: TrackingCategory.achievements,
      );
      final eventAchievements = achievements.where(
        (item) => _worldEventCategoryIds.contains(item.blizzardCategoryId),
      );

      expect(
        eventAchievements,
        isEmpty,
        reason: '${expansion.name} should not contain world event HFs',
      );
    }
  });

  test('routes TBC arena season mount achievements to PvP groups', () async {
    final repository = JsonPlannerRepository();

    final achievements = await repository.getItems(
      WowExpansion.tbc,
      category: TrackingCategory.achievements,
    );
    final achievementsById = {
      for (final item in achievements) item.blizzardId: item,
    };

    for (final achievementId in _tbcArenaMountAchievementIds) {
      final achievement = achievementsById[achievementId];

      expect(achievement, isNotNull);
      expect(
        AchievementGroupHierarchy.labelFor(achievement!),
        'Joueur contre Joueur > Arène',
      );
    }
  });

  test(
    'classifies Vanilla-listed pet battle achievements by Wowhead patch',
    () async {
      final repository = JsonPlannerRepository();

      final vanillaAchievements = await repository.getItems(
        WowExpansion.vanilla,
        category: TrackingCategory.achievements,
      );
      final vanillaIds = vanillaAchievements.map((item) => item.blizzardId);

      for (final achievementId in _petBattleAchievementExpansionById.keys) {
        expect(vanillaIds, isNot(contains(achievementId)));
      }

      final achievementsByExpansion = <WowExpansion, Map<int, TrackingItem>>{};
      for (final expansion in {WowExpansion.mop, WowExpansion.midnight}) {
        final achievements = await repository.getItems(
          expansion,
          category: TrackingCategory.achievements,
        );
        achievementsByExpansion[expansion] = {
          for (final item in achievements)
            if (item.blizzardId != null) item.blizzardId!: item,
        };
      }

      for (final entry in _petBattleAchievementExpansionById.entries) {
        final achievement = achievementsByExpansion[entry.value]?[entry.key];

        expect(achievement, isNotNull);
        expect(achievement!.expansion, entry.value);
      }
    },
  );

  test(
    'classifies Vanilla-listed extension content by Wowhead expansion',
    () async {
      final repository = JsonPlannerRepository();

      final vanillaAchievements = await repository.getItems(
        WowExpansion.vanilla,
        category: TrackingCategory.achievements,
      );
      final vanillaIds = vanillaAchievements.map((item) => item.blizzardId);

      for (final achievementId
          in _extensionContentAchievementExpansionById.keys) {
        expect(vanillaIds, isNot(contains(achievementId)));
      }
      final vanillaExtensionContentAchievements = vanillaAchievements.where(
        (item) =>
            _extensionContentCategoryIds.contains(item.blizzardCategoryId),
      );

      expect(vanillaExtensionContentAchievements, isEmpty);

      final achievementsByExpansion = <WowExpansion, Map<int, TrackingItem>>{};
      for (final expansion in {WowExpansion.bfa, WowExpansion.dragonflight}) {
        final achievements = await repository.getItems(
          expansion,
          category: TrackingCategory.achievements,
        );
        achievementsByExpansion[expansion] = {
          for (final item in achievements)
            if (item.blizzardId != null) item.blizzardId!: item,
        };
      }

      for (final entry in _extensionContentAchievementExpansionById.entries) {
        final achievement = achievementsByExpansion[entry.value]?[entry.key];

        expect(achievement, isNotNull);
        expect(achievement!.expansion, entry.value);
      }
    },
  );
}
