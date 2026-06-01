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
    switch (expansion) {
      case WowExpansion.wrath:
        return _source.loadWrathMounts();
      default:
        return [];
    }
  }
}
