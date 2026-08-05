import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/core/services/route_planner_service.dart';
import 'package:wow100/data/models/tracking_category.dart';
import 'package:wow100/data/models/tracking_item.dart';
import 'package:wow100/data/models/wow_expansion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adds condition tags to objective route steps', () async {
    final service = RoutePlannerService();

    final plan = await service.buildPlan(
      faction: 'Horde',
      items: [
        _item(
          id: 'pet_condition',
          name: 'Mascotte conditionnelle',
          condition: 'Tauren requis',
        ),
      ],
    );
    final objective = plan.steps.singleWhere(
      (step) => step.kind == RouteStepKind.objective,
    );

    expect(objective.tags, contains('Condition : Tauren requis'));
  });

  test('keeps objective route steps clean without condition', () async {
    final service = RoutePlannerService();

    final plan = await service.buildPlan(
      faction: 'Horde',
      items: [_item(id: 'pet_no_condition', name: 'Mascotte simple')],
    );
    final objective = plan.steps.singleWhere(
      (step) => step.kind == RouteStepKind.objective,
    );

    expect(
      objective.tags.where((tag) => tag.startsWith('Condition :')),
      isEmpty,
    );
  });
}

TrackingItem _item({
  required String id,
  required String name,
  String condition = '',
}) {
  return TrackingItem(
    id: id,
    name: name,
    category: TrackingCategory.pets,
    expansion: WowExpansion.vanilla,
    zone: 'Orgrimmar',
    region: 'Kalimdor',
    world: 'Azeroth',
    instance: 'Vendeur',
    source: 'Vendeur',
    groupRequired: false,
    weeklyLockout: false,
    obtained: false,
    condition: condition,
    blizzardId: 1,
    boss: '',
  );
}
