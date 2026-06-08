import 'package:flutter/foundation.dart';

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

  /// N'est plus possible a obtenir en jeu.
  final bool unavailable;

  final int? blizzardId;

  final String boss;

  final String externalUrl;

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
    this.unavailable = false,
    this.blizzardId,
    required this.boss,
    this.externalUrl = '',
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
      unavailable: unavailable,
      blizzardId: blizzardId,
      boss: boss,
      externalUrl: externalUrl,
    );
  }

  factory TrackingItem.fromJson(Map<String, dynamic> json) {
    debugPrint('EXPANSION JSON = ${json['expansion']}');
    return TrackingItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: TrackingCategoryParser.fromJson(json['category']),
      expansion: WowExpansionParser.fromJson(json['expansion']),
      zone: json['zone'] ?? '',
      instance: json['instance'] ?? '',
      source: json['source'] ?? '',
      wowheadItemId: json['wowheadItemId'],
      wowheadAchievementId: json['wowheadAchievementId'],
      groupRequired: json['groupRequired'] ?? false,
      weeklyLockout: json['weeklyLockout'] ?? false,
      obtained: false,
      unavailable: json['unavailable'] ?? _looksUnavailable(json),
      blizzardId: json['blizzardId'],
      boss: json['boss'] ?? '',
      externalUrl: json['externalUrl'] ?? json['mamytwinkUrl'] ?? '',
    );
  }

  static bool _looksUnavailable(Map<String, dynamic> json) {
    final values = [
      json['availability'],
      json['status'],
      json['difficulty'],
      json['categoryType'],
      json['instance'],
      json['source'],
      json['sourceName'],
      json['note'],
    ];

    return values.whereType<String>().any((value) {
      final normalized = _normalizeAvailabilityText(value);

      return normalized.contains('indisponible') ||
          normalized.contains('plus accessible') ||
          normalized.contains('plus disponible') ||
          RegExp(
            r'\b(retire|retiree|retirees|retired)\b',
          ).hasMatch(normalized) ||
          normalized.contains('removed') ||
          normalized.contains('unavailable');
    });
  }

  static String _normalizeAvailabilityText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r"['’´`\-/]"), ' ')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
