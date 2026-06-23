import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/data/models/tracking_item.dart';
import 'package:wow100/data/models/wow_region_filter.dart';
import 'package:wow100/data/models/wow_expansion.dart';
import 'package:wow100/data/repositories/planner_repository.dart';
import 'package:wow100/data/sources/wow_expansion_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('does not infer an exploration zone from the achievement text', () {
    final item = TrackingItem.fromJson({
      'id': 'achievement_846',
      'name': 'Exploration des Mille pointes',
      'category': 'achievements',
      'expansion': 'vanilla',
      'zone': 'Kalimdor',
      'instance': 'Kalimdor',
      'source':
          'Explorer les Mille pointes et révéler les zones voilées de la carte du monde.',
      'groupRequired': false,
      'weeklyLockout': false,
    });

    final filter = WowRegionFilter.fromItem(item);

    expect(item.zone, TrackingItem.unknownZone);
    expect(item.region, TrackingItem.unknownZone);
    expect(filter?.zone, TrackingItem.unknownZone);
    expect(filter?.region, TrackingItem.unknownZone);
  });

  test('does not infer a world region from the achievement text', () {
    final item = TrackingItem.fromJson({
      'id': 'achievement_43',
      'name': 'Exploration de Kalimdor',
      'category': 'achievements',
      'expansion': 'vanilla',
      'zone': 'Exploration',
      'instance': 'Exploration',
      'source': 'Explorer les régions de Kalimdor.',
      'groupRequired': false,
      'weeklyLockout': false,
    });

    final filter = WowRegionFilter.fromItem(item);

    expect(item.zone, TrackingItem.unknownZone);
    expect(item.region, TrackingItem.unknownZone);
    expect(filter?.zone, TrackingItem.unknownZone);
    expect(filter?.region, TrackingItem.unknownZone);
  });

  test('keeps Eastern Kingdoms zones under their continent', () {
    final item = TrackingItem.fromJson({
      'id': 'mount_13335',
      'name': 'Deathcharger',
      'category': 'mounts',
      'expansion': 'vanilla',
      'zone': 'Maleterres de l\'Est',
      'instance': 'Stratholme',
      'source': 'Baron Rivendare',
      'groupRequired': true,
      'weeklyLockout': false,
    });

    final filter = WowRegionFilter.fromItem(item);

    expect(filter?.zone, 'Maleterres de l\'Est');
    expect(filter?.region, 'Royaumes de l\'Est');
  });

  test('real Vanilla data sends non-official locations to Sans zone', () async {
    final repository = JsonPlannerRepository();
    final items = await repository.getItems(WowExpansion.vanilla);
    final filters = items
        .map(WowRegionFilter.fromItem)
        .whereType<WowRegionFilter>()
        .toList();

    expect(
      filters.any((filter) => filter.region == TrackingItem.unknownZone),
      isTrue,
    );
    expect(filters.any((filter) => filter.zone == 's Mille pointes'), isFalse);
    expect(filters.any((filter) => filter.zone == 'Mille pointes'), isFalse);
    expect(filters.any((filter) => filter.zone == 'Kalimdor'), isFalse);
  });

  test(
    'region filters only expose known zones, catalog locations or Sans zone',
    () async {
      final repository = JsonPlannerRepository();

      for (final info in WowExpansionCatalog.all) {
        final expansion = info.expansion;
        if (expansion == WowExpansion.total) continue;

        final items = await repository.getItems(expansion);
        for (final item in items) {
          final filter = WowRegionFilter.fromItem(item);
          if (filter == null) continue;
          expect(
            filter.zone == TrackingItem.unknownZone ||
                TrackingItem.isKnownWorldZone(filter.zone) ||
                item.locationRef.isNotEmpty,
            isTrue,
            reason: '${info.name}: ${filter.zone}',
          );
        }
      }
    },
  );
}
