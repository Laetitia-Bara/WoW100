import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/data/models/wow_expansion.dart';
import 'package:wow100/data/sources/json_planner_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JsonPlannerSource.loadMountItems', () {
    test(
      'uses Wowhead overrides before Mamytwink or manual metadata',
      () async {
        final source = JsonPlannerSource();

        final vanillaMounts = await source.loadMountItems(WowExpansion.vanilla);
        final mopMounts = await source.loadMountItems(WowExpansion.mop);
        final shadowlandsMounts = await source.loadMountItems(
          WowExpansion.shadowlands,
        );

        expect(
          vanillaMounts.map((item) => item.blizzardId),
          isNot(contains(110)),
        );
        expect(
          vanillaMounts.map((item) => item.blizzardId),
          isNot(contains(111)),
        );
        expect(
          vanillaMounts.map((item) => item.blizzardId),
          isNot(contains(1528)),
        );

        expect(
          mopMounts.singleWhere((item) => item.blizzardId == 110).source,
          'Marché noir',
        );
        expect(
          mopMounts.singleWhere((item) => item.blizzardId == 111).source,
          'Marché noir',
        );

        final zerethsteed = shadowlandsMounts.singleWhere(
          (item) => item.blizzardId == 1528,
        );
        expect(zerethsteed.name, 'Destrier de Zereth scindé');
        expect(zerethsteed.instance, 'Synthèse de protoforme');
      },
    );
  });
}
