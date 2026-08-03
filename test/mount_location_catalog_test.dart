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
      expect(thrayir.difficulty, 'Facile');

      final deepSeaCreature = items.singleWhere(
        (item) => item.blizzardId == 838,
      );
      expect(deepSeaCreature.world, 'Azeroth');
      expect(deepSeaCreature.region, 'Îles Brisées');
      expect(deepSeaCreature.zone, 'Azsuna');
      expect(deepSeaCreature.subzone, 'Œil d’Azshara');
      expect(deepSeaCreature.difficulty, 'Moyen');

      final prideOfTheHunt = items.singleWhere(
        (item) => item.blizzardId == 2769,
      );
      expect(prideOfTheHunt.locationRef, 'wowhead-zone:15969');
      expect(prideOfTheHunt.world, 'Azeroth');
      expect(prideOfTheHunt.region, "Quel'Thalas");
      expect(prideOfTheHunt.zone, contains('Argent'));
      expect(prideOfTheHunt.subzone, isEmpty);

      final bayHorse = items.singleWhere((item) => item.blizzardId == 6);
      expect(bayHorse.locationRef, 'wowhead-zone:11');
      expect(bayHorse.source, 'Vendeur');
      expect(bayHorse.difficulty, 'Facile');

      final deathcharger = items.singleWhere((item) => item.blizzardId == 69);
      expect(deathcharger.locationRef, 'wowhead-zone:2017');
      expect(deathcharger.source, 'Butin');
      expect(deathcharger.subzone, 'Stratholme');

      final ashesOfAlar = items.singleWhere((item) => item.blizzardId == 183);
      expect(ashesOfAlar.locationRef, 'wowhead-zone:3523');
      expect(ashesOfAlar.world, 'Outreterre');
      expect(ashesOfAlar.region, 'Outreterre');
      expect(ashesOfAlar.zone, 'Raz-de-Néant');
      expect(ashesOfAlar.instance, 'Butin');
      expect(ashesOfAlar.displayInstance, 'L’Œil');
      expect(ashesOfAlar.source, 'Butin');
      expect(ashesOfAlar.difficulty, 'Difficile');
      expect(ashesOfAlar.dropRate, '1.70');
      expect(ashesOfAlar.tags, ['Raid']);
      expect(ashesOfAlar.frequencyLabel, 'Hebdomadaire');

      final vanillaItems = await JsonPlannerSource().loadMountItems(
        WowExpansion.vanilla,
      );
      final vanillaDeathcharger = vanillaItems.singleWhere(
        (item) => item.blizzardId == 69,
      );
      expect(vanillaDeathcharger.instance, 'Butin');
      expect(vanillaDeathcharger.subzone, 'Stratholme');

      final allBrewfestMount = items.singleWhere(
        (item) => item.blizzardId == 202,
      );
      expect(allBrewfestMount.source, 'Fête des brasseurs');

      final tbcItems = await JsonPlannerSource().loadMountItems(
        WowExpansion.tbc,
      );
      expect(
        tbcItems.where(
          (item) =>
              item.source == 'Fête des brasseurs' ||
              item.name.contains('fête des Brasseurs'),
        ),
        isEmpty,
      );
    },
  );
}
