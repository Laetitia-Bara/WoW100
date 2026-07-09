import 'tracking_category.dart';
import 'wow_expansion.dart';

class TrackingItem {
  static const String unknownZone = 'Sans zone';

  final String id;

  /// Nom affiché
  final String name;

  /// Monture, HF, Mascotte...
  final TrackingCategory category;

  /// Extension associée
  final WowExpansion expansion;

  /// Zone générale
  final String zone;

  /// Sous-zone précise, lorsqu'elle existe.
  final String subzone;

  /// Region de monde / continent parent de la zone.
  final String region;

  /// Monde parent de la localisation.
  final String world;

  /// Référence stable vers le catalogue de localisation.
  final String locationRef;

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

  /// Libelle de frequence affiche a la place du tag de lockout standard.
  final String frequencyLabel;

  /// Obtenu par le joueur
  final bool obtained;

  /// N'est plus possible a obtenir en jeu.
  final bool unavailable;

  /// Niveau de difficulte de recuperation lorsque le catalogue le connait.
  final String difficulty;

  /// Taux de drop affiche lorsque le catalogue le connait.
  final String dropRate;

  /// Tags manuels additionnels affiches apres les metadonnees standard.
  final List<String> tags;

  final int? blizzardId;

  final String boss;

  final String externalUrl;

  final String mamytwinkUrl;

  final String wowheadUrl;

