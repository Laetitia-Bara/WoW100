import '../models/tracking_item.dart';
import '../models/tracking_category.dart';
import '../models/wow_expansion.dart';
import '../sources/json_planner_source.dart';

abstract class PlannerRepository {
  Future<List<TrackingItem>> getItems(
    WowExpansion expansion, {
    TrackingCategory category = TrackingCategory.mounts,
  });
}

class JsonPlannerRepository implements PlannerRepository {
  final JsonPlannerSource _source = JsonPlannerSource();

  @override
  Future<List<TrackingItem>> getItems(
    WowExpansion expansion, {
    TrackingCategory category = TrackingCategory.mounts,
  }) async {
    if (category == TrackingCategory.achievements ||
        expansion == WowExpansion.allAchievements) {
      return _source.loadAchievementItems(expansion);
    }

    if (category == TrackingCategory.pets ||
        expansion == WowExpansion.allPets) {
      return _source.loadPetItems(expansion);
    }

    switch (expansion) {
      case WowExpansion.allAchievements:
        return _source.loadAchievementItems(WowExpansion.allAchievements);
      case WowExpansion.allMounts:
        return _source.loadMountItems(WowExpansion.allMounts);
      case WowExpansion.vanilla:
      case WowExpansion.tbc:
      case WowExpansion.wrath:
      case WowExpansion.cataclysm:
      case WowExpansion.mop:
      case WowExpansion.wod:
      case WowExpansion.legion:
      case WowExpansion.bfa:
      case WowExpansion.shadowlands:
      case WowExpansion.dragonflight:
      case WowExpansion.warWithin:
      case WowExpansion.midnight:
        return _source.loadMountItems(expansion);
      default:
        return [];
    }
  }
}
