import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/tracking_item.dart';
import '../models/tracking_category.dart';
import '../models/wow_expansion.dart';

class JsonPlannerSource {
  static final Map<String, Future<List<TrackingItem>>> _itemAssetCache = {};

  static const Set<int> _globalAchievementCategoryIds = {
    155,
    156,
    158,
    159,
    160,
    161,
    162,
    163,
    187,
    14981,
    15101,
    15416,
    15454,
    15532,
    15545,
    15567,
    15574,
  };

  static const Map<int, WowExpansion> _achievementExpansionOverrides = {
    18566: WowExpansion.dragonflight,
    18567: WowExpansion.dragonflight,
    18568: WowExpansion.dragonflight,
    18569: WowExpansion.dragonflight,
    18570: WowExpansion.dragonflight,
    18571: WowExpansion.dragonflight,
    18572: WowExpansion.dragonflight,
    18573: WowExpansion.dragonflight,
    18574: WowExpansion.dragonflight,
    18939: WowExpansion.dragonflight,
    18940: WowExpansion.dragonflight,
    18942: WowExpansion.dragonflight,
  };

  static const Map<WowExpansion, String> _achievementAssetPaths = {
    WowExpansion.vanilla: 'assets/data/achievements/vanilla_achievements.json',
    WowExpansion.tbc: 'assets/data/achievements/tbc_achievements.json',
    WowExpansion.wrath: 'assets/data/achievements/wrath_achievements.json',
    WowExpansion.cataclysm:
        'assets/data/achievements/cataclysm_achievements.json',
    WowExpansion.mop: 'assets/data/achievements/mop_achievements.json',
    WowExpansion.wod: 'assets/data/achievements/wod_achievements.json',
    WowExpansion.legion: 'assets/data/achievements/legion_achievements.json',
    WowExpansion.bfa: 'assets/data/achievements/bfa_achievements.json',
    WowExpansion.shadowlands:
        'assets/data/achievements/shadowlands_achievements.json',
    WowExpansion.dragonflight:
        'assets/data/achievements/dragonflight_achievements.json',
    WowExpansion.warWithin:
        'assets/data/achievements/warWithin_achievements.json',
    WowExpansion.midnight:
        'assets/data/achievements/midnight_achievements.json',
  };

  static const Map<WowExpansion, String> _petAssetPaths = {
    WowExpansion.vanilla: 'assets/data/pets/vanilla_pets.json',
    WowExpansion.tbc: 'assets/data/pets/tbc_pets.json',
    WowExpansion.wrath: 'assets/data/pets/wrath_pets.json',
    WowExpansion.cataclysm: 'assets/data/pets/cataclysm_pets.json',
    WowExpansion.mop: 'assets/data/pets/mop_pets.json',
    WowExpansion.wod: 'assets/data/pets/wod_pets.json',
    WowExpansion.legion: 'assets/data/pets/legion_pets.json',
    WowExpansion.bfa: 'assets/data/pets/bfa_pets.json',
    WowExpansion.shadowlands: 'assets/data/pets/shadowlands_pets.json',
    WowExpansion.dragonflight: 'assets/data/pets/dragonflight_pets.json',
    WowExpansion.warWithin: 'assets/data/pets/warWithin_pets.json',
    WowExpansion.midnight: 'assets/data/pets/midnight_pets.json',
  };

  Future<List<TrackingItem>> loadItemsFromAsset(String assetPath) async {
    final items = await _itemAssetCache.putIfAbsent(
      assetPath,
      () => _loadItemsFromAsset(assetPath),
    );

    return List<TrackingItem>.of(items);
  }

  Future<List<TrackingItem>> _loadItemsFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> data = jsonDecode(jsonString);

