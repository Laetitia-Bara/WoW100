import 'package:flutter/foundation.dart';

import '../../data/models/achievement_faction_equivalents.dart';
import '../../data/models/tracking_category.dart';
import '../../data/models/tracking_item.dart';
import '../../data/models/wow_character.dart';
import '../../data/repositories/battle_net_repository.dart';
import 'battle_net_token_service.dart';

class CollectionOwnershipSnapshot {
  CollectionOwnershipSnapshot({
    Iterable<int> ownedMountIds = const <int>[],
    Iterable<int> ownedPetIds = const <int>[],
    Iterable<int> ownedAchievementIds = const <int>[],
  }) : ownedMountIds = Set.unmodifiable(ownedMountIds),
       ownedPetIds = Set.unmodifiable(ownedPetIds),
       ownedAchievementIds = Set.unmodifiable(
         AchievementFactionEquivalents.expand(ownedAchievementIds.toSet()),
       );

  final Set<int> ownedMountIds;
  final Set<int> ownedPetIds;
  final Set<int> ownedAchievementIds;

  bool isOwned(TrackingItem item) {
    final blizzardId = item.blizzardId;
    if (blizzardId == null) return false;

    return switch (item.category) {
      TrackingCategory.mounts => ownedMountIds.contains(blizzardId),
      TrackingCategory.pets => ownedPetIds.contains(blizzardId),
      TrackingCategory.achievements => ownedAchievementIds.contains(blizzardId),
      _ => false,
    };
  }

  List<TrackingItem> applyTo(Iterable<TrackingItem> items) {
    return [for (final item in items) item.copyWith(obtained: isOwned(item))];
  }
}

class CollectionOwnershipService {
  CollectionOwnershipService({
    BattleNetTokenService? tokenService,
    BattleNetRepository? battleNetRepository,
  }) : _tokenService = tokenService ?? BattleNetTokenService(),
       _battleNetRepository = battleNetRepository ?? BattleNetRepository();

  final BattleNetTokenService _tokenService;
  final BattleNetRepository _battleNetRepository;

  Future<CollectionOwnershipSnapshot?> load({
    required WowCharacter? character,
    bool tracksMounts = true,
    bool tracksPets = true,
    bool tracksAchievements = true,
  }) async {
    final token = await _tokenService.loadToken();
    if (token == null) return null;

    final ownedMountIds = <int>{};
    final ownedPetIds = <int>{};
    final ownedAchievementIds = <int>{};

    if (tracksAchievements) {
      try {
        final accountAchievements = await _battleNetRepository
            .getAccountAchievements(token);
        ownedAchievementIds.addAll(
          accountAchievements.map((achievement) => achievement.id),
        );
      } catch (e, stack) {
        debugPrint('BATTLE.NET ACCOUNT ACHIEVEMENTS ERROR: $e');
        debugPrint('$stack');
      }

      if (character != null) {
        try {
          final achievements = await _battleNetRepository.getAchievements(
            token,
            character.realmSlug,
            character.name,
          );
          ownedAchievementIds.addAll(
            achievements.map((achievement) => achievement.id),
          );
        } catch (e, stack) {
          debugPrint('BATTLE.NET CHARACTER ACHIEVEMENTS ERROR: $e');
          debugPrint('$stack');
        }
      }
    }

    if (tracksPets) {
      try {
        final pets = await _battleNetRepository.getPets(token);
        ownedPetIds.addAll(pets.map((pet) => pet.id));
      } catch (e, stack) {
        debugPrint('BATTLE.NET PETS ERROR: $e');
        debugPrint('$stack');
      }
    }

    if (tracksMounts) {
      try {
        final mounts = await _battleNetRepository.getMounts(token);
        ownedMountIds.addAll(mounts.map((mount) => mount.id));
      } catch (e, stack) {
        debugPrint('BATTLE.NET MOUNTS ERROR: $e');
        debugPrint('$stack');
      }
    }

    return CollectionOwnershipSnapshot(
      ownedMountIds: ownedMountIds,
      ownedPetIds: ownedPetIds,
      ownedAchievementIds: ownedAchievementIds,
    );
  }
}
