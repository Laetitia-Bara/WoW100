import '../models/tracking_item.dart';
import '../models/tracking_category.dart';
import '../models/wow_expansion.dart';
import '../sources/json_planner_source.dart';

abstract class PlannerRepository {
  Future<List<TrackingItem>> getItems(
    WowExpansion expansion, {
    TrackingCategory? category,
  });
}

class JsonPlannerRepository implements PlannerRepository {
  final JsonPlannerSource _source = JsonPlannerSource();

  @override
  Future<List<TrackingItem>> getItems(
    WowExpansion expansion, {
    TrackingCategory? category,
  }) async {
    if (category == TrackingCategory.achievements ||
        expansion == WowExpansion.allAchievements) {
      return _source.loadAchievementItems(expansion);
    }

    if (category == TrackingCategory.pets ||
        expansion == WowExpansion.allPets) {
      return _source.loadPetItems(expansion);
    }

    if (category == null && _isExtensionExpansion(expansion)) {
      final items = [
        ...await _source.loadAchievementItems(expansion),
        ...await _source.loadMountItems(expansion),
        ...await _source.loadPetItems(expansion),
      ];

      items.sort((a, b) {
        final categoryCompare = a.category.index.compareTo(b.category.index);
        if (categoryCompare != 0) return categoryCompare;

        final instanceCompare = a.instance.compareTo(b.instance);
        if (instanceCompare != 0) return instanceCompare;

        return a.name.compareTo(b.name);
      });

      return items;
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

  bool _isExtensionExpansion(WowExpansion expansion) {
    return switch (expansion) {
      WowExpansion.vanilla ||
      WowExpansion.tbc ||
      WowExpansion.wrath ||
      WowExpansion.cataclysm ||
      WowExpansion.mop ||
      WowExpansion.wod ||
      WowExpansion.legion ||
      WowExpansion.bfa ||
      WowExpansion.shadowlands ||
      WowExpansion.dragonflight ||
      WowExpansion.warWithin ||
      WowExpansion.midnight => true,
      _ => false,
    };
  }
}
