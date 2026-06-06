import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/tracking_item.dart';
import '../models/tracking_category.dart';
import '../models/wow_expansion.dart';

class JsonPlannerSource {
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

  Future<List<TrackingItem>> loadWrathMounts() {
    return loadItemsFromAsset('assets/data/mounts/wrath_mounts.json');
  }

  Future<List<TrackingItem>> loadItemsFromAsset(String assetPath) async {
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
    final mamytwinkCandidates = await _loadCandidates();

    final manualById = _byBlizzardId(manualMetadata);
    final draftById = _byBlizzardId(mamytwinkDraft);

    final items = <TrackingItem>[];

    for (final mount in catalog) {
      final blizzardId = mount['id'] as int?;
      if (blizzardId == null) continue;

      final manual = manualById[blizzardId];
      final draft = draftById[blizzardId];
      final mamytwink = mamytwinkCandidates[blizzardId];
      final expansionKey =
          manual?['expansion'] ??
          draft?['expansion'] ??
          mamytwink?['expansion'];

      if (expansion != WowExpansion.allMounts &&
          (expansionKey is! String || expansionKey != expansion.name)) {
        continue;
      }

      final itemExpansion = expansionKey is String
          ? WowExpansionParser.fromJson(expansionKey)
          : WowExpansion.allMounts;
      final manualSource =
          manual?['source'] as String? ?? manual?['sourceName'] as String?;
      final mamytwinkSource = mamytwink?['source'] as String?;
      final manualInstance = manual?['instance'] as String?;
      final sourceName = (manualSource?.isNotEmpty ?? false)
          ? manualSource!
          : (mamytwinkSource?.isNotEmpty ?? false)
              ? mamytwinkSource!
              : _sourceNameFromBlizzard(mount);
      final status = _mountStatus(
        sourceName: sourceName,
        difficulty:
            manual?['difficulty'] as String? ??
            mamytwink?['difficulty'] as String?,
        hasClassification: expansionKey is String,
      );
      final instance = (manualInstance?.isNotEmpty ?? false)
          ? manualInstance!
          : sourceName;

      items.add(
        TrackingItem(
          id: 'mount_$blizzardId',
          name: mount['name'] ?? mamytwink?['mamytwinkName'] ?? '',
          category: TrackingCategory.mounts,
          expansion: itemExpansion,
          zone: manual?['zone'] ?? mamytwink?['extensionName'] ?? 'Non classe',
          instance: expansion == WowExpansion.allMounts
              ? status
              : instance.isEmpty
              ? 'Source a verifier'
              : instance,
          source: sourceName,
          groupRequired: manual?['groupRequired'] ?? false,
          weeklyLockout:
              manual?['weeklyLockout'] ?? _isWeeklyMountSource(sourceName),
          obtained: false,
          blizzardId: blizzardId,
          boss: manual?['boss'] ?? '',
          externalUrl: mamytwink?['mamytwinkUrl'] ?? '',
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

    items.sort((a, b) {
      final expansionCompare = a.expansion.index.compareTo(b.expansion.index);
      if (expansionCompare != 0) return expansionCompare;

      final instanceCompare = a.instance.compareTo(b.instance);
      if (instanceCompare != 0) return instanceCompare;

      return a.name.compareTo(b.name);
    });

    return items;
  }

  Future<List<Map<String, dynamic>>> _loadJsonList(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> data = jsonDecode(jsonString);

    return data.cast<Map<String, dynamic>>();
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

  bool _isWeeklyMountSource(String sourceName) {
    final normalized = sourceName.toLowerCase();

    return normalized.startsWith('butin') ||
        normalized.contains('raid') ||
        normalized.contains('hebdomadaire');
  }

  String _mountStatus({
    required String sourceName,
    required String? difficulty,
    required bool hasClassification,
  }) {
    final source = _normalizeMountStatusText(sourceName);
    final difficultyText = _normalizeMountStatusText(difficulty ?? '');

    if (source.contains('retire') || difficultyText.contains('indisponible')) {
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

    if (source.contains('evenement mondial') ||
        source.contains('evenement') ||
        source.contains('anniversaire') ||
        source.contains('fete') ||
        source.contains('amour dans l air') ||
        source.contains('jardin des nobles') ||
        source.contains('voile d hiver')) {
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
