import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/data/models/achievement_group_hierarchy.dart';

void main() {
  test('returns the root label for nested achievement groups', () {
    expect(AchievementGroupHierarchy.rootLabel('Quêtes > Kalimdor'), 'Quêtes');
    expect(
      AchievementGroupHierarchy.rootLabel('Événements mondiaux > Sanssaint'),
      'Événements mondiaux',
    );
  });

  test('keeps root-only achievement groups unchanged', () {
    expect(AchievementGroupHierarchy.rootLabel('Personnages'), 'Personnages');
  });
}
