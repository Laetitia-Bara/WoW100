abstract class ProgressRepository {
  Future<List<TrackingItem>> getItems(WowExpansion expansion);
}
