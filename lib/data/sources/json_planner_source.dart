import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/tracking_item.dart';
import '../models/tracking_category.dart';
import '../models/wow_expansion.dart';

class JsonPlannerSource {
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
      final mamytwinkSource = mamytwink?['source'] as String?;
      final manualInstance = manual?['instance'] as String?;
      final sourceName = (mamytwinkSource?.isNotEmpty ?? false)
          ? mamytwinkSource!
          : _sourceNameFromBlizzard(mount);
      final status = _mountStatus(
        sourceName: sourceName,
        difficulty: mamytwink?['difficulty'] as String?,
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

    return mount['sourceType'] ?? 'Source a verifier';
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
    final source = sourceName.toLowerCase();
    final difficultyText = (difficulty ?? '').toLowerCase();

    if (!hasClassification) {
      return 'A classer';
    }

    if (source.contains('boutique')) {
      return 'Boutique';
    }

    if (source.contains('cartes') || source.contains('tcg')) {
      return 'TCG';
    }

    if (source.contains('promotion')) {
      return 'Promotion';
    }

    if (source.contains('retire') || difficultyText.contains('indisponible')) {
      return 'Retirees / indisponibles';
    }

    if (source.contains('comptoir')) {
      return 'Comptoir';
    }

    if (source.contains('secret')) {
      return 'Secrets';
    }

    if (source.contains('inconnu') || source.contains('non implemente')) {
      return 'A verifier';
    }

    return 'Disponibles';
  }
}
