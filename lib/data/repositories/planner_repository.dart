import '../models/tracking_item.dart';
import '../models/wow_expansion.dart';
import '../sources/mock_planner_source.dart';

abstract class PlannerRepository {
  Future<List<TrackingItem>> getItems(WowExpansion expansion);
}

class MockPlannerRepository implements PlannerRepository {
  @override
  Future<List<TrackingItem>> getItems(WowExpansion expansion) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockPlannerSource.getItems(expansion);
  }
}
