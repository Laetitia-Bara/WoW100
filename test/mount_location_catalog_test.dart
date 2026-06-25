import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/data/models/wow_expansion.dart';
import 'package:wow100/data/sources/json_planner_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'mounts resolve canonical world, continent, region and subzone',
    () async {
      final items = await JsonPlannerSource().loadMountItems(
        WowExpansion.allMounts,
      );

      expect(items, hasLength(1608));

      final thrayir = items.singleWhere((item) => item.blizzardId == 2322);
      expect(thrayir.locationRef, 'wowhead-zone:10416');
      expect(thrayir.world, 'Azeroth');
      expect(thrayir.region, 'Khaz Algar');
      expect(thrayir.zone, 'Île aux Sirènes');
      expect(thrayir.subzone, isEmpty);

      final deepSeaCreature = items.singleWhere(
        (item) => item.blizzardId == 838,
      );
      expect(deepSeaCreature.world, 'Azeroth');
      expect(deepSeaCreature.region, 'Îles Brisées');
      expect(deepSeaCreature.zone, 'Azsuna');
      expect(deepSeaCreature.subzone, 'Œil d’Azshara');

      final prideOfTheHunt = items.singleWhere(
        (item) => item.blizzardId == 2769,
      );
      expect(prideOfTheHunt.locationRef, 'wowhead-zone:15969');
      expect(prideOfTheHunt.world, 'Azeroth');
      expect(prideOfTheHunt.region, "Quel'Thalas");
      expect(prideOfTheHunt.zone, contains('Argent'));
      expect(prideOfTheHunt.subzone, isEmpty);
    },
  );
}
