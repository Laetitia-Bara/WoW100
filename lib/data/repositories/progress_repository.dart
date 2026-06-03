import '../../core/services/battle_net_token_service.dart';
import '../../core/services/local_check_service.dart';
import '../models/expansion_progress.dart';
import '../models/tracking_category.dart';
import '../models/wow_expansion.dart';
import '../repositories/battle_net_repository.dart';
import '../sources/json_planner_source.dart';
import '../../core/services/selected_character_service.dart';

abstract class ProgressRepository {
  Future<List<ExpansionProgress>> getProgress();
}

class JsonProgressRepository implements ProgressRepository {
  final JsonPlannerSource _source = JsonPlannerSource();
  final LocalCheckService _localCheckService = LocalCheckService();
  final BattleNetTokenService _tokenService = BattleNetTokenService();
  final BattleNetRepository _battleNetRepository = BattleNetRepository();
  final SelectedCharacterService _selectedCharacterService =
      SelectedCharacterService();

  @override
  Future<List<ExpansionProgress>> getProgress() async {
    final wrathItems = [
      ...await _source.loadItemsFromAsset(
        'assets/data/mounts/wrath_mounts.json',
      ),
      ...await _source.loadItemsFromAsset('assets/data/pets/wrath_pets.json'),
      ...await _source.loadItemsFromAsset(
        'assets/data/achievements/wrath_achievements.json',
      ),
    ];

    final token = await _tokenService.loadToken();

    final ownedMountIds = <int>{};
    final ownedPetIds = <int>{};
    final ownedAchievementIds = <int>{};

    if (token != null) {
      final mounts = await _battleNetRepository.getMounts(token);
      ownedMountIds.addAll(mounts.map((mount) => mount.id));

      final pets = await _battleNetRepository.getPets(token);
      ownedPetIds.addAll(pets.map((pet) => pet.id));

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
    }

    final completed = <TrackingCategory, int>{};
    final total = <TrackingCategory, int>{};

    for (final item in wrathItems) {
      total[item.category] = (total[item.category] ?? 0) + 1;

      final checked = await _localCheckService.isChecked(item.id);

      final ownedMount =
          item.category == TrackingCategory.mounts &&
          item.blizzardId != null &&
          ownedMountIds.contains(item.blizzardId);

      final ownedPet =
          item.category == TrackingCategory.pets &&
          item.blizzardId != null &&
          ownedPetIds.contains(item.blizzardId);

      final ownedAchievement =
          item.category == TrackingCategory.achievements &&
          item.blizzardId != null &&
          ownedAchievementIds.contains(item.blizzardId);

      if (checked || ownedMount || ownedPet || ownedAchievement) {
        completed[item.category] = (completed[item.category] ?? 0) + 1;
      }
    }

    return [
      ExpansionProgress(
        expansion: WowExpansion.total,
        completed: completed,
        total: total,
      ),
      ExpansionProgress(
        expansion: WowExpansion.wrath,
        completed: completed,
        total: total,
      ),
    ];
  }
}
