import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/tracking_category.dart';
import '../../../../data/models/tracking_item.dart';
import '../../../../data/models/wow_expansion.dart';
import '../../../../data/models/wow_region_filter.dart';
import '../../../../data/repositories/planner_repository.dart';
import '../../../../data/sources/wow_expansion_catalog.dart';
import '../../../../data/sources/wow_location_catalog.dart';

class RegionSelectorSheet extends StatefulWidget {
  const RegionSelectorSheet({
    super.key,
    required this.repository,
    required this.newestFirst,
    this.selectedRegion,
    this.expansionScope,
    this.categoryScope,
  });

  final PlannerRepository repository;
  final bool newestFirst;
  final WowRegionFilter? selectedRegion;
  final WowExpansion? expansionScope;
  final TrackingCategory? categoryScope;

  @override
  State<RegionSelectorSheet> createState() => _RegionSelectorSheetState();
}

class _RegionSelectorSheetState extends State<RegionSelectorSheet> {
  late final Future<List<_WorldRegionSection>> _sectionsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _sectionsFuture = _loadSections();
  }

  Future<List<_WorldRegionSection>> _loadSections() async {
    final catalogSections = await WowLocationCatalog.loadAll();
    final catalogByExpansion = {
      for (final catalog in catalogSections) catalog.expansion: catalog,
    };
    final expansions = WowExpansionCatalog.all
        .where((info) {
          if (info.expansion == WowExpansion.total) return false;
          final scope = widget.expansionScope;
          return scope == null || info.expansion == scope;
        })
        .map((info) => info.expansion)
        .toList();

    expansions.sort((left, right) {
      final leftOrder = WowExpansionCatalog.infoOf(left).order;
      final rightOrder = WowExpansionCatalog.infoOf(right).order;

      return widget.newestFirst
          ? rightOrder.compareTo(leftOrder)
          : leftOrder.compareTo(rightOrder);
    });

    final expansionSections = <_ExpansionRegionSection>[];

    for (final expansion in expansions) {
      final items = await widget.repository.getItems(
        expansion,
        category: widget.categoryScope,
      );
      final catalog = catalogByExpansion[expansion];
      final section = catalog == null
          ? _ExpansionRegionSection.fromItems(expansion, items)
          : _ExpansionRegionSection.fromCatalog(
              expansion,
              catalog.regions,
              items,
            );
      if (section.regions.isNotEmpty) {
        expansionSections.add(section);
      }
    }

    return _WorldRegionSection.fromExpansionSections(expansionSections);
  }

  List<_WorldRegionSection> _filterSections(
    List<_WorldRegionSection> sections,
  ) {
    final query = WowRegionFilter.normalize(_query);
    if (query.isEmpty) return sections;

    final filteredSections = <_WorldRegionSection>[];

    for (final section in sections) {
      final filtered = section.filtered(query);
      if (filtered != null) filteredSections.add(filtered);
    }

    return filteredSections;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recherche par région',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Rechercher une région ou zone',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<_WorldRegionSection>>(
                future: _sectionsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sections = _filterSections(snapshot.data!);

                  if (sections.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucune région ne correspond à cette recherche.',
                          style: TextStyle(color: AppTheme.mutedText),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      return _WorldRegionTile(
                        section: sections[index],
                        selectedRegion: widget.selectedRegion,
                        initiallyExpanded: sections.length == 1,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldRegionTile extends StatelessWidget {
  const _WorldRegionTile({
    required this.section,
    required this.selectedRegion,
    required this.initiallyExpanded,
  });

  final _WorldRegionSection section;
  final WowRegionFilter? selectedRegion;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded:
          initiallyExpanded || section.containsSelected(selectedRegion),
      title: _ZoneCountTitle(
        label: section.name,
        count: section.zoneCount,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      children: [
        for (final continent in section.continents)
          _ContinentRegionTile(
            continent: continent,
            selectedRegion: selectedRegion,
          ),
      ],
    );
  }
}

class _ContinentRegionTile extends StatelessWidget {
  const _ContinentRegionTile({
    required this.continent,
    required this.selectedRegion,
  });

  final _ContinentRegionSection continent;
  final WowRegionFilter? selectedRegion;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: continent.containsSelected(selectedRegion),
      tilePadding: const EdgeInsets.only(left: 24, right: 16),
      title: _ZoneCountTitle(
        label: continent.name,
        count: continent.zoneCount,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      children: [
        for (final region in continent.regions)
          _RegionTile(region: region, selectedRegion: selectedRegion),
      ],
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({required this.region, required this.selectedRegion});

  final _RegionSection region;
  final WowRegionFilter? selectedRegion;

  @override
  Widget build(BuildContext context) {
    final singleOption = region.singleOptionMatchingName;

    if (singleOption != null) {
      final isSelected = selectedRegion?.key == singleOption.filter.key;

      return ListTile(
        contentPadding: const EdgeInsets.only(left: 32, right: 16),
        title: _ZoneCountTitle(
          label: region.name,
          count: region.options.length,
          style: TextStyle(
            color: isSelected ? AppTheme.gold : null,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppTheme.gold)
            : null,
        onTap: () => Navigator.pop(context, singleOption.filter),
      );
    }

    return ExpansionTile(
      initiallyExpanded:
          WowRegionFilter.normalize(selectedRegion?.region ?? '') ==
              WowRegionFilter.normalize(region.continentName) &&
          WowRegionFilter.normalize(selectedRegion?.zone ?? '') ==
              WowRegionFilter.normalize(region.name),
      tilePadding: const EdgeInsets.only(left: 32, right: 16),
      title: _ZoneCountTitle(label: region.name, count: region.options.length),
      children: [
        for (final option in region.options)
          ListTile(
            contentPadding: const EdgeInsets.only(left: 48, right: 16),
            leading: Icon(
              selectedRegion?.key == option.filter.key
                  ? Icons.check_circle
                  : Icons.location_on_outlined,
              color: selectedRegion?.key == option.filter.key
                  ? AppTheme.gold
                  : null,
            ),
            title: Text(option.filter.label),
            onTap: () => Navigator.pop(context, option.filter),
          ),
      ],
    );
  }
}

class _ZoneCountTitle extends StatelessWidget {
  const _ZoneCountTitle({required this.label, required this.count, this.style});

  final String label;
  final int count;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final baseStyle = DefaultTextStyle.of(context).style.merge(style);

    return Text(
      label,
      style: baseStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ExpansionRegionSection {
  const _ExpansionRegionSection({
    required this.expansion,
    required this.regions,
  });

  final WowExpansion expansion;
  final List<_RegionSection> regions;

  int get zoneCount {
    return regions.fold(0, (count, region) => count + region.options.length);
  }

  static _ExpansionRegionSection fromCatalog(
    WowExpansion expansion,
    List<WowCatalogRegion> catalogRegions,
    List<TrackingItem> items,
  ) {
    final counts = _countFilters(items);
    final regions = catalogRegions.map((region) {
      final options = [
        _RegionOption(
          filter: region.filter,
          count: counts[region.filter.key] ?? 0,
        ),
        for (final subzone in region.subzones)
          _RegionOption(
            filter: region.subzoneFilter(subzone),
            count: counts[region.subzoneFilter(subzone).key] ?? 0,
          ),
      ];

      return _RegionSection(
        worldName: region.worldName,
        continentName: region.continentName,
        name: region.name,
        options: options,
      );
    }).toList();

    return _ExpansionRegionSection(expansion: expansion, regions: regions);
  }

  static Map<String, int> _countFilters(List<TrackingItem> items) {
    final counts = <String, int>{};

    for (final item in items) {
      final filter = WowRegionFilter.fromItem(item);
      if (filter == null) continue;

      counts.update(filter.key, (count) => count + 1, ifAbsent: () => 1);

      final subzone = item.subzone.trim();
      if (subzone.isEmpty) continue;

      final subzoneFilter = WowRegionFilter(
        expansion: filter.expansion,
        region: filter.region,
        zone: filter.zone,
        subzone: subzone,
      );
      counts.update(subzoneFilter.key, (count) => count + 1, ifAbsent: () => 1);
    }

    return counts;
  }

  static _ExpansionRegionSection fromItems(
    WowExpansion expansion,
    List<TrackingItem> items,
  ) {
    final optionCounts = <String, _RegionOption>{};

    for (final item in items) {
      final filter = WowRegionFilter.fromItem(item);
      if (filter == null) continue;

      final current = optionCounts[filter.key];
      optionCounts[filter.key] = _RegionOption(
        filter: filter,
        count: (current?.count ?? 0) + 1,
      );
    }

    final optionsByRegion = <String, List<_RegionOption>>{};
    for (final option in optionCounts.values) {
      optionsByRegion
          .putIfAbsent(option.filter.region, () => <_RegionOption>[])
          .add(option);
    }

    final regions =
        optionsByRegion.entries.map((entry) {
          final options = entry.value
            ..sort(
              (left, right) => WowRegionFilter.normalize(
                left.filter.label,
              ).compareTo(WowRegionFilter.normalize(right.filter.label)),
            );

          return _RegionSection(
            worldName: _worldNameForItems(entry.value),
            continentName: entry.key,
            name: entry.key,
            options: options,
          );
        }).toList()..sort(
          (left, right) => WowRegionFilter.normalize(
            left.name,
          ).compareTo(WowRegionFilter.normalize(right.name)),
        );

    return _ExpansionRegionSection(expansion: expansion, regions: regions);
  }

  _ExpansionRegionSection? filtered(String query) {
    final expansionLabel = WowExpansionCatalog.infoOf(expansion).name;
    final matchesExpansion = WowRegionFilter.normalize(
      expansionLabel,
    ).contains(query);
    final filteredRegions = <_RegionSection>[];

    for (final region in regions) {
      final matchesRegion = WowRegionFilter.normalize(
        region.name,
      ).contains(query);
      final options = region.options.where((option) {
        return matchesExpansion ||
            matchesRegion ||
            WowRegionFilter.normalize(option.filter.zone).contains(query) ||
            WowRegionFilter.normalize(option.filter.subzone).contains(query);
      }).toList();

      if (options.isNotEmpty) {
        filteredRegions.add(
          _RegionSection(
            worldName: region.worldName,
            continentName: region.continentName,
            name: region.name,
            options: options,
          ),
        );
      }
    }

    if (filteredRegions.isEmpty) return null;

    return _ExpansionRegionSection(
      expansion: expansion,
      regions: filteredRegions,
    );
  }

  static String _worldNameForItems(List<_RegionOption> options) {
    for (final option in options) {
      final world = option.filter.zone == TrackingItem.unknownZone
          ? ''
          : option.filter.region;
      if (world.isNotEmpty) return world;
    }

    return TrackingItem.unknownZone;
  }
}

class _WorldRegionSection {
  const _WorldRegionSection({required this.name, required this.continents});

  final String name;
  final List<_ContinentRegionSection> continents;

  int get zoneCount {
    return continents.fold(
      0,
      (count, continent) => count + continent.zoneCount,
    );
  }

  bool containsSelected(WowRegionFilter? selectedRegion) {
    return continents.any(
      (continent) => continent.containsSelected(selectedRegion),
    );
  }

  _WorldRegionSection? filtered(String query) {
    final matchesWorld = WowRegionFilter.normalize(name).contains(query);
    final filteredContinents = <_ContinentRegionSection>[];

    for (final continent in continents) {
      final filtered = continent.filtered(query, matchesWorld: matchesWorld);
      if (filtered != null) filteredContinents.add(filtered);
    }

    if (filteredContinents.isEmpty) return null;

    return _WorldRegionSection(name: name, continents: filteredContinents);
  }

  static List<_WorldRegionSection> fromExpansionSections(
    List<_ExpansionRegionSection> expansionSections,
  ) {
    final builders = <String, _WorldRegionBuilder>{};

    for (final section in expansionSections) {
      for (final region in section.regions) {
        final worldBuilder = builders.putIfAbsent(
          region.worldName,
          () => _WorldRegionBuilder(region.worldName),
        );
        worldBuilder.add(region);
      }
    }

    return builders.values.map((builder) => builder.build()).toList()
      ..sort((left, right) => _compareLabels(left.name, right.name));
  }
}

class _ContinentRegionSection {
  const _ContinentRegionSection({required this.name, required this.regions});

  final String name;
  final List<_RegionSection> regions;

  int get zoneCount {
    return regions.fold(0, (count, region) => count + region.options.length);
  }

  bool containsSelected(WowRegionFilter? selectedRegion) {
    if (selectedRegion == null) return false;

    return regions.any((region) {
      return WowRegionFilter.normalize(selectedRegion.region) ==
              WowRegionFilter.normalize(name) &&
          region.options.any(
            (option) => option.filter.key == selectedRegion.key,
          );
    });
  }

  _ContinentRegionSection? filtered(
    String query, {
    required bool matchesWorld,
  }) {
    final matchesContinent = WowRegionFilter.normalize(name).contains(query);
    final filteredRegions = <_RegionSection>[];

    for (final region in regions) {
      final filtered = region.filtered(
        query,
        matchesAncestor: matchesWorld || matchesContinent,
      );
      if (filtered != null) filteredRegions.add(filtered);
    }

    if (filteredRegions.isEmpty) return null;

    return _ContinentRegionSection(name: name, regions: filteredRegions);
  }
}

class _WorldRegionBuilder {
  _WorldRegionBuilder(this.name);

  final String name;
  final Map<String, _ContinentRegionBuilder> _continents = {};

  void add(_RegionSection region) {
    final builder = _continents.putIfAbsent(
      region.continentName,
      () => _ContinentRegionBuilder(region.continentName),
    );
    builder.add(region);
  }

  _WorldRegionSection build() {
    final continents =
        _continents.values.map((builder) => builder.build()).toList()
          ..sort((left, right) => _compareLabels(left.name, right.name));

    return _WorldRegionSection(name: name, continents: continents);
  }
}

class _ContinentRegionBuilder {
  _ContinentRegionBuilder(this.name);

  final String name;
  final Map<String, _RegionSection> _regions = {};

  void add(_RegionSection region) {
    final key = WowRegionFilter.normalize(region.name);
    final current = _regions[key];
    if (current == null) {
      _regions[key] = region;
      return;
    }

    final optionsByKey = {
      for (final option in current.options) option.filter.key: option,
      for (final option in region.options) option.filter.key: option,
    };

    final options = optionsByKey.values.toList()
      ..sort(
        (left, right) => _compareLabels(left.filter.label, right.filter.label),
      );

    _regions[key] = _RegionSection(
      worldName: current.worldName,
      continentName: current.continentName,
      name: current.name,
      options: options,
    );
  }

  _ContinentRegionSection build() {
    final regions = _regions.values.toList()
      ..sort((left, right) => _compareLabels(left.name, right.name));

    return _ContinentRegionSection(name: name, regions: regions);
  }
}

class _RegionSection {
  const _RegionSection({
    required this.worldName,
    required this.continentName,
    required this.name,
    required this.options,
  });

  final String worldName;
  final String continentName;
  final String name;
  final List<_RegionOption> options;

  _RegionOption? get singleOptionMatchingName {
    if (options.length != 1) return null;

    final option = options.single;
    if (WowRegionFilter.normalize(option.filter.label) !=
        WowRegionFilter.normalize(name)) {
      return null;
    }

    return option;
  }

  _RegionSection? filtered(String query, {required bool matchesAncestor}) {
    final matchesRegion = WowRegionFilter.normalize(name).contains(query);
    final options = this.options.where((option) {
      return matchesAncestor ||
          matchesRegion ||
          WowRegionFilter.normalize(option.filter.zone).contains(query) ||
          WowRegionFilter.normalize(option.filter.subzone).contains(query);
    }).toList();

    if (options.isEmpty) return null;

    return _RegionSection(
      worldName: worldName,
      continentName: continentName,
      name: name,
      options: options,
    );
  }
}

class _RegionOption {
  const _RegionOption({required this.filter, required this.count});

  final WowRegionFilter filter;
  final int count;
}

int _compareLabels(String left, String right) {
  return WowRegionFilter.normalize(
    left,
  ).compareTo(WowRegionFilter.normalize(right));
}