    return data
        .map((e) => TrackingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TrackingItem>> loadMountItems(WowExpansion expansion) async {
    final catalog = await _loadJsonList(
      'assets/generated/mounts_catalog_enriched.json',
    );
    final manualMetadata = await _loadJsonList(
      'assets/data/metadata/mounts_metadata.json',
    );
    final mamytwinkDraft = await _loadJsonList(
      'assets/generated/mounts_metadata_mamytwink_draft.json',
    );
    final wowheadOverrides = await _loadJsonList(
      'assets/data/metadata/mounts_wowhead_overrides.json',
    );
    final mountReference = await _loadMountReference();
    final mamytwinkCandidates = await _loadCandidates();

    final manualById = _byBlizzardId(manualMetadata);
    final draftById = _byBlizzardId(mamytwinkDraft);
    final wowheadById = _byBlizzardId(wowheadOverrides);
    final referenceById = _byBlizzardId(mountReference);

    final items = <TrackingItem>[];

    for (final mount in catalog) {
      final blizzardId = mount['id'] as int?;
      if (blizzardId == null) continue;

      final manual = manualById[blizzardId];
      final wowhead = wowheadById[blizzardId];
      final draft = draftById[blizzardId];
      final mamytwink = mamytwinkCandidates[blizzardId];
      final reference = referenceById[blizzardId];
      final location = reference?['location'] as Map<String, dynamic>?;
      final expansionKey =
          wowhead?['expansion'] ??
          manual?['expansion'] ??
          draft?['expansion'] ??
          mamytwink?['expansion'];

      final manualSource =
          manual?['source'] as String? ?? manual?['sourceName'] as String?;
      final wowheadSource =
          wowhead?['source'] as String? ?? wowhead?['sourceName'] as String?;
      final mamytwinkSource = mamytwink?['source'] as String?;
      final manualInstance =
          wowhead?['instance'] as String? ?? manual?['instance'] as String?;
      final difficulty =
          _metadataString(wowhead, 'difficulty') ??
          _metadataString(manual, 'difficulty') ??
          _metadataString(draft, 'difficulty') ??
          _metadataString(mamytwink, 'difficulty');
      final rawDropRate =
          _firstMetadataString(wowhead, _dropRateKeys) ??
          _firstMetadataString(manual, _dropRateKeys) ??
          _firstMetadataString(draft, _dropRateKeys) ??
          _firstMetadataString(mamytwink, _dropRateKeys) ??
          _firstMetadataString(reference, _dropRateKeys);
      final frequencyLabel =
          _firstMetadataString(wowhead, _frequencyLabelKeys) ??
          _firstMetadataString(manual, _frequencyLabelKeys) ??
          _firstMetadataString(reference, _frequencyLabelKeys) ??
          _firstMetadataString(draft, _frequencyLabelKeys) ??
          _firstMetadataString(mamytwink, _frequencyLabelKeys);
      final condition =
          _firstMetadataString(wowhead, _conditionKeys) ??
          _firstMetadataString(manual, _conditionKeys) ??
          _firstMetadataString(reference, _conditionKeys) ??
          _firstMetadataString(draft, _conditionKeys) ??
          _firstMetadataString(mamytwink, _conditionKeys);
      final tags = _metadataStringList(wowhead, 'tags')
          .followedBy(_metadataStringList(manual, 'tags'))
          .followedBy(_metadataStringList(reference, 'tags'))
          .followedBy(_metadataStringList(draft, 'tags'))
          .followedBy(_metadataStringList(mamytwink, 'tags'))
          .fold(<String>[], (tags, tag) {
            if (!tags.any((existing) => existing == tag)) {
              tags.add(tag);
            }
            return tags;
          });
      final rawSourceName = (wowheadSource?.isNotEmpty ?? false)
          ? wowheadSource!
          : (manualSource?.isNotEmpty ?? false)
          ? manualSource!
          : (mamytwinkSource?.isNotEmpty ?? false)
          ? mamytwinkSource!
          : _sourceNameFromBlizzard(mount);
      final sourceName = _cleanMountSourceName(rawSourceName);
      final dropRate = rawDropRate ?? _dropRateFromSourceName(rawSourceName);

      if (expansion != WowExpansion.allMounts &&
          (expansionKey is! String ||
              expansionKey != expansion.name ||
              _isWorldEventMountSource(sourceName))) {
        continue;
      }

      final itemExpansion = expansionKey is String
          ? WowExpansionParser.fromJson(expansionKey)
          : WowExpansion.allMounts;
      final status = _mountStatus(
        sourceName: sourceName,
        difficulty: difficulty,
        hasClassification: expansionKey is String,
      );
      final unavailable = _isUnavailableMount(
        sourceName: sourceName,
        difficulty: difficulty,
        metadata: [wowhead, manual, draft, mamytwink],
      );
      final instance = (manualInstance?.isNotEmpty ?? false)
          ? manualInstance!
          : sourceName;
      final groupInstance = _isLootMountSource(sourceName) ? status : instance;
      final displayInstance = (manualInstance?.isNotEmpty ?? false)
          ? manualInstance!
          : '';
      final mamytwinkUrl =
          _metadataString(reference, 'mamytwinkUrl') ??
          _metadataString(mamytwink, 'mamytwinkUrl') ??
          _metadataString(manual, 'mamytwinkUrl') ??
          '';
      final wowheadUrl =
          _metadataString(manual, 'wowheadUrl') ??
          _metadataString(reference, 'wowheadUrl') ??
          _metadataString(wowhead, 'externalUrl') ??
          '';
      final wowheadItemId =
          reference?['wowheadItemId'] as int? ??
          wowhead?['wowheadItemId'] as int?;
      final zone =
          _usableMetadataString(location, 'regionName') ??
          _usableZoneString(manual, 'zone') ??
          TrackingItem.unknownZone;
      final region =
          _usableMetadataString(location, 'continentName') ??
          _usableRegionString(manual, 'region') ??
          TrackingItem.unknownZone;
      final world =
          _usableMetadataString(location, 'worldName') ??
          _usableMetadataString(manual, 'world') ??
          '';

      items.add(
        TrackingItem(
          id: 'mount_$blizzardId',
          name: mount['name'] ?? mamytwink?['mamytwinkName'] ?? '',
          category: TrackingCategory.mounts,
          expansion: itemExpansion,
          zone: zone,
          subzone: _metadataString(location, 'subzoneName') ?? '',
          region: region,
          world: world,
          locationRef: _metadataString(reference, 'primaryLocationRef') ?? '',
          instance: expansion == WowExpansion.allMounts
              ? status
              : groupInstance.isEmpty
              ? 'Source a verifier'
              : groupInstance,
          displayInstance: displayInstance,
          source: sourceName,
          groupRequired:
              wowhead?['groupRequired'] ?? manual?['groupRequired'] ?? false,
          weeklyLockout:
              wowhead?['weeklyLockout'] ??
              manual?['weeklyLockout'] ??
              _isWeeklyMountSource(sourceName),
          frequencyLabel: frequencyLabel ?? '',
          obtained: false,
          unavailable: unavailable,
          difficulty: difficulty ?? '',
          dropRate: dropRate ?? '',
          tags: tags,
          condition: condition ?? '',
          blizzardId: blizzardId,
          wowheadItemId: wowheadItemId,
          boss: wowhead?['boss'] ?? manual?['boss'] ?? '',
          externalUrl: mamytwinkUrl.isNotEmpty ? mamytwinkUrl : wowheadUrl,
          mamytwinkUrl: mamytwinkUrl,
          wowheadUrl: wowheadUrl,
        ),
      );
    }

    items.sort((a, b) {
      final instanceCompare = a.instance.compareTo(b.instance);
      if (instanceCompare != 0) return instanceCompare;

      return a.name.compareTo(b.name);
    });

    return items;
  }

  Future<List<TrackingItem>> loadPetItems(WowExpansion expansion) async {
    if (expansion == WowExpansion.allPets) {
      return loadItemsFromAsset('assets/generated/pets_wow100_draft.json');
    }

    final assetPaths = <String>[];

    final assetPath = _petAssetPaths[expansion];
    if (assetPath != null) {
      assetPaths.add(assetPath);
    }

    final items = <TrackingItem>[];

    for (final assetPath in assetPaths) {
      items.addAll(await loadItemsFromAsset(assetPath));
    }

    // Shared content can be stored in the file of the expansion in which it
    // was introduced, but must stay out of that expansion's planner.
    items.removeWhere(_isOutOfExpansionPet);

    items.sort((a, b) {
      final expansionCompare = a.expansion.index.compareTo(b.expansion.index);
      if (expansionCompare != 0) return expansionCompare;

      final instanceCompare = a.instance.compareTo(b.instance);
      if (instanceCompare != 0) return instanceCompare;

      return a.name.compareTo(b.name);
    });

    return items;
  }

  bool _isOutOfExpansionPet(TrackingItem item) {
    return _isWorldEventText(item.instance) ||
        _isWorldEventText(item.source) ||
        _isBlizzardPromotionText(item.instance) ||
        _isBlizzardPromotionText(item.source);
  }

  bool _isWorldEventText(String value) {
    final normalized = _normalizeMountStatusText(value);

    return normalized.contains('evenement mondial') ||
        normalized.contains('evenement') ||
        normalized.contains('anniversaire') ||
        normalized.contains('fete') ||
        normalized.contains('amour dans l air') ||
        normalized.contains('jardin des nobles') ||
        normalized.contains('fete des brasseurs') ||
        normalized.contains('sanssaint') ||
        normalized.contains('voile d hiver');
  }

  bool _isBlizzardPromotionText(String value) {
    final normalized = _normalizeMountStatusText(value);

    return normalized == 'promotion' ||
        normalized.contains('promotion blizzard');
  }

  Future<List<TrackingItem>> loadAchievementItems(
    WowExpansion expansion,
  ) async {
    if (expansion == WowExpansion.allAchievements) {
      final generated = await _tryLoadItemsFromAsset(
        'assets/generated/achievements_wow100_draft.json',
      );

      if (generated.isNotEmpty) {
        return generated;
      }

      return _loadAllAchievementAssets();
    }

    final assetPath = _achievementAssetPaths[expansion];
    if (assetPath == null) return [];

    final items = (await _tryLoadItemsFromAsset(
      assetPath,
    )).where((item) => _belongsInAchievementPlanner(item, expansion)).toList();

    items.sort((a, b) {
      final instanceCompare = a.instance.compareTo(b.instance);
      if (instanceCompare != 0) return instanceCompare;

      return a.name.compareTo(b.name);
    });

    return items;
  }

  bool _belongsInAchievementPlanner(TrackingItem item, WowExpansion expansion) {
    final categoryId = item.blizzardCategoryId;
    if (categoryId != null) {
      if (_globalAchievementCategoryIds.contains(categoryId)) {
        return false;
      }
    }

    final achievementId = item.blizzardId;
    if (achievementId != null) {
      final achievementExpansion =
          _achievementExpansionOverrides[achievementId];
      if (achievementExpansion != null && achievementExpansion != expansion) {
        return false;
      }
    }

    return item.expansion == expansion;
  }

  Future<List<TrackingItem>> _loadAllAchievementAssets() async {
    final items = <TrackingItem>[];

    for (final assetPath in _achievementAssetPaths.values) {
      items.addAll(await _tryLoadItemsFromAsset(assetPath));
    }

    items.sort((a, b) {
      final expansionCompare = a.expansion.index.compareTo(b.expansion.index);
      if (expansionCompare != 0) return expansionCompare;

      final instanceCompare = a.instance.compareTo(b.instance);
      if (instanceCompare != 0) return instanceCompare;

      return a.name.compareTo(b.name);
    });

    return items;
  }

  Future<List<TrackingItem>> _tryLoadItemsFromAsset(String assetPath) async {
    try {
      return await loadItemsFromAsset(assetPath);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadJsonList(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> data = jsonDecode(jsonString);

    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _loadMountReference() async {
    final jsonString = await rootBundle.loadString(
      'assets/generated/mounts_reference_catalog.json',
    );
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final mounts = data['mounts'] as List<dynamic>? ?? const [];

    return mounts.cast<Map<String, dynamic>>();
  }

  Future<Map<int, Map<String, dynamic>>> _loadCandidates() async {
    final jsonString = await rootBundle.loadString(
      'assets/generated/mamytwink_mount_candidates.json',
    );
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>;

    return _byBlizzardId(candidates.cast<Map<String, dynamic>>());
  }

  Map<int, Map<String, dynamic>> _byBlizzardId(
    List<Map<String, dynamic>> items,
  ) {
    return {
      for (final item in items)
        if (item['blizzardId'] is int) item['blizzardId'] as int: item,
    };
  }

  String _sourceNameFromBlizzard(Map<String, dynamic> mount) {
    final sourceName = mount['sourceName'] as String?;
    if (sourceName != null && sourceName.isNotEmpty) return sourceName;

    return mount['sourceType'] ?? 'Source à vérifier';
  }

  String _cleanMountSourceName(String sourceName) {
    return sourceName
        .replaceFirst(RegExp(r'\s*\(\s*\d+(?:[,.]\d+)?\s*%?\s*\)\s*$'), '')
        .trim();
  }

  String? _dropRateFromSourceName(String sourceName) {
    final match = RegExp(
      r'\(\s*(\d+(?:[,.]\d+)?)\s*%?\s*\)',
    ).firstMatch(sourceName);
    if (match == null) return null;

    return match.group(1);
  }

  String? _metadataString(Map<String, dynamic>? metadata, String key) {
    if (metadata == null) return null;

    final direct = metadata[key];
    if (direct is String && direct.isNotEmpty) return direct;
    if (direct is num) return direct.toString();

    final mamytwink = metadata['mamytwink'];
    if (mamytwink is Map<String, dynamic>) {
      final nested = mamytwink[key];
      if (nested is String && nested.isNotEmpty) return nested;
      if (nested is num) return nested.toString();
    }

    return null;
  }

  String? _usableMetadataString(Map<String, dynamic>? metadata, String key) {
    final value = _metadataString(metadata, key);
    if (value == null) return null;

    final normalized = _normalizeMountStatusText(value);
    if (normalized.isEmpty ||
        normalized == 'a definir' ||
        normalized == 'source a verifier' ||
        normalized == 'unknown' ||
        normalized == 'sans zone') {
      return null;
    }

    return value;
  }

  String? _usableZoneString(Map<String, dynamic>? metadata, String key) {
    final value = _usableMetadataString(metadata, key);
    if (value == null || !TrackingItem.isKnownWorldZone(value)) return null;

    return value;
  }

  String? _usableRegionString(Map<String, dynamic>? metadata, String key) {
    final value = _usableMetadataString(metadata, key);
    if (value == null || !TrackingItem.isWorldRegion(value)) return null;

    return value;
  }

  List<String> _metadataStringList(Map<String, dynamic>? metadata, String key) {
    if (metadata == null) return const [];

    final values = metadata[key];
    if (values is! List) return const [];

    return values
        .map((value) => value is String ? value.trim() : '')
        .where((value) => value.isNotEmpty)
        .toList();
  }

  static const List<String> _dropRateKeys = [
    'dropRate',
    'dropChance',
    'drop_rate',
    'drop_chance',
    'drop',
  ];

  static const List<String> _frequencyLabelKeys = [
    'frequencyLabel',
    'frequency',
    'resetFrequency',
  ];

  static const List<String> _conditionKeys = ['condition', 'note'];

  String? _firstMetadataString(
    Map<String, dynamic>? metadata,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = _metadataString(metadata, key);
      if (value != null) return value;
    }

    return null;
  }

  bool _isUnavailableMount({
    required String sourceName,
    required String? difficulty,
    required List<Map<String, dynamic>?> metadata,
  }) {
    final values = <String>[sourceName, ?difficulty];

    for (final item in metadata.whereType<Map<String, dynamic>>()) {
      for (final key in [
        'availability',
        'category',
        'categoryType',
        'status',
      ]) {
        final value = item[key];
        if (value is String) values.add(value);
      }

      final mamytwink = item['mamytwink'];
      if (mamytwink is Map<String, dynamic>) {
        for (final key in ['difficulty', 'source', 'category', 'status']) {
          final value = mamytwink[key];
          if (value is String) values.add(value);
        }
      }
    }

    return values.map(_normalizeMountStatusText).any((value) {
      return value.contains('indisponible') ||
          value.contains('plus accessible') ||
          value.contains('plus disponible') ||
          RegExp(r'\b(retire|retiree|retirees|retired)\b').hasMatch(value) ||
          value.contains('removed') ||
          value.contains('unavailable') ||
          value == 'retired';
    });
  }

  bool _isWeeklyMountSource(String sourceName) {
    final normalized = sourceName.toLowerCase();

    return normalized.startsWith('butin') ||
        normalized.contains('raid') ||
        normalized.contains('hebdomadaire');
  }

  bool _isLootMountSource(String sourceName) {
    final source = _normalizeMountStatusText(sourceName);

    return source.contains('butin') || source.contains('drop');
  }

  bool _isWorldEventMountSource(String sourceName) {
    final source = _normalizeMountStatusText(sourceName);

    return source.contains('evenement mondial') ||
        source.contains('evenement') ||
        source.contains('anniversaire') ||
        source.contains('fete') ||
        source.contains('fete lunaire') ||
        source.contains('amour dans l air') ||
        source.contains('jardin des nobles') ||
        source.contains('fete des brasseurs') ||
        source.contains('sanssaint') ||
        source.contains('voile d hiver');
  }

  String _mountStatus({
    required String sourceName,
    required String? difficulty,
    required bool hasClassification,
  }) {
    final source = _normalizeMountStatusText(sourceName);
    final difficultyText = _normalizeMountStatusText(difficulty ?? '');

    if (RegExp(r'\b(retire|retiree|retirees|retired)\b').hasMatch(source) ||
        difficultyText.contains('indisponible')) {
      return 'Retirées / indisponibles';
    }

    if (source.contains('non implemente')) {
      return 'Non implémenté';
    }

    if (source.contains('inconnu')) {
      return 'Inconnu';
    }

    if (source.contains('butin') || source.contains('drop')) {
      return 'Butin';
    }

    if (source.contains('vendeur')) {
      return 'Vendeur';
    }

    if (source.contains('reputation')) {
      return 'Réputation';
    }

    if (source.contains('quete')) {
      return 'Quête';
    }

    if (source.contains('haut fait') || source.contains('haut-fait')) {
      return 'Haut-fait';
    }

    if (source.contains('metier') ||
        source.contains('ingenierie') ||
        source.contains('joaillerie') ||
        source.contains('couture') ||
        source.contains('peche') ||
        source.contains('archeologie')) {
      return 'Métier';
    }

    if (_isWorldEventMountSource(sourceName)) {
      return 'Événement mondial';
    }

    if (source.contains('cartes') ||
        source.contains('tcg') ||
        source.contains('jeu de cartes')) {
      return 'Cartes à collectionner';
    }

    if (source.contains('boutique')) {
      return 'Boutique';
    }

    if (source.contains('pvp')) {
      return 'PvP coté';
    }

    if (source.contains('promotion')) {
      return 'Promotion Blizzard';
    }

    if (source.contains('exploration des iles')) {
      return 'Exploration des îles';
    }

    if (source.contains('decouverte')) {
      return 'Secret';
    }

    if (source.contains('secret')) {
      return 'Secret';
    }

    if (source.contains('congregation')) {
      return 'Congrégation';
    }

    if (source.contains('comptoir')) {
      return 'Comptoir';
    }

    if (source.contains('source a verifier') ||
        (source.contains('source') && source.contains('verifier'))) {
      if (!hasClassification) {
        return 'A classer';
      }

      return 'A vérifier';
    }

    return 'Divers';
  }

  String _normalizeMountStatusText(String value) {
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
