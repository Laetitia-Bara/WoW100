import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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
  });

  final PlannerRepository repository;
  final bool newestFirst;
  final WowRegionFilter? selectedRegion;
  final WowExpansion? expansionScope;

  @override
  State<RegionSelectorSheet> createState() => _RegionSelectorSheetState();
}

class _RegionSelectorSheetState extends State<RegionSelectorSheet> {
  late final Future<List<_ExpansionRegionSection>> _sectionsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _sectionsFuture = _loadSections();
  }

  Future<List<_ExpansionRegionSection>> _loadSections() async {
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

    final sections = <_ExpansionRegionSection>[];

    for (final expansion in expansions) {
      final items = await widget.repository.getItems(expansion);
      final catalog = catalogByExpansion[expansion];
      final section = catalog == null
          ? _ExpansionRegionSection.fromItems(expansion, items)
          : _ExpansionRegionSection.fromCatalog(
              expansion,
              catalog.regions,
              items,
            );
      if (section.regions.isNotEmpty) {
        sections.add(section);
      }
    }

    return sections;
  }

  List<_ExpansionRegionSection> _filterSections(
    List<_ExpansionRegionSection> sections,
  ) {
    final query = WowRegionFilter.normalize(_query);
    if (query.isEmpty) return sections;

    final filteredSections = <_ExpansionRegionSection>[];

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
                      'Recherche par region',
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
                  labelText: 'Rechercher une extension, region ou zone',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<_ExpansionRegionSection>>(
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
                          'Aucune region ne correspond a cette recherche.',
                          style: TextStyle(color: AppTheme.mutedText),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      return _ExpansionRegionTile(
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

class _ExpansionRegionTile extends StatelessWidget {
  const _ExpansionRegionTile({
    required this.section,
    required this.selectedRegion,
    required this.initiallyExpanded,
  });

  final _ExpansionRegionSection section;
  final WowRegionFilter? selectedRegion;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final info = WowExpansionCatalog.infoOf(section.expansion);

    return ExpansionTile(
      initiallyExpanded:
          initiallyExpanded || selectedRegion?.expansion == section.expansion,
      title: Text(
        info.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('${section.zoneCount} zones'),
      children: [
        for (final region in section.regions)
          ExpansionTile(
            initiallyExpanded:
                selectedRegion?.expansion == section.expansion &&
                WowRegionFilter.normalize(selectedRegion?.zone ?? '') ==
                    WowRegionFilter.normalize(region.name),
            tilePadding: const EdgeInsets.only(left: 32, right: 16),
            title: Text(region.name),
            subtitle: Text('${region.options.length} zones'),
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
                  trailing: option.count == 0
                      ? null
                      : Text(
                          option.count.toString(),
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                  onTap: () => Navigator.pop(context, option.filter),
                ),
            ],
          ),
      ],
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

      return _RegionSection(name: region.name, options: options);
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

          return _RegionSection(name: entry.key, options: options);
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
          _RegionSection(name: region.name, options: options),
        );
      }
    }

    if (filteredRegions.isEmpty) return null;

    return _ExpansionRegionSection(
      expansion: expansion,
      regions: filteredRegions,
    );
  }
}

class _RegionSection {
  const _RegionSection({required this.name, required this.options});

  final String name;
  final List<_RegionOption> options;
}

class _RegionOption {
  const _RegionOption({required this.filter, required this.count});

  final WowRegionFilter filter;
  final int count;
}
