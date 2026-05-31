import 'tracking_category.dart';
import 'wow_expansion.dart';

class TrackingItem {
  final String id;

  /// Nom affiché
  final String name;

  /// Monture, HF, Mascotte...
  final TrackingCategory category;

  /// Extension associée
  final WowExpansion expansion;

  /// Zone générale
  final String zone;

  /// Donjon / Raid / Zone précise
  final String instance;

  /// Boss ou source
  final String source;

  /// ID Wowhead (objet)
  final int? wowheadItemId;

  /// ID Wowhead (haut-fait)
  final int? wowheadAchievementId;

  /// Nécessite un groupe
  final bool groupRequired;

  /// Reset hebdomadaire
  final bool weeklyLockout;

  /// Obtenu par le joueur
  final bool obtained;

  const TrackingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.expansion,
    required this.zone,
    required this.instance,
    required this.source,
    this.wowheadItemId,
    this.wowheadAchievementId,
    required this.groupRequired,
    required this.weeklyLockout,
    required this.obtained,
  });

  TrackingItem copyWith({bool? obtained}) {
    return TrackingItem(
      id: id,
      name: name,
      category: category,
      expansion: expansion,
      zone: zone,
      instance: instance,
      source: source,
      wowheadItemId: wowheadItemId,
      wowheadAchievementId: wowheadAchievementId,
      groupRequired: groupRequired,
      weeklyLockout: weeklyLockout,
      obtained: obtained ?? this.obtained,
    );
  }
}