  const TrackingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.expansion,
    required this.zone,
    this.subzone = '',
    this.region = '',
    this.world = '',
    this.locationRef = '',
    required this.instance,
    required this.source,
    this.wowheadItemId,
    this.wowheadAchievementId,
    this.blizzardCategoryId,
    this.blizzardCategoryName = '',
    required this.groupRequired,
    required this.weeklyLockout,
    this.frequencyLabel = '',
    required this.obtained,
    this.unavailable = false,
    this.difficulty = '',
    this.dropRate = '',
    this.tags = const [],
    this.blizzardId,
    required this.boss,
    this.externalUrl = '',
    this.mamytwinkUrl = '',
    this.wowheadUrl = '',
  });

  TrackingItem copyWith({bool? obtained}) {
    return TrackingItem(
      id: id,
      name: name,
      category: category,
      expansion: expansion,
      zone: zone,
      subzone: subzone,
      region: region,
      world: world,
      locationRef: locationRef,
      instance: instance,
      source: source,
      wowheadItemId: wowheadItemId,
      wowheadAchievementId: wowheadAchievementId,
      blizzardCategoryId: blizzardCategoryId,
      blizzardCategoryName: blizzardCategoryName,
      groupRequired: groupRequired,
      weeklyLockout: weeklyLockout,
      frequencyLabel: frequencyLabel,
      obtained: obtained ?? this.obtained,
      unavailable: unavailable,
      difficulty: difficulty,
      dropRate: dropRate,
      tags: tags,
      blizzardId: blizzardId,
      boss: boss,
      externalUrl: externalUrl,
      mamytwinkUrl: mamytwinkUrl,
      wowheadUrl: wowheadUrl,
    );
  }

  factory TrackingItem.fromJson(Map<String, dynamic> json) {
    final expansion = WowExpansionParser.fromJson(json['expansion']);
    final zone = _officialWorldZoneFromJson(json);

    return TrackingItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: TrackingCategoryParser.fromJson(json['category']),
      expansion: expansion,
      zone: zone,
      subzone: json['subzone'] ?? '',
      region: _officialRegionFromJson(json, zone),
      world: json['world'] ?? '',
      locationRef: json['primaryLocationRef'] ?? json['locationRef'] ?? '',
      instance: json['instance'] ?? '',
      source: json['source'] ?? '',
      wowheadItemId: json['wowheadItemId'],
      wowheadAchievementId: json['wowheadAchievementId'],
      blizzardCategoryId: json['blizzardCategoryId'],
      blizzardCategoryName: json['blizzardCategoryName'] ?? '',
      groupRequired: json['groupRequired'] ?? false,
      weeklyLockout: json['weeklyLockout'] ?? false,
      frequencyLabel: _firstJsonDisplayString(json, [
        'frequencyLabel',
        'frequency',
        'resetFrequency',
      ]),
      obtained: false,
      unavailable: json['unavailable'] ?? _looksUnavailable(json),
      difficulty: json['difficulty'] ?? '',
      dropRate: _firstJsonDisplayString(json, [
        'dropRate',
        'dropChance',
        'drop_rate',
        'drop_chance',
        'drop',
      ]),
      tags: _jsonStringList(json['tags']),
      blizzardId: json['blizzardId'],
      boss: json['boss'] ?? '',
      externalUrl: json['externalUrl'] ?? json['mamytwinkUrl'] ?? '',
      mamytwinkUrl: json['mamytwinkUrl'] ?? '',
      wowheadUrl: json['wowheadUrl'] ?? '',
    );
  }

  static String _jsonString(dynamic value) {
    if (value is! String) return '';

    return value.trim();
  }

  static List<String> _jsonStringList(dynamic value) {
    if (value is! List) return const [];

    final tags = <String>[];
    final seen = <String>{};

    for (final item in value) {
      final tag = _jsonDisplayString(item);
      if (tag.isEmpty) continue;

      final normalized = _normalizeAvailabilityText(tag);
      if (normalized.isEmpty || !seen.add(normalized)) continue;

      tags.add(tag);
    }

    return tags;
  }

  static String _officialWorldZoneFromJson(Map<String, dynamic> json) {
    final candidates = [
      _firstJsonString(json, ['locationZone', 'localizedZone', 'area']),
      _jsonString(json['zone']),
    ];

    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      if (isKnownWorldZone(candidate)) return candidate.trim();
    }

    return unknownZone;
  }

  static String _officialRegionFromJson(
    Map<String, dynamic> json,
    String zone,
  ) {
    final regionFromZone = canonicalRegionForZone(zone);
    if (regionFromZone != null) return regionFromZone;

    if (zone == unknownZone) return unknownZone;

    final explicitRegion = _firstJsonString(json, [
      'region',
      'worldRegion',
      'continent',
    ]);
    if (explicitRegion.isNotEmpty && isWorldRegion(explicitRegion)) {
      return explicitRegion;
    }

    return unknownZone;
  }

  static String _firstJsonString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _jsonString(json[key]);
      if (value.isNotEmpty) return value;
    }

    return '';
  }

  static String _jsonDisplayString(dynamic value) {
    if (value is String) return value.trim();
    if (value is num) return value.toString();

    return '';
  }

  static String _firstJsonDisplayString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final source in [
      json,
      if (json['mamytwink'] is Map<String, dynamic>)
        json['mamytwink'] as Map<String, dynamic>,
      if (json['wowhead'] is Map<String, dynamic>)
        json['wowhead'] as Map<String, dynamic>,
    ]) {
      for (final key in keys) {
        final value = _jsonDisplayString(source[key]);
        if (value.isNotEmpty) return value;
      }
    }

    return '';
  }

  static bool isWorldRegion(String value) {
    return _worldRegionAliases.containsKey(_normalizeAvailabilityText(value));
  }

  static bool isKnownWorldZone(String value) {
    return _worldZoneMap.containsKey(_normalizeAvailabilityText(value));
  }

  static String canonicalWorldZone(String value) {
    final zone = value.trim();
    return zone.isEmpty ? unknownZone : zone;
  }

  static String? canonicalRegionForZone(String value) {
    return _worldZoneMap[_normalizeAvailabilityText(value)];
  }

  static const Map<String, String> _worldRegionAliases = {
    'kalimdor': 'Kalimdor',
    'royaumes de l est': 'Royaumes de l\'Est',
    'royaumes de lest': 'Royaumes de l\'Est',
    'outreterre': 'Outreterre',
    'norfendre': 'Norfendre',
    'pandarie': 'Pandarie',
    'draenor': 'Draenor',
    'iles brisees': 'Iles Brisees',
    'argus': 'Argus',
    'kul tiras': 'Kul Tiras',
    'zandalar': 'Zandalar',
    'ombreterre': 'Ombreterre',
    'iles aux dragons': 'Iles aux Dragons',
    'khaz algar': 'Khaz Algar',
    'quel thalas': 'Quel\'Thalas',
  };

  static const Map<String, String> _worldZoneMap = {
    'iles de l echo': 'Kalimdor',
    'ile de brume azur': 'Kalimdor',
    'durotar': 'Kalimdor',
    'feralas': 'Kalimdor',
    'gangrebois': 'Kalimdor',
    'mulgore': 'Kalimdor',
    'reflet de lune': 'Kalimdor',
    'silithus': 'Kalimdor',
    'sombrivage': 'Kalimdor',
    'tanaris': 'Kalimdor',
    'tarides': 'Kalimdor',
    'tarides du nord': 'Kalimdor',
    'tarides du sud': 'Kalimdor',
    'cratere d un goro': 'Kalimdor',
    'desolace': 'Kalimdor',
    'orneval': 'Kalimdor',
    'azshara': 'Kalimdor',
    'berceau de l hiver': 'Kalimdor',
    'ile de brume sang': 'Kalimdor',
    'mille pointes': 'Kalimdor',
    'les serres rocheuses': 'Kalimdor',
    'serres rocheuses': 'Kalimdor',
    'marecage d aprefange': 'Kalimdor',
    'ahn qiraj le royaume dechu': 'Kalimdor',
    'mont hyjal': 'Kalimdor',
    'uldum': 'Kalimdor',
    'dun morogh': 'Royaumes de l\'Est',
    'foret d elwynn': 'Royaumes de l\'Est',
    'bois des chants eternels': 'Royaumes de l\'Est',
    'bois de chants eternels': 'Royaumes de l\'Est',
    'clairieres de tirisfal': 'Royaumes de l\'Est',
    'gilneas': 'Royaumes de l\'Est',
    'marche de l ouest': 'Royaumes de l\'Est',
    'terres fantomes': 'Royaumes de l\'Est',
    'les terres fantomes': 'Royaumes de l\'Est',
    'loch modan': 'Royaumes de l\'Est',
    'foret des pins argentes': 'Royaumes de l\'Est',
    'les carmines': 'Royaumes de l\'Est',
    'bois de la penombre': 'Royaumes de l\'Est',
    'contreforts de hautebrande': 'Royaumes de l\'Est',
    'les paluns': 'Royaumes de l\'Est',
    'paluns': 'Royaumes de l\'Est',
    'hautes terres arathi': 'Royaumes de l\'Est',
    'hautes terres arathies': 'Royaumes de l\'Est',
    'strangleronce septentrionale': 'Royaumes de l\'Est',
    'cap strangleronce': 'Royaumes de l\'Est',
    'maleterres de l est': 'Royaumes de l\'Est',
    'maleterres de louest': 'Royaumes de l\'Est',
    'strangleronce': 'Royaumes de l\'Est',
    'vallee de strangleronce': 'Royaumes de l\'Est',
    'defile de deuillevent': 'Royaumes de l\'Est',
    'les hinterlands': 'Royaumes de l\'Est',
    'hinterlands': 'Royaumes de l\'Est',
    'terres ingrates': 'Royaumes de l\'Est',
    'gorge des vents brulants': 'Royaumes de l\'Est',
    'steppes ardentes': 'Royaumes de l\'Est',
    'marais des chagrins': 'Royaumes de l\'Est',
    'terres foudroyees': 'Royaumes de l\'Est',
    'ile de quel danas': 'Royaumes de l\'Est',
    'foret de varech thar': 'Royaumes de l\'Est',
    'etendues chatoyantes': 'Royaumes de l\'Est',
    'profondeurs abyssales': 'Royaumes de l\'Est',
    'hautes terres du crepuscule': 'Royaumes de l\'Est',
    'peninsule de tol barad': 'Royaumes de l\'Est',
    'tol barad': 'Royaumes de l\'Est',
    'raz de neant': 'Outreterre',
    'nagrand': 'Outreterre',
    'peninsule des flammes infernales': 'Outreterre',
    'marecage de zangar': 'Outreterre',
    'foret de terokkar': 'Outreterre',
    'les tranchantes': 'Outreterre',
    'tranchantes': 'Outreterre',
    'vallee d ombrelune': 'Outreterre',
    'toundra boreenne': 'Norfendre',
    'fjord hurlant': 'Norfendre',
    'desolation des dragons': 'Norfendre',
    'les grisonnes': 'Norfendre',
    'grisonnes': 'Norfendre',
    'zul drak': 'Norfendre',
    'bassin de sholazar': 'Norfendre',
    'les pics foudroyes': 'Norfendre',
    'pics foudroyes': 'Norfendre',
    'foret du chant de cristal': 'Norfendre',
    'accostage de hrothgar': 'Norfendre',
    'couronne de glace': 'Norfendre',
    'la couronne de glace': 'Norfendre',
    'joug d hiver': 'Norfendre',
    'kezan': 'Le Maelstrom',
    'les iles perdues': 'Le Maelstrom',
    'maelstrom': 'Le Maelstrom',
    'le trefonds': 'Le Maelstrom',
    'trefonds': 'Le Maelstrom',
    'front du magma': 'Zones du Cataclysme',
    'la foret de jade': 'Pandarie',
    'foret de jade': 'Pandarie',
    'vallee des quatre vents': 'Pandarie',
    'etendues sauvages de krasarang': 'Pandarie',
    'sommet de kun lai': 'Pandarie',
    'steppes de tanglong': 'Pandarie',
    'terres de l angoisse': 'Pandarie',
    'val de l eternel printemps': 'Pandarie',
    'escalier derobe': 'Pandarie',
    'ile du tonnerre': 'Pandarie',
    'ile des geants': 'Pandarie',
    'ile du temps fige': 'Pandarie',
    'crete de givrefeu': 'Draenor',
    'gorgrond': 'Draenor',
    'talador': 'Draenor',
    'fleches d arak': 'Draenor',
    'jungle de tanaan': 'Draenor',
    'ashran': 'Draenor',
    'val sharah': 'Iles Brisees',
    'tornheim': 'Iles Brisees',
    'helheim': 'Iles Brisees',
    'azsuna': 'Iles Brisees',
    'haut roc': 'Iles Brisees',
    'suramar': 'Iles Brisees',
    'rivage brise': 'Iles Brisees',
    'etendues antoreennes': 'Argus',
    'krokuun': 'Argus',
    'mac aree': 'Argus',
    'kul tiras': 'Kul Tiras',
    'drustvar': 'Kul Tiras',
    'vallee chantorage': 'Kul Tiras',
    'rade de tiragarde': 'Kul Tiras',
    'tol dagor': 'Kul Tiras',
    'zuldazar': 'Zandalar',
    'nazmir': 'Zandalar',
    'vol dun': 'Zandalar',
    'nazjatar': 'Nazjatar',
    'mecagone': 'Mechagone',
    'bastion': 'Ombreterre',
    'l antre': 'Ombreterre',
    'antre': 'Ombreterre',
    'maldraxxus': 'Ombreterre',
    'oribos': 'Ombreterre',
    'revendreth': 'Ombreterre',
    'sylvarden': 'Ombreterre',
    'zereth mortis': 'Ombreterre',
    'rivages de l eveil': 'Iles aux Dragons',
    'plaines d ohn ahra': 'Iles aux Dragons',
    'traversee d azur': 'Iles aux Dragons',
    'thaldraszus': 'Iles aux Dragons',
    'grotte de zaralek': 'Iles aux Dragons',
    'reve d emeraude': 'Iles aux Dragons',
    'ile de dorn': 'Khaz Algar',
    'abimes retentissants': 'Khaz Algar',
    'sainte chute': 'Khaz Algar',
    'azj kahet': 'Khaz Algar',
    'k aresh': 'Khaz Algar',
    'harandar': 'Quel\'Thalas',
    'zul aman': 'Quel\'Thalas',
    'tempete du vide': 'Quel\'Thalas',
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
