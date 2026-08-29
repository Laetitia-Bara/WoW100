import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/data/models/tracking_category.dart';
import 'package:wow100/data/models/wow_expansion.dart';
import 'package:wow100/data/repositories/planner_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('marks Snowy Owl as seasonal', () async {
    final repository = JsonPlannerRepository();

    final vanillaPets = await repository.getItems(
      WowExpansion.vanilla,
      category: TrackingCategory.pets,
    );
    final snowyOwl = vanillaPets.singleWhere((item) => item.blizzardId == 69);

    expect(snowyOwl.name, 'Chouette blanche');
    expect(snowyOwl.tags, contains('Saisonnier'));
  });

  test('keeps world event pets out of expansion catalogs', () async {
    final repository = JsonPlannerRepository();

    final vanillaPets = await repository.getItems(
      WowExpansion.vanilla,
      category: TrackingCategory.pets,
    );

    expect(
      vanillaPets.where(
        (item) =>
            item.instance == 'Événement mondial' ||
            item.instance == 'Promotion Blizzard',
      ),
      isEmpty,
    );
    expect(vanillaPets.any((item) => item.blizzardId == 69), isTrue);

    final allPets = await repository.getItems(WowExpansion.allPets);
    expect(allPets.any((item) => item.blizzardId == 92), isTrue);
  });
}
