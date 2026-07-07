import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wow100/core/services/battle_net_token_service.dart';
import 'package:wow100/data/models/achievement_faction_availability.dart';
import 'package:wow100/data/models/achievement_faction_equivalents.dart';
import 'package:wow100/data/models/achievement_group_hierarchy.dart';
import 'package:wow100/data/models/tracking_category.dart';
import 'package:wow100/data/repositories/battle_net_repository.dart';

import '../../../../core/ads/app_ads.dart';
import '../../../../core/services/local_check_service.dart';
import '../../../../core/services/selected_character_service.dart';
import '../../../../core/services/wowhead_url_builder.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/expansion_palette.dart';
import '../../../../core/widgets/web_sponsor_panel.dart';
import '../../../../data/models/tracking_item.dart';
import '../../../../data/models/wow_character.dart';
import '../../../../data/models/wow_expansion.dart';
import '../../../../data/models/wow_region_filter.dart';
import '../../../../data/repositories/planner_repository.dart';
import '../widgets/region_selector_sheet.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({
    super.key,
    required this.extension,
    this.category,
    this.regionFilter,
    this.newestFirst = false,
  });

  final WowExpansion extension;
  final TrackingCategory? category;
  final WowRegionFilter? regionFilter;
  final bool newestFirst;

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final PlannerRepository _repository = JsonPlannerRepository();
  final LocalCheckService _localCheckService = LocalCheckService();
  final SelectedCharacterService _selectedCharacterService =
      SelectedCharacterService();
  final Set<String> _collapsedGroups = {};

  static const List<String> _preferredMountGroups = [
    'A classer',
    'Butin',
    'Vendeur',
    'Réputation',
    'Quête',
    'Haut-fait',
    'Métier',
    'Événement mondial',
    'Divers',
    'Cartes à collectionner',
    'Boutique',
    'PvP coté',
    'Promotion Blizzard',
    'Exploration des îles',
    'Secret',
    'Congrégation',
    'Comptoir',
    'Non implémenté',
    'Retirées / indisponibles',
    'Inconnu',
    'A vérifier',
  ];

  List<TrackingItem> _items = [];
  bool _isLoading = true;
  bool _missingOnly = true;
  bool _hideUnavailable = true;
  String _searchQuery = '';
  WowCharacter? _selectedCharacter;
  String? _selectedCharacterFaction;
  final Set<TrackingCategory> _selectedCategories = {};
  final Set<String> _selectedGroups = {};
  WowRegionFilter? _selectedRegionFilter;

  bool get _isPetsPlanner =>
      widget.category == TrackingCategory.pets ||
      widget.extension == WowExpansion.allPets;

  bool get _isAchievementsPlanner =>
      widget.category == TrackingCategory.achievements ||
      widget.extension == WowExpansion.allAchievements;

  bool get _isExtensionPlanner =>
      widget.category == null &&
      widget.extension != WowExpansion.allAchievements &&
      widget.extension != WowExpansion.allMounts &&
      widget.extension != WowExpansion.allPets;

  bool get _isAllCollectionPlanner =>
      widget.category == null &&
      (widget.extension == WowExpansion.allAchievements ||
          widget.extension == WowExpansion.allMounts ||
          widget.extension == WowExpansion.allPets);

  bool get _isAllAchievementsPlanner =>
      widget.extension == WowExpansion.allAchievements;

  bool get _usesInlineRegionFilter =>
      _isAllCollectionPlanner || _isAllAchievementsPlanner;

  bool get _tracksAchievements => _isExtensionPlanner || _isAchievementsPlanner;

  bool get _tracksMounts =>
      _isExtensionPlanner ||
      widget.category == TrackingCategory.mounts ||
      widget.extension == WowExpansion.allMounts;

  bool get _tracksPets => _isExtensionPlanner || _isPetsPlanner;

  TrackingCategory? get _regionSelectorCategoryScope {
    if (widget.extension == WowExpansion.allAchievements) {
      return TrackingCategory.achievements;
    }
    if (widget.extension == WowExpansion.allMounts) {
      return TrackingCategory.mounts;
    }
    if (widget.extension == WowExpansion.allPets) {
      return TrackingCategory.pets;
    }

    return null;
  }

  bool get _showsRegionFilter =>
      _isExtensionPlanner ||
      _usesInlineRegionFilter ||
      _selectedRegionFilter != null;

  String get _regionFilterLabelText {
    if (_isAllAchievementsPlanner) return 'Par région (En construction ^^)';
    if (_isAllCollectionPlanner) {
      return 'Recherche par régions (en construction)';
    }

    return 'Région';
  }

  String get _regionFilterEmptyLabel {
    if (_isAllAchievementsPlanner) return 'Toutes les régions';
    if (_isAllCollectionPlanner) return 'Toutes les extensions';

    return 'Toutes les régions (En construction ^^)';
  }

  String get _collectionName {
    if (_isExtensionPlanner) return 'collectables';
    if (_isAchievementsPlanner) return 'hauts faits';
    if (_isPetsPlanner) return 'mascottes';

    return 'montures';
  }

  String get _allCollectionTitle {
    if (_isAchievementsPlanner) return 'Tous les hauts faits';
    if (_isPetsPlanner) return 'Toutes les mascottes';

    return 'Toutes les montures';
  }

  String get _plannerTitle {
    final regionFilter = _selectedRegionFilter;
    if (regionFilter != null) return 'Planner de ${regionFilter.zone}';

    if (_isExtensionPlanner) return 'Collectables de ${widget.extension.label}';
    if (_isAchievementsPlanner) return 'Hauts Faits';
    if (_isPetsPlanner) return 'Mascottes à récupérer';

    return 'Montures à récupérer';
  }

  Future<void> _openRegionSelector() async {
    final result = await showModalBottomSheet<WowRegionFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RegionSelectorSheet(
        repository: _repository,
        newestFirst: widget.newestFirst,
        selectedRegion: _selectedRegionFilter,
        expansionScope: _isExtensionPlanner ? widget.extension : null,
        categoryScope: _regionSelectorCategoryScope,
      ),
    );

    if (result == null || !mounted) return;

    if (_usesInlineRegionFilter) {
      setState(() {
        _selectedRegionFilter = result;
        _searchQuery = '';
        _selectedGroups.clear();
        _collapsedGroups.clear();
      });
      return;
    }

    if (result.expansion != widget.extension || widget.category != null) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PlannerPage(
            extension: result.expansion,
            regionFilter: result,
            newestFirst: widget.newestFirst,
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedRegionFilter = result;
      _searchQuery = '';
      _selectedCategories.clear();
      _selectedGroups.clear();
      _collapsedGroups.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedRegionFilter = widget.regionFilter;
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _repository.getItems(
        widget.extension,
        category: widget.category,
      );
      final token = await BattleNetTokenService().loadToken();
      final ownedMountIds = <int>{};
      final ownedPetIds = <int>{};
      final ownedAchievementIds = <int>{};
      final character = await _selectedCharacterService.loadCharacter();

      if (token != null) {
        if (_tracksAchievements) {
          try {
            final accountAchievements = await BattleNetRepository()
                .getAccountAchievements(token);
            ownedAchievementIds.addAll(
              accountAchievements.map((achievement) => achievement.id),
            );
          } catch (e, stack) {
            debugPrint('BATTLE.NET ACCOUNT ACHIEVEMENTS ERROR: $e');
            debugPrint('$stack');
          }

          if (character != null) {
            try {
              final achievements = await BattleNetRepository().getAchievements(
                token,
                character.realmSlug,
                character.name,
              );
              ownedAchievementIds.addAll(
                achievements.map((achievement) => achievement.id),
              );
            } catch (e, stack) {
              debugPrint('BATTLE.NET CHARACTER ACHIEVEMENTS ERROR: $e');
              debugPrint('$stack');
            }
          }
        }

        if (_tracksPets) {
          final pets = await BattleNetRepository().getPets(token);
          ownedPetIds.addAll(pets.map((pet) => pet.id));
        }

        if (_tracksMounts) {
          final mounts = await BattleNetRepository().getMounts(token);
          ownedMountIds.addAll(mounts.map((mount) => mount.id));
        }
      }

      final expandedOwnedAchievementIds = AchievementFactionEquivalents.expand(
        ownedAchievementIds,
      );
      final checkedItemIds = await _localCheckService.checkedItemIds(
        items.map((item) => item.id),
      );
      final checkedAchievementIds = <int>{};

      for (final item in items) {
        if (checkedItemIds.contains(item.id) &&
            item.category == TrackingCategory.achievements &&
            item.blizzardId != null) {
          checkedAchievementIds.add(item.blizzardId!);
        }
      }

      final expandedCheckedAchievementIds =
          AchievementFactionEquivalents.expand(checkedAchievementIds);
      final updatedItems = <TrackingItem>[];

      for (final item in items) {
        final checked =
            checkedItemIds.contains(item.id) ||
            (item.category == TrackingCategory.achievements &&
                item.blizzardId != null &&
                expandedCheckedAchievementIds.contains(item.blizzardId));
        final ownedMount =
            item.category == TrackingCategory.mounts &&
            item.blizzardId != null &&
            ownedMountIds.contains(item.blizzardId);
        final ownedPet =
            item.category == TrackingCategory.pets &&
            item.blizzardId != null &&
            ownedPetIds.contains(item.blizzardId);
        final ownedAchievement =
            item.category == TrackingCategory.achievements &&
            item.blizzardId != null &&
            expandedOwnedAchievementIds.contains(item.blizzardId);

        updatedItems.add(
          item.copyWith(
            obtained: checked || ownedMount || ownedPet || ownedAchievement,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _items = updatedItems;
        _selectedCharacter = character;
        _selectedCharacterFaction = character?.faction;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('ERREUR PLANNER: $e');
      debugPrint('$stack');

      if (!mounted) return;

      setState(() {
        _items = [];
        _isLoading = false;
      });
    }
  }

  List<String> _groupOptions() {
    final groups = _items.map(_groupLabel).toSet().toList();

    groups.sort(_compareGroups);
    return groups;
  }

  List<TrackingCategory> _categoryOptions() {
    final categories = _items.map((item) => item.category).toSet().toList();
    const preferredCategories = [
      TrackingCategory.achievements,
      TrackingCategory.mounts,
      TrackingCategory.pets,
    ];

    categories.sort((left, right) {
      final leftIndex = preferredCategories.indexOf(left);
      final rightIndex = preferredCategories.indexOf(right);

      if (leftIndex != -1 && rightIndex != -1) {
        return leftIndex.compareTo(rightIndex);
      }

      if (leftIndex != -1) return -1;
      if (rightIndex != -1) return 1;

      return left.label.compareTo(right.label);
    });

    return categories;
  }

  Map<String, List<TrackingItem>> _groupedItems(List<TrackingItem> items) {
    final groupedItems = <String, List<TrackingItem>>{};

    for (final item in items) {
      final group = _groupLabel(item);
      groupedItems.putIfAbsent(group, () => []).add(item);
    }

    final sortedGroups = groupedItems.keys.toList()..sort(_compareGroups);
    final sortedGroupedItems = <String, List<TrackingItem>>{};

    for (final group in sortedGroups) {
      final groupItems = groupedItems[group] ?? [];
      groupItems.sort((a, b) => a.name.compareTo(b.name));
      sortedGroupedItems[group] = groupItems;
    }

    return sortedGroupedItems;
  }

  String _groupLabel(TrackingItem item) {
    final achievementGroup = AchievementGroupHierarchy.labelFor(item);
    if (achievementGroup != null) return achievementGroup;

    final group = item.instance.trim();

    if (group.isEmpty || group == 'A verifier') {
      return 'A vérifier';
    }

    if (group == 'Drop') {
      return 'Butin';
    }

    if (group == 'TCG') {
      return 'Cartes à collectionner';
    }

    if (group == 'Promotion') {
      return 'Promotion Blizzard';
    }

    if (group == 'Secrets') {
      return 'Secret';
    }

    if (group == 'Retirees / indisponibles') {
      return 'Retirées / indisponibles';
    }

    return group;
  }

  int _compareGroups(String left, String right) {
    final achievementCompare = AchievementGroupHierarchy.compare(left, right);
    if (achievementCompare != null) return achievementCompare;

    final leftIndex = _preferredMountGroups.indexOf(left);
    final rightIndex = _preferredMountGroups.indexOf(right);

    if (leftIndex != -1 && rightIndex != -1) {
      return leftIndex.compareTo(rightIndex);
    }

    if (leftIndex != -1) return -1;
    if (rightIndex != -1) return 1;

    return left.compareTo(right);
  }

  Future<void> _setChecked(TrackingItem item, bool checked) async {
    final affectedItemIds = _items
        .where(
          (current) =>
              current.id == item.id ||
              (item.category == TrackingCategory.achievements &&
                  current.category == TrackingCategory.achievements &&
                  AchievementFactionEquivalents.areEquivalent(
                    item.blizzardId,
                    current.blizzardId,
                  )),
        )
        .map((current) => current.id)
        .toSet();

    for (final itemId in affectedItemIds) {
      await _localCheckService.setChecked(itemId, checked);
    }

    if (!mounted) return;

    setState(() {
      _items = _items.map((current) {
        if (affectedItemIds.contains(current.id)) {
          return current.copyWith(obtained: checked);
        }

        return current;
      }).toList();
    });
  }

  void _toggleGroup(String group) {
    setState(() {
      if (_collapsedGroups.contains(group)) {
        _collapsedGroups.remove(group);
      } else {
        _collapsedGroups.add(group);
      }
    });
  }

  void _clearRegionFilter() {
    setState(() {
      _selectedRegionFilter = null;
      _collapsedGroups.clear();
    });
  }

  Future<void> _openGroupSelector(List<String> groupOptions) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GroupFilterSheet(
        options: groupOptions,
        selectedGroups: _selectedGroups,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedGroups
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _openCategorySelector(
    List<TrackingCategory> categoryOptions,
  ) async {
    final result = await showModalBottomSheet<Set<TrackingCategory>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryFilterSheet(
        options: categoryOptions,
        selectedCategories: _selectedCategories,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedCategories
        ..clear()
        ..addAll(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupOptions = _groupOptions();
    final categoryOptions = _categoryOptions();

    final filteredItems = _items.where((item) {
      final group = _groupLabel(item);
      final matchesCategory =
          !_isExtensionPlanner ||
          _selectedCategories.isEmpty ||
          _selectedCategories.contains(item.category);
      final matchesGroup =
          _selectedGroups.isEmpty || _selectedGroups.contains(group);
      final matchesRegion =
          _selectedRegionFilter == null || _selectedRegionFilter!.matches(item);
      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.world.toLowerCase().contains(query) ||
          item.region.toLowerCase().contains(query) ||
          item.zone.toLowerCase().contains(query) ||
          item.subzone.toLowerCase().contains(query) ||
          group.toLowerCase().contains(query) ||
          item.instance.toLowerCase().contains(query) ||
          item.source.toLowerCase().contains(query);

      final matchesMissingOnly = !_missingOnly || !item.obtained;
      final unavailableForFaction =
          AchievementFactionAvailability.isUnavailableForFaction(
            item,
            _selectedCharacterFaction,
          );
      final matchesAvailability =
          !_hideUnavailable || (!item.unavailable && !unavailableForFaction);

      return matchesCategory &&
          matchesRegion &&
          matchesGroup &&
          matchesSearch &&
          matchesMissingOnly &&
          matchesAvailability;
    }).toList();

    final groupedItems = _groupedItems(filteredItems);
    final obtainedCount = filteredItems.where((item) => item.obtained).length;
    final totalCount = filteredItems.length;
    final progress = totalCount == 0 ? 0.0 : obtainedCount / totalCount;
    final progressPercent = totalCount == 0 ? 0 : (progress * 100).round();
    final listEntries = <_PlannerListEntry>[];

    for (final entry in groupedItems.entries) {
      listEntries.add(_PlannerListEntry.group(entry.key, entry.value.length));

      if (!_collapsedGroups.contains(entry.key)) {
        listEntries.addAll(entry.value.map(_PlannerListEntry.item));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: _PlannerAppBarTitle(
          title: _selectedRegionFilter?.zone ?? widget.extension.label,
          character: _selectedCharacter,
        ),
        actions: [
          IconButton(
            tooltip: 'Tout décocher',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _localCheckService.clearCheckedItems(
                _items.map((item) => item.id),
              );

              if (!mounted) return;

              setState(() {
                _items = _items
                    .map((item) => item.copyWith(obtained: false))
                    .toList();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : WebSponsorSliverPageBody(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.extension == WowExpansion.allMounts ||
                                widget.extension == WowExpansion.allPets ||
                                widget.extension == WowExpansion.allAchievements
                            ? _allCollectionTitle
                            : _plannerTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText:
                              'Rechercher (ex : extension, nom, réputation, etc ...)',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_showsRegionFilter) ...[
                        _RegionFilterField(
                          selectedRegion: _selectedRegionFilter,
                          labelText: _regionFilterLabelText,
                          emptyLabel: _regionFilterEmptyLabel,
                          onTap: _openRegionSelector,
                          onClear: _selectedRegionFilter == null
                              ? null
                              : _clearRegionFilter,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_isExtensionPlanner) ...[
                        _CategoryFilterField(
                          selectedCategories: _selectedCategories,
                          onTap: () => _openCategorySelector(categoryOptions),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _GroupFilterField(
                        selectedGroups: _selectedGroups,
                        onTap: () => _openGroupSelector(groupOptions),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _PlannerFilterSwitch(
                            value: _missingOnly,
                            title: 'Afficher uniquement les manquants',
                            subtitle:
                                'Masquer les $_collectionName déjà obtenues',
                            onChanged: (value) {
                              setState(() {
                                _missingOnly = value;
                              });
                            },
                          ),
                          _PlannerFilterSwitch(
                            value: _hideUnavailable,
                            title: 'Masquer les indisponibles',
                            subtitle:
                                'Retirer les sources qui ne sont plus obtenables',
                            onChanged: (value) {
                              setState(() {
                                _hideUnavailable = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$obtainedCount / $totalCount obtenus',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$progressPercent %',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const AppNativeAd(),
                      if (filteredItems.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              'Aucune $_collectionName ne correspond à cette recherche.',
                              style: const TextStyle(color: AppTheme.mutedText),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = listEntries[index];
                    final groupTitle = entry.groupTitle;

                    if (groupTitle != null) {
                      return _PlannerGroupHeader(
                        title: groupTitle,
                        count: entry.groupCount,
                        isCollapsed: _collapsedGroups.contains(groupTitle),
                        onToggle: () => _toggleGroup(groupTitle),
                      );
                    }

                    final item = entry.item!;
                    return _PlannerItemCard(
                      item: item,
                      onChanged: (value) => _setChecked(item, value ?? false),
                    );
                  }, childCount: listEntries.length),
                ),
              ],
            ),
    );
  }
}

class _PlannerListEntry {
  const _PlannerListEntry.group(this.groupTitle, this.groupCount) : item = null;

  const _PlannerListEntry.item(this.item) : groupTitle = null, groupCount = 0;

  final String? groupTitle;
  final int groupCount;
  final TrackingItem? item;
}

class _PlannerAppBarTitle extends StatelessWidget {
  const _PlannerAppBarTitle({required this.title, required this.character});

  final String title;
  final WowCharacter? character;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showReminder = character != null && constraints.maxWidth >= 340;
        final titleMaxWidth = showReminder
            ? ((constraints.maxWidth - 256) / 2).clamp(
                72.0,
                constraints.maxWidth,
              )
            : constraints.maxWidth;

        return SizedBox(
          height: kToolbarHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: titleMaxWidth,
                  child: Text(title, overflow: TextOverflow.ellipsis),
                ),
              ),
              if (showReminder)
                Center(
                  child: _SelectedCharacterReminder(character: character!),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectedCharacterReminder extends StatelessWidget {
  const _SelectedCharacterReminder({required this.character});

  final WowCharacter character;

  @override
  Widget build(BuildContext context) {
    final faction = _plannerIdentityKey(character.faction);
    final flagAsset = switch (faction) {
      'alliance' => 'assets/images/bann/bann_perso_alliance.png',
      'horde' => 'assets/images/bann/bann_perso_horde.png',
      _ => null,
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.background.withAlpha(200),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.gold.withAlpha(105)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (flagAsset != null) ...[
                _FactionFlag(asset: flagAsset),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  character.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactionFlag extends StatelessWidget {
  const _FactionFlag({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Container(
        foregroundDecoration: BoxDecoration(
          border: Border.all(color: AppTheme.gold.withAlpha(120)),
        ),
        child: SizedBox(
          width: 34,
          height: 22,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
}

String _plannerIdentityKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('Ã ', 'a')
      .replaceAll('Ã¢', 'a')
      .replaceAll('Ã¤', 'a')
      .replaceAll('Ã§', 'c')
      .replaceAll('Ã©', 'e')
      .replaceAll('Ã¨', 'e')
      .replaceAll('Ãª', 'e')
      .replaceAll('Ã«', 'e')
      .replaceAll('Ã®', 'i')
      .replaceAll('Ã¯', 'i')
      .replaceAll('Ã´', 'o')
      .replaceAll('Ã¶', 'o')
      .replaceAll('Ã¹', 'u')
      .replaceAll('Ã»', 'u')
      .replaceAll('Ã¼', 'u');
}

class _PlannerGroupHeader extends StatelessWidget {
  const _PlannerGroupHeader({
    required this.title,
    required this.count,
    required this.isCollapsed,
    required this.onToggle,
  });

  final String title;
  final int count;
  final bool isCollapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: isCollapsed ? 'Déplier' : 'Replier',
            onPressed: onToggle,
            icon: Icon(
              isCollapsed
                  ? Icons.keyboard_arrow_right
                  : Icons.keyboard_arrow_down,
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '$title ($count)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.gold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerFilterSwitch extends StatelessWidget {
  const _PlannerFilterSwitch({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Row(
        children: [
          Switch(value: value, onChanged: onChanged),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionFilterField extends StatelessWidget {
  const _RegionFilterField({
    required this.selectedRegion,
    required this.onTap,
    this.labelText = 'Région',
    this.emptyLabel = 'Toutes les régions (En construction ^^)',
    this.onClear,
  });

  final WowRegionFilter? selectedRegion;
  final VoidCallback onTap;
  final String labelText;
  final String emptyLabel;
  final VoidCallback? onClear;

  String get _label {
    final region = selectedRegion;
    if (region == null) return emptyLabel;

    return region.fullLabel;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            const Icon(Icons.travel_explore, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            if (selectedRegion != null && onClear != null) ...[
              IconButton(
                tooltip: 'Retirer le filtre',
                visualDensity: VisualDensity.compact,
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }
}

class _GroupFilterField extends StatelessWidget {
  const _GroupFilterField({required this.selectedGroups, required this.onTap});

  final Set<String> selectedGroups;
  final VoidCallback onTap;

  String get _label {
    if (selectedGroups.isEmpty) {
      return 'Tous les groupes';
    }

    if (selectedGroups.length <= 2) {
      return selectedGroups.join(', ');
    }

    return '${selectedGroups.length} groupes sélectionnés';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Groupes',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (selectedGroups.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                selectedGroups.length.toString(),
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterField extends StatelessWidget {
  const _CategoryFilterField({
    required this.selectedCategories,
    required this.onTap,
  });

  final Set<TrackingCategory> selectedCategories;
  final VoidCallback onTap;

  String get _label {
    if (selectedCategories.isEmpty) {
      return 'HF, Montures, Mascottes';
    }

    if (selectedCategories.length <= 2) {
      return selectedCategories
          .map((category) => category.shortLabel)
          .join(', ');
    }

    return '${selectedCategories.length} catégories sélectionnées';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Catégories',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (selectedCategories.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                selectedCategories.length.toString(),
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterSheet extends StatefulWidget {
  const _CategoryFilterSheet({
    required this.options,
    required this.selectedCategories,
  });

  final List<TrackingCategory> options;
  final Set<TrackingCategory> selectedCategories;

  @override
  State<_CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<_CategoryFilterSheet> {
  late final Set<TrackingCategory> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = {...widget.selectedCategories};
  }

  void _toggle(TrackingCategory category, bool selected) {
    setState(() {
      if (selected) {
        _tempSelected.add(category);
      } else {
        _tempSelected.remove(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.65,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Catégories',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tempSelected.clear();
                      });
                    },
                    child: const Text('Tout effacer'),
                  ),
                ],
              ),
            ),
            CheckboxListTile(
              value: _tempSelected.isEmpty,
              title: const Text('Toutes les catégories'),
              subtitle: const Text('HF, montures et mascottes'),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (_) {
                setState(() {
                  _tempSelected.clear();
                });
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  final category = widget.options[index];
                  final selected = _tempSelected.contains(category);

                  return CheckboxListTile(
                    value: selected,
                    title: Text(category.label),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) => _toggle(category, value ?? false),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _tempSelected),
                  child: Text(
                    _tempSelected.isEmpty
                        ? 'Afficher toutes les catégories'
                        : 'Appliquer ${_tempSelected.length} catégorie(s)',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupFilterSheet extends StatefulWidget {
  const _GroupFilterSheet({
    required this.options,
    required this.selectedGroups,
  });

  final List<String> options;
  final Set<String> selectedGroups;

  @override
  State<_GroupFilterSheet> createState() => _GroupFilterSheetState();
}

class _GroupFilterSheetState extends State<_GroupFilterSheet> {
  late final Set<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = {...widget.selectedGroups};
  }

  void _toggle(String group, bool selected) {
    setState(() {
      if (selected) {
        _tempSelected.add(group);
      } else {
        _tempSelected.remove(group);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Groupes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tempSelected.clear();
                      });
                    },
                    child: const Text('Tout effacer'),
                  ),
                ],
              ),
            ),
            CheckboxListTile(
              value: _tempSelected.isEmpty,
              title: const Text('Tous les groupes'),
              subtitle: const Text('Aucun groupe filtré'),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (_) {
                setState(() {
                  _tempSelected.clear();
                });
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  final group = widget.options[index];
                  final selected = _tempSelected.contains(group);

                  return CheckboxListTile(
                    value: selected,
                    title: Text(group),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) => _toggle(group, value ?? false),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _tempSelected),
                  child: Text(
                    _tempSelected.isEmpty
                        ? 'Afficher tous les groupes'
                        : 'Appliquer ${_tempSelected.length} groupe(s)',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerItemCard extends StatelessWidget {
  const _PlannerItemCard({required this.item, required this.onChanged});

  final TrackingItem item;
  final ValueChanged<bool?> onChanged;

  String _wowheadUrl(BuildContext context) {
    if (item.wowheadUrl.isNotEmpty) return item.wowheadUrl;

    final locale = WowheadUrlBuilder.preferredLocaleCode(
      WidgetsBinding.instance.platformDispatcher.locales.map(
        (locale) => locale.toLanguageTag(),
      ),
      fallback: Localizations.localeOf(context).languageCode,
    );

    return WowheadUrlBuilder.build(
      item: item,
      locale: item.category == TrackingCategory.mounts ? 'fr' : locale,
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }

  List<_PlannerTag> _metadataTags() {
    final difficultyTag = _difficultyTag();
    final extensionTag = _extensionTag();
    final regionLabel = _regionLabel();

    return [
      ?difficultyTag,
      ?extensionTag,
      if (regionLabel != null) _PlannerTag(label: regionLabel),
    ];
  }

  _PlannerTag? _difficultyTag() {
    final label = item.difficulty.trim();
    if (!_hasUsefulMetadataLabel(label)) return null;

    final normalized = WowRegionFilter.normalize(label);
    if (item.unavailable && normalized == 'indisponible') return null;

    final colors = _difficultyColors(normalized);

    return _PlannerTag(
      label: label,
      backgroundColor: colors.$1,
      foregroundColor: colors.$2,
    );
  }

  _PlannerTag? _extensionTag() {
    if (item.expansion == WowExpansion.total ||
        item.expansion == WowExpansion.allMounts ||
        item.expansion == WowExpansion.allAchievements ||
        item.expansion == WowExpansion.allPets) {
      return null;
    }

    final label = item.expansion.label;
    if (!_hasUsefulMetadataLabel(label)) return null;

    final colors = ExpansionPalette.tagColors(item.expansion);
    return _PlannerTag(
      label: label,
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
    );
  }

  String? _regionLabel() {
    for (final label in [item.zone, item.region]) {
      final trimmed = label.trim();
      if (_hasUsefulMetadataLabel(trimmed)) return trimmed;
    }

    return null;
  }

  bool _hasUsefulMetadataLabel(String value) {
    final normalized = WowRegionFilter.normalize(value);

    return normalized.isNotEmpty &&
        normalized != 'sans zone' &&
        normalized != 'a definir' &&
        normalized != 'unknown' &&
        normalized != 'source a verifier';
  }

  (Color, Color) _difficultyColors(String normalizedDifficulty) {
    if (normalizedDifficulty.contains('facile')) {
      return (const Color(0xFF14532D), const Color(0xFF86EFAC));
    }
    if (normalizedDifficulty.contains('moyen')) {
      return (const Color(0xFF713F12), const Color(0xFFFDE68A));
    }
    if (normalizedDifficulty.contains('difficile')) {
      return (const Color(0xFF7F1D1D), const Color(0xFFFCA5A5));
    }
    if (normalizedDifficulty.contains('indisponible')) {
      return (const Color(0xFF7F1D1D), const Color(0xFFFEE2E2));
    }
    if (normalizedDifficulty.contains('reel') ||
        normalizedDifficulty.contains('argent')) {
      return (const Color(0xFF312E81), const Color(0xFFC7D2FE));
    }

    return (const Color(0xFF334155), const Color(0xFFE2E8F0));
  }

  @override
  Widget build(BuildContext context) {
    final isMount = item.category == TrackingCategory.mounts;
    final mamytwinkUrl = item.mamytwinkUrl.trim();
    final wowheadUrl = _wowheadUrl(context);
    final groupLabel =
        AchievementGroupHierarchy.labelFor(item) ?? item.instance;
    final tags = [
      if (item.unavailable)
        const _PlannerTag(
          label: 'Indisponible',
          backgroundColor: Color(0xFF7F1D1D),
          foregroundColor: Color(0xFFFEE2E2),
        ),
      _PlannerTag(label: item.category.label),
      ..._metadataTags(),
      _PlannerTag(label: item.weeklyLockout ? 'Hebdomadaire' : 'Farm libre'),
      if (item.groupRequired) const _PlannerTag(label: 'Groupe conseillé'),
      if (item.obtained) const _PlannerTag(label: 'Obtenu'),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: isMount ? 72 : 42,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(value: item.obtained, onChanged: onChanged),
                  if (isMount)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (mamytwinkUrl.isNotEmpty)
                          _MountExternalLinkButton(
                            tooltip: 'Ouvrir sur Mamytwink',
                            onPressed: () => _openUrl(mamytwinkUrl),
                            child: const Text(
                              'M',
                              style: TextStyle(
                                color: Color(0xFF84CC16),
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        _MountExternalLinkButton(
                          tooltip: 'Ouvrir sur Wowhead',
                          onPressed: () => _openUrl(wowheadUrl),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              /*Text(
                                'WH',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),*/
                              SizedBox(width: 1),
                              Icon(Icons.rocket_launch_rounded, size: 12),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    IconButton(
                      tooltip:
                          item.wowheadItemId != null ||
                              item.wowheadAchievementId != null
                          ? 'Ouvrir sur Wowhead'
                          : 'Ouvrir la fiche',
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _openUrl(wowheadUrl),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _PlannerItemArtwork(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      decoration: item.obtained
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      item.expansion.label,
                      if (item.world.isNotEmpty) item.world,
                      if (item.region.isNotEmpty &&
                          WowRegionFilter.normalize(item.region) !=
                              WowRegionFilter.normalize(item.zone))
                        item.region,
                      item.zone,
                      if (item.subzone.isNotEmpty) item.subzone,
                      groupLabel,
                      item.source,
                    ].where((value) => value.isNotEmpty).join(' • '),
                    style: const TextStyle(color: AppTheme.mutedText),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: tags),
                  if (item.boss.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Boss : ${item.boss}',
                      style: const TextStyle(color: AppTheme.mutedText),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MountExternalLinkButton extends StatelessWidget {
  const _MountExternalLinkButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: const EdgeInsets.all(4),
      visualDensity: VisualDensity.compact,
      icon: child,
    );
  }
}

class _PlannerItemArtwork extends StatelessWidget {
  const _PlannerItemArtwork({required this.item});

  static final Map<String, Future<String?>> _mediaUrlCache = {};

  final TrackingItem item;

  Future<String?> _mediaUrl() {
    final blizzardId = item.blizzardId;

    if (blizzardId == null ||
        (item.category != TrackingCategory.mounts &&
            item.category != TrackingCategory.pets)) {
      return Future.value(null);
    }

    final cacheKey = '${item.category.name}:$blizzardId';

    return _mediaUrlCache.putIfAbsent(
      cacheKey,
      () => BattleNetRepository().getCollectibleMediaUrl(
        item.category,
        blizzardId,
      ),
    );
  }

  String _fallbackImageUrl() {
    return switch (item.category) {
      TrackingCategory.mounts =>
        'https://render.worldofwarcraft.com/eu/icons/56/ability_mount_ridinghorse.jpg',
      TrackingCategory.pets =>
        'https://render.worldofwarcraft.com/eu/icons/56/inv_pet_babyblizzardbear.jpg',
      TrackingCategory.achievements =>
        'https://render.worldofwarcraft.com/eu/icons/56/achievement_bg_winwsg.jpg',
      _ =>
        'https://render.worldofwarcraft.com/eu/icons/56/inv_misc_questionmark.jpg',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
          color: Colors.black26,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: FutureBuilder<String?>(
            future: _mediaUrl(),
            builder: (context, snapshot) {
              final imageUrl = snapshot.data ?? _fallbackImageUrl();

              return Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _ArtworkFallbackIcon(item: item),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;

                  return const Center(
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ArtworkFallbackIcon extends StatelessWidget {
  const _ArtworkFallbackIcon({required this.item});

  final TrackingItem item;

  IconData get _icon {
    return switch (item.category) {
      TrackingCategory.mounts => Icons.cruelty_free,
      TrackingCategory.pets => Icons.pets,
      TrackingCategory.achievements => Icons.emoji_events_outlined,
      _ => Icons.auto_awesome,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black26,
      child: Center(child: Icon(_icon, color: AppTheme.gold, size: 28)),
    );
  }
}

class _PlannerTag extends StatelessWidget {
  const _PlannerTag({
    required this.label,
    this.backgroundColor = Colors.white10,
    this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: foregroundColor == null
          ? null
          : TextStyle(color: foregroundColor),
      visualDensity: VisualDensity.compact,
      backgroundColor: backgroundColor,
      side: BorderSide.none,
    );
  }
}
