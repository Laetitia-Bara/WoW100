import '../models/tracking_item.dart';
import '../models/wow_expansion.dart';
import '../sources/json_planner_source.dart';

abstract class PlannerRepository {
  Future<List<TrackingItem>> getItems(WowExpansion expansion);
}

class JsonPlannerRepository implements PlannerRepository {
  final JsonPlannerSource _source = JsonPlannerSource();

  @override
  Future<List<TrackingItem>> getItems(WowExpansion expansion) async {
    final assetPaths = <String>[];

    switch (expansion) {
      case WowExpansion.wrath:
        assetPaths.add('assets/data/mounts/wrath_mounts.json');
        break;
      default:
        return [];
    }

    final allItems = <TrackingItem>[];

    for (final path in assetPaths) {
      final items = await _source.loadItemsFromAsset(path);
      allItems.addAll(items);
    }

    return allItems;
  }
}
