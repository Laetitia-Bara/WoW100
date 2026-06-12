import 'package:wow100/data/models/tracking_item.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/battle_net_token_service.dart';
import '../../core/services/local_check_service.dart';
import '../../core/services/selected_character_service.dart';
import '../models/expansion_progress.dart';
import '../models/tracking_category.dart';
import '../models/wow_expansion.dart';
import '../repositories/battle_net_repository.dart';
import '../sources/json_planner_source.dart';

abstract class ProgressRepository {
  Future<List<ExpansionProgress>> getProgress();
}

class JsonProgressRepository implements ProgressRepository {
  final JsonPlannerSource _source = JsonPlannerSource();
  final LocalCheckService _localCheckService = LocalCheckService();
  final BattleNetTokenService _tokenService = BattleNetTokenService();
  final SelectedCharacterService _selectedCharacterService =
      SelectedCharacterService();
  final BattleNetRepository _battleNetRepository = BattleNetRepository();

  @override
  Future<List<ExpansionProgress>> getProgress() async {
    final expansions = [
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

    final allMountItems = await _source.loadMountItems(WowExpansion.allMounts);
    final allPetItems = await _source.loadPetItems(WowExpansion.allPets);
    final allAchievementItems = await _source.loadAchievementItems(
      WowExpansion.allAchievements,
    );

    final token = await _tokenService.loadToken();

    final ownedMountIds = <int>{};
    final ownedPetIds = <int>{};
    final ownedAchievementIds = <int>{};

    if (token != null) {
      try {
        final mounts = await _battleNetRepository.getMounts(token);
        ownedMountIds.addAll(mounts.map((mount) => mount.id));
      } catch (e, stack) {
        debugPrint('BATTLE.NET MOUNTS ERROR: $e');
        debugPrint('$stack');
      }

      try {
        final pets = await _battleNetRepository.getPets(token);
        ownedPetIds.addAll(pets.map((pet) => pet.id));
      } catch (e, stack) {
        debugPrint('BATTLE.NET PETS ERROR: $e');
        debugPrint('$stack');
      }

      try {
        final character = await _selectedCharacterService.loadCharacter();

        if (character != null) {
          final achievements = await _battleNetRepository.getAchievements(
            token,
            character.realmSlug,
            character.name,
          );
          ownedAchievementIds.addAll(
            achievements.map((achievement) => achievement.id),
          );
        }
      } catch (e, stack) {
        debugPrint('BATTLE.NET ACHIEVEMENTS ERROR: $e');
        debugPrint('$stack');
      }
    }

    final progresses = <ExpansionProgress>[];

    for (final expansion in expansions) {
      final expansionItems = allMountItems
          .where((item) => item.expansion == expansion)
          .toList();
      final expansionPetItems = allPetItems
          .where((item) => item.expansion == expansion)
          .toList();
      final expansionAchievementItems = allAchievementItems
          .where((item) => item.expansion == expansion)
          .toList();

      progresses.add(
        await _buildProgress(
          expansion,
          [
            ...expansionItems,
            ...expansionPetItems,
            ...expansionAchievementItems,
          ],
          ownedMountIds,
          ownedPetIds,
          ownedAchievementIds,
        ),
      );
    }

    return [
      await _buildProgress(
        WowExpansion.total,
        [...allMountItems, ...allPetItems, ...allAchievementItems],
        ownedMountIds,
        ownedPetIds,
        ownedAchievementIds,
      ),
      ...progresses,
    ];
  }

  Future<ExpansionProgress> _buildProgress(
    WowExpansion expansion,
    List<TrackingItem> items,
    Set<int> ownedMountIds,
    Set<int> ownedPetIds,
    Set<int> ownedAchievementIds,
  ) async {
    var completedAchievements = 0;
    var completedMounts = 0;
    var completedPets = 0;
    var totalAchievements = 0;
    var totalMounts = 0;
    var totalPets = 0;
    var completedObtainableAchievements = 0;
    var completedObtainableMounts = 0;
    var completedObtainablePets = 0;
    var obtainableAchievements = 0;
    var obtainableMounts = 0;
    var obtainablePets = 0;

    for (final item in items) {
      final checked = await _localCheckService.isChecked(item.id);
      final owned =
          item.blizzardId != null &&
          ((item.category == TrackingCategory.mounts &&
                  ownedMountIds.contains(item.blizzardId)) ||
              (item.category == TrackingCategory.pets &&
                  ownedPetIds.contains(item.blizzardId)) ||
              (item.category == TrackingCategory.achievements &&
                  ownedAchievementIds.contains(item.blizzardId)));

      if (item.category == TrackingCategory.achievements) {
        totalAchievements += 1;
        if (!item.unavailable) obtainableAchievements += 1;
      } else if (item.category == TrackingCategory.mounts) {
        totalMounts += 1;
        if (!item.unavailable) obtainableMounts += 1;
      } else if (item.category == TrackingCategory.pets) {
        totalPets += 1;
        if (!item.unavailable) obtainablePets += 1;
      }

      if ((checked || owned) &&
          item.category == TrackingCategory.achievements) {
        completedAchievements += 1;
        if (!item.unavailable) completedObtainableAchievements += 1;
      } else if ((checked || owned) &&
          item.category == TrackingCategory.mounts) {
        completedMounts += 1;
        if (!item.unavailable) completedObtainableMounts += 1;
      } else if ((checked || owned) && item.category == TrackingCategory.pets) {
        completedPets += 1;
        if (!item.unavailable) completedObtainablePets += 1;
      }
    }

    return ExpansionProgress(
      expansion: expansion,
      completed: {
        TrackingCategory.achievements: completedAchievements,
        TrackingCategory.mounts: completedMounts,
        TrackingCategory.pets: completedPets,
      },
      total: {
        TrackingCategory.achievements: totalAchievements,
        TrackingCategory.mounts: totalMounts,
        TrackingCategory.pets: totalPets,
      },
      completedObtainable: {
        TrackingCategory.achievements: completedObtainableAchievements,
        TrackingCategory.mounts: completedObtainableMounts,
        TrackingCategory.pets: completedObtainablePets,
      },
      obtainableTotal: {
        TrackingCategory.achievements: obtainableAchievements,
        TrackingCategory.mounts: obtainableMounts,
        TrackingCategory.pets: obtainablePets,
      },
    );
  }
}
