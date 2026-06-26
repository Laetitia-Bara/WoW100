import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/wow_expansion.dart';
import '../models/wow_region_filter.dart';

class WowLocationCatalog {
  const WowLocationCatalog({required this.expansion, required this.regions});

  final WowExpansion expansion;
  final List<WowCatalogRegion> regions;

  static Future<List<WowLocationCatalog>> loadAll() async {
    final jsonString = await rootBundle.loadString(
      'assets/generated/locations_reference_catalog.json',
    );
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final continents = _continentNames(data);
    final locations = (data['locations'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final regionsByExpansion = <WowExpansion, Map<String, _RegionBuilder>>{};

    for (final location in locations) {
      final expansion = _expansionFromKey(location['extensionKey']);
      if (expansion == null) continue;

      final kind = location['kind'] as String? ?? '';
      final regionName = _string(location['regionName']);
      final regionRef = _string(location['regionRef']);
      final continentName = continents[_string(location['continentKey'])] ?? '';

      if (regionName.isEmpty || regionRef.isEmpty || continentName.isEmpty) {
        continue;
      }

      final builders = regionsByExpansion.putIfAbsent(
        expansion,
        () => <String, _RegionBuilder>{},
      );
      final builder = builders.putIfAbsent(
        regionRef,
        () => _RegionBuilder(
          expansion: expansion,
          continentName: continentName,
          regionName: regionName,
        ),
      );

      if (kind == 'subzone') {
        final subzoneName = _string(location['name']);
        if (subzoneName.isNotEmpty &&
            WowRegionFilter.normalize(subzoneName) !=
                WowRegionFilter.normalize(regionName)) {
          builder.addSubzone(subzoneName);
        }
      }
    }

    return [
      for (final entry in regionsByExpansion.entries)
        WowLocationCatalog(
          expansion: entry.key,
          regions: _sortedRegions(entry.value.values),
        ),
    ];
  }

  static Map<String, String> _continentNames(Map<String, dynamic> data) {
    final continents = data['continents'] as List<dynamic>? ?? const [];

    return {
      for (final continent in continents.whereType<Map<String, dynamic>>())
        if (_string(continent['key']).isNotEmpty)
          _string(continent['key']): _string(continent['name']),
    };
  }

  static List<WowCatalogRegion> _sortedRegions(
    Iterable<_RegionBuilder> builders,
  ) {
    final regions = builders.map((builder) => builder.build()).toList()
      ..sort((left, right) => _compareLabels(left.name, right.name));

    return regions;
  }

  static int _compareLabels(String left, String right) {
    return WowRegionFilter.normalize(
      left,
    ).compareTo(WowRegionFilter.normalize(right));
  }

  static WowExpansion? _expansionFromKey(dynamic value) {
    return switch (value) {
      'vanilla' => WowExpansion.vanilla,
      'the-burning-crusade' => WowExpansion.tbc,
      'wrath-of-the-lich-king' => WowExpansion.wrath,
      'cataclysm' => WowExpansion.cataclysm,
      'mists-of-pandaria' => WowExpansion.mop,
      'warlords-of-draenor' => WowExpansion.wod,
      'legion' => WowExpansion.legion,
      'battle-for-azeroth' => WowExpansion.bfa,
      'shadowlands' => WowExpansion.shadowlands,
      'dragonflight' => WowExpansion.dragonflight,
      'the-war-within' => WowExpansion.warWithin,
      'midnight' => WowExpansion.midnight,
      _ => null,
    };
  }

  static String _string(dynamic value) {
    return value is String ? value.trim() : '';
  }
}

class WowCatalogRegion {
  const WowCatalogRegion({
    required this.expansion,
    required this.continentName,
    required this.name,
    required this.subzones,
  });

  final WowExpansion expansion;
  final String continentName;
  final String name;
  final List<String> subzones;

  WowRegionFilter get filter {
    return WowRegionFilter(
      expansion: expansion,
      region: continentName,
      zone: name,
    );
  }

  WowRegionFilter subzoneFilter(String subzone) {
    return WowRegionFilter(
      expansion: expansion,
      region: continentName,
      zone: name,
      subzone: subzone,
    );
  }
}

class _RegionBuilder {
  _RegionBuilder({
    required this.expansion,
    required this.continentName,
    required this.regionName,
  });

  final WowExpansion expansion;
  final String continentName;
  final String regionName;
  final Set<String> _subzones = {};

  void addSubzone(String subzone) {
    _subzones.add(subzone);
  }

  WowCatalogRegion build() {
    final subzones = _subzones.toList()
      ..sort(WowLocationCatalog._compareLabels);

    return WowCatalogRegion(
      expansion: expansion,
      continentName: continentName,
      name: regionName,
      subzones: subzones,
    );
  }
}
