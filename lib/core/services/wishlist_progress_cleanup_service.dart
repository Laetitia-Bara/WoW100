import '../../data/models/tracking_item.dart';
import 'collection_ownership_service.dart';
import 'saved_farm_route_service.dart';
import 'solo_planner_service.dart';

class WishlistProgressCleanupResult {
  const WishlistProgressCleanupResult({
    required this.selectedItemIds,
    required this.removedItemIds,
  });

  final Set<String> selectedItemIds;
  final Set<String> removedItemIds;

  bool get removedAny => removedItemIds.isNotEmpty;
}

class WishlistProgressCleanupService {
  WishlistProgressCleanupService({
    SoloPlannerService? soloPlannerService,
    SavedFarmRouteService? savedFarmRouteService,
  }) : _soloPlannerService = soloPlannerService ?? SoloPlannerService(),
       _savedFarmRouteService =
           savedFarmRouteService ?? SavedFarmRouteService();

  final SoloPlannerService _soloPlannerService;
  final SavedFarmRouteService _savedFarmRouteService;

  Future<WishlistProgressCleanupResult> removeObtainedItems({
    required Iterable<TrackingItem> items,
    required CollectionOwnershipSnapshot ownership,
  }) async {
    final selectedItemIds = await _soloPlannerService.selectedItemIds();
    final removedItemIds = items
        .where((item) => selectedItemIds.contains(item.id))
        .where(ownership.isOwned)
        .map((item) => item.id)
        .toSet();

    if (removedItemIds.isEmpty) {
      return WishlistProgressCleanupResult(
        selectedItemIds: selectedItemIds,
        removedItemIds: const <String>{},
      );
    }

    await _soloPlannerService.clearSelected(removedItemIds);
    await _savedFarmRouteService.removeItemsFromMyRoutes(removedItemIds);

    return WishlistProgressCleanupResult(
      selectedItemIds: await _soloPlannerService.selectedItemIds(),
      removedItemIds: removedItemIds,
    );
  }
}
