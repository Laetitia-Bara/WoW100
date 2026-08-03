import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/data/models/achievement_group_hierarchy.dart';
import 'package:wow100/data/models/tracking_category.dart';
import 'package:wow100/data/models/tracking_item.dart';
import 'package:wow100/data/models/wow_expansion.dart';

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

  test('routes arena season mount achievements to PvP arena groups', () {
    const achievement = TrackingItem(
      id: 'achievement_2316',
      name: 'Drake du Néant brutal',
      category: TrackingCategory.achievements,
      expansion: WowExpansion.tbc,
      zone: 'Montures',
      instance: 'Montures',
      source:
          "Obtenir le drake du Néant brutal de la quatrième saison d'arène de The Burning Crusade.",
      blizzardCategoryId: 15269,
      blizzardCategoryName: 'Montures',
      groupRequired: false,
      weeklyLockout: false,
      obtained: false,
      boss: '',
    );

    expect(
      AchievementGroupHierarchy.labelFor(achievement),
      'Joueur contre Joueur > Arène',
    );
  });
}
