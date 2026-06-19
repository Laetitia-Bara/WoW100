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

  /// Region de monde / continent parent de la zone.
  final String region;

  /// Donjon / Raid / Zone précise
  final String instance;

  /// Boss ou source
  final String source;

  /// ID Wowhead (objet)
  final int? wowheadItemId;

  /// ID Wowhead (haut-fait)
  final int? wowheadAchievementId;

  final int? blizzardCategoryId;

  final String blizzardCategoryName;

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
    this.region = '',
    required this.instance,
    required this.source,
    this.wowheadItemId,
    this.wowheadAchievementId,
    this.blizzardCategoryId,
    this.blizzardCategoryName = '',
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
      region: region,
      instance: instance,
      source: source,
      wowheadItemId: wowheadItemId,
      wowheadAchievementId: wowheadAchievementId,
      blizzardCategoryId: blizzardCategoryId,
      blizzardCategoryName: blizzardCategoryName,
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
    final expansion = WowExpansionParser.fromJson(json['expansion']);
    final rawZone = _jsonString(json['zone']);
    final zone = _preferredZone(json, rawZone);

    return TrackingItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: TrackingCategoryParser.fromJson(json['category']),
      expansion: expansion,
      zone: zone,
      region: _preferredRegion(json, expansion, rawZone, zone),
      instance: json['instance'] ?? '',
      source: json['source'] ?? '',
      wowheadItemId: json['wowheadItemId'],
      wowheadAchievementId: json['wowheadAchievementId'],
      blizzardCategoryId: json['blizzardCategoryId'],
      blizzardCategoryName: json['blizzardCategoryName'] ?? '',
      groupRequired: json['groupRequired'] ?? false,
      weeklyLockout: json['weeklyLockout'] ?? false,
      obtained: false,
      unavailable: json['unavailable'] ?? _looksUnavailable(json),
      blizzardId: json['blizzardId'],
      boss: json['boss'] ?? '',
      externalUrl: json['externalUrl'] ?? json['mamytwinkUrl'] ?? '',
    );
  }

  static String _jsonString(dynamic value) {
    if (value is! String) return '';

    return value.trim();
  }

  static String _preferredZone(Map<String, dynamic> json, String rawZone) {
    final explicitZone = _firstJsonString(json, [
      'locationZone',
      'localizedZone',
      'area',
    ]);
    if (explicitZone.isNotEmpty) return explicitZone;

    final exploredZone =
        _extractExplorationZone(_jsonString(json['name'])) ??
        _extractExplorationZone(_jsonString(json['source'])) ??
        _extractExplorationZone(_jsonString(json['description']));
    if (exploredZone != null && exploredZone.isNotEmpty) {
      return exploredZone;
    }

    return rawZone;
  }

  static String _preferredRegion(
    Map<String, dynamic> json,
    WowExpansion expansion,
    String rawZone,
    String zone,
  ) {
    final explicitRegion = _firstJsonString(json, [
      'region',
      'worldRegion',
      'continent',
    ]);
    if (explicitRegion.isNotEmpty) return explicitRegion;

    final candidates = [
      rawZone,
      zone,
      _jsonString(json['blizzardCategoryName']),
      _jsonString(json['source']),
      _jsonString(json['description']),
      _jsonString(json['name']),
    ];

    for (final candidate in candidates) {
      final region = _regionFromText(candidate);
      if (region != null) return region;
    }

    return _defaultRegionForExpansion(expansion);
  }

  static String _firstJsonString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _jsonString(json[key]);
      if (value.isNotEmpty) return value;
    }

    return '';
  }

  static String? _extractExplorationZone(String value) {
    if (value.isEmpty) return null;

    final nameMatch = RegExp(
      r"^Exploration (?:de|du|des|d')\s*(.+)$",
      caseSensitive: false,
    ).firstMatch(value);
    if (nameMatch != null) {
      return _cleanExtractedZone(nameMatch.group(1) ?? '');
    }

    final sourceMatch = RegExp(
      r"^Explorer\s+(.+?)\s+et\s+",
      caseSensitive: false,
    ).firstMatch(value);
    if (sourceMatch != null) {
      return _cleanExtractedZone(sourceMatch.group(1) ?? '');
    }

    return null;
  }

  static String _cleanExtractedZone(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[.]$'), '')
        .trim();
  }

  static String? _regionFromText(String value) {
    final normalized = _normalizeAvailabilityText(value);
    if (normalized.isEmpty) return null;

    final exactMatch = _zoneRegionMap[normalized];
    if (exactMatch != null) return exactMatch;

    for (final entry in _zoneRegionMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }

    return null;
  }

  static String _defaultRegionForExpansion(WowExpansion expansion) {
    return switch (expansion) {
      WowExpansion.tbc => 'Outreterre',
      WowExpansion.wrath => 'Norfendre',
      WowExpansion.cataclysm => 'Zones du Cataclysme',
      WowExpansion.mop => 'Pandarie',
      WowExpansion.wod => 'Draenor',
      WowExpansion.legion => 'Iles Brisees',
      WowExpansion.bfa => 'Kul Tiras et Zandalar',
      WowExpansion.shadowlands => 'Ombreterre',
      WowExpansion.dragonflight => 'Iles aux Dragons',
      WowExpansion.warWithin => 'Khaz Algar',
      WowExpansion.midnight => 'Quel\'Thalas',
      _ => '',
    };
  }

  static const Map<String, String> _zoneRegionMap = {
    'kalimdor': 'Kalimdor',
    'durotar': 'Kalimdor',
    'feralas': 'Kalimdor',
    'gangrebois': 'Kalimdor',
    'mulgore': 'Kalimdor',
    'reflet de lune': 'Kalimdor',
    'silithus': 'Kalimdor',
    'sombrivage': 'Kalimdor',
    'tanaris': 'Kalimdor',
    'tarides': 'Kalimdor',
    'cratere d un goro': 'Kalimdor',
    'desolace': 'Kalimdor',
    'orneval': 'Kalimdor',
    'azshara': 'Kalimdor',
    'berceau de l hiver': 'Kalimdor',
    'ile de brume azur': 'Kalimdor',
    'ile de brume sang': 'Kalimdor',
    'mille pointes': 'Kalimdor',
    'mont hyjal': 'Kalimdor',
    'uldum': 'Kalimdor',
    'royaumes de l est': 'Royaumes de l\'Est',
    'royaumes de lest': 'Royaumes de l\'Est',
    'maleterres de l est': 'Royaumes de l\'Est',
    'maleterres de louest': 'Royaumes de l\'Est',
    'strangleronce': 'Royaumes de l\'Est',
    'defile de deuillevent': 'Royaumes de l\'Est',
    'chants eternels': 'Royaumes de l\'Est',
    'foret d elwynn': 'Royaumes de l\'Est',
    'dun morogh': 'Royaumes de l\'Est',
    'clairieres de tirisfal': 'Royaumes de l\'Est',
    'bois des chants eternels': 'Royaumes de l\'Est',
    'les carmines': 'Royaumes de l\'Est',
    'marche de l ouest': 'Royaumes de l\'Est',
    'bois de la penombre': 'Royaumes de l\'Est',
    'loch modan': 'Royaumes de l\'Est',
    'hautes terres arathies': 'Royaumes de l\'Est',
    'hautes terres du crepuscule': 'Royaumes de l\'Est',
    'outreterre': 'Outreterre',
    'raz de neant': 'Outreterre',
    'nagrand': 'Outreterre',
    'peninsule des flammes infernales': 'Outreterre',
    'norfendre': 'Norfendre',
    'couronne de glace': 'Norfendre',
    'pandarie': 'Pandarie',
    'draenor': 'Draenor',
    'iles brisees': 'Iles Brisees',
    'argus': 'Argus',
    'kul tiras': 'Kul Tiras',
    'zandalar': 'Zandalar',
    'nazjatar': 'Nazjatar',
    'mecagone': 'Mechagone',
    'ombreterre': 'Ombreterre',
    'zereth mortis': 'Ombreterre',
    'iles aux dragons': 'Iles aux Dragons',
    'khaz algar': 'Khaz Algar',
    'quel thalas': 'Quel\'Thalas',
  };

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
