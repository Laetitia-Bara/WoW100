import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wow100/core/services/collection_ownership_service.dart';
import 'package:wow100/core/services/solo_planner_service.dart';
import 'package:wow100/core/services/wishlist_progress_cleanup_service.dart';
import 'package:wow100/data/models/tracking_category.dart';
import 'package:wow100/data/models/tracking_item.dart';
import 'package:wow100/data/models/wow_expansion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'removes Battle.net-owned items from wishlist and today route',
    () async {
      final soloPlannerService = SoloPlannerService();
      final cleanupService = WishlistProgressCleanupService(
        soloPlannerService: soloPlannerService,
      );

      await soloPlannerService.setSelected('mount-1', true);
      await soloPlannerService.setSelected('mount-2', true);
      await soloPlannerService.setAllTodaySelected([
        'mount-1',
        'mount-2',
      ], loadedRouteName: 'Farm du soir');

      final result = await cleanupService.removeObtainedItems(
        items: [
          _mountItem(id: 'mount-1', blizzardId: 42),
          _mountItem(id: 'mount-2', blizzardId: 77),
        ],
        ownership: CollectionOwnershipSnapshot(ownedMountIds: [42]),
      );

      expect(result.removedItemIds, {'mount-1'});
      expect(result.selectedItemIds, {'mount-2'});
      expect(await soloPlannerService.selectedItemIds(), {'mount-2'});
      expect(await soloPlannerService.selectedTodayItemIds({'mount-2'}), {
        'mount-2',
      });
      expect(await soloPlannerService.loadedRouteName(), isNull);
    },
  );
}

TrackingItem _mountItem({required String id, required int blizzardId}) {
  return TrackingItem(
    id: id,
    name: id,
    category: TrackingCategory.mounts,
    expansion: WowExpansion.tbc,
    zone: TrackingItem.unknownZone,
    instance: 'Divers',
    source: 'Test',
    groupRequired: false,
    weeklyLockout: false,
    obtained: false,
    blizzardId: blizzardId,
    boss: '',
  );
}
