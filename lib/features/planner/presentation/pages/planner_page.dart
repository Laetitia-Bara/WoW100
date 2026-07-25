import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wow100/core/services/battle_net_token_service.dart';
import 'package:wow100/data/models/achievement_faction_availability.dart';
import 'package:wow100/data/models/achievement_faction_equivalents.dart';
import 'package:wow100/data/models/achievement_group_hierarchy.dart';
import 'package:wow100/data/models/tracking_category.dart';
import 'package:wow100/data/repositories/battle_net_repository.dart';

import '../../../../core/ads/app_ads.dart';
import '../../../../core/services/selected_character_service.dart';
import '../../../../core/services/solo_planner_service.dart';
import '../../../../core/services/wowhead_url_builder.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/expansion_palette.dart';
import '../../../../core/widgets/journey_step_bar.dart';
import '../../../../core/widgets/scrolling_notice_banner.dart';
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
  final SoloPlannerService _soloPlannerService = SoloPlannerService();
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
  Set<String> _soloItemIds = {};
  WowCharacter? _selectedCharacter;
  String? _selectedCharacterFaction;
  final Set<TrackingCategory> _selectedCategories = {};
  final Set<WowExpansion> _selectedExtensions = {};
  final Set<String> _selectedGroups = {};
  final Set<String> _selectedDifficulties = {};
  WowRegionFilter? _selectedRegionFilter;
  int _loadGeneration = 0;
  bool _didApplyInitialGroupCollapse = false;

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
      _isAllCollectionPlanner || _isAllAchievementsPlanner || _isPetsPlanner;

  bool get _tracksAchievements => _isExtensionPlanner || _isAchievementsPlanner;

  bool get _tracksMounts =>
      _isExtensionPlanner ||
      widget.category == TrackingCategory.mounts ||
      widget.extension == WowExpansion.allMounts;

  bool get _tracksPets => _isExtensionPlanner || _isPetsPlanner;

  bool get _usesObtainmentTypeLabels =>
      _tracksMounts || _tracksPets || _tracksAchievements;

  TrackingCategory? get _regionSelectorCategoryScope {
    if (_isPetsPlanner) {
      return TrackingCategory.pets;
    }
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
    if (_isAllCollectionPlanner || _isPetsPlanner) {
      return 'Recherche par régions (en construction)';
    }

    return 'Région';
  }

  String get _regionFilterEmptyLabel {
    if (_isAllAchievementsPlanner) return 'Toutes les régions';
    if (_isAllCollectionPlanner || _isPetsPlanner) return 'Tous les mondes';

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
    final generation = ++_loadGeneration;

    try {
      final items = await _repository.getItems(
        widget.extension,
        category: widget.category,
      );
      final character = await _selectedCharacterService.loadCharacter();
      final soloItemIds = await _soloPlannerService.selectedItemIds();
      final localItems = _applyProgress(items);
      _applyInitialGroupCollapse(localItems);

      if (!mounted || generation != _loadGeneration) return;

      setState(() {
        _items = localItems;
        _soloItemIds = soloItemIds;
        _selectedCharacter = character;
        _selectedCharacterFaction = character?.faction;
        _isLoading = false;
      });

      unawaited(_loadBattleNetProgress(items, character, generation));
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

  void _applyInitialGroupCollapse(List<TrackingItem> items) {
    if (_didApplyInitialGroupCollapse || !_isAllAchievementsPlanner) return;

    _didApplyInitialGroupCollapse = true;
    _collapsedGroups
      ..clear()
      ..addAll(items.map(_groupLabel));
  }

  void _resetFiltersToDefault() {
    _missingOnly = true;
    _hideUnavailable = true;
    _searchQuery = '';
    _selectedCategories.clear();
    _selectedExtensions.clear();
    _selectedGroups.clear();
    _selectedDifficulties.clear();
    _selectedRegionFilter = null;
    _collapsedGroups.clear();
    _didApplyInitialGroupCollapse = false;
  }

  Future<void> _resetFiltersAndRefresh() async {
    setState(() {
      _resetFiltersToDefault();
      _isLoading = true;
    });

    await _loadItems();
  }

  Future<void> _loadBattleNetProgress(
    List<TrackingItem> items,
    WowCharacter? character,
    int generation,
  ) async {
    final token = await BattleNetTokenService().loadToken();
    if (token == null || !mounted || generation != _loadGeneration) return;

    final ownedMountIds = <int>{};
    final ownedPetIds = <int>{};
    final ownedAchievementIds = <int>{};
    final battleNetRepository = BattleNetRepository();

    if (_tracksAchievements) {
      try {
        final accountAchievements = await battleNetRepository
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
          final achievements = await battleNetRepository.getAchievements(
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
      try {
        final pets = await battleNetRepository.getPets(token);
        ownedPetIds.addAll(pets.map((pet) => pet.id));
      } catch (e, stack) {
        debugPrint('BATTLE.NET PETS ERROR: $e');
        debugPrint('$stack');
      }
    }

    if (_tracksMounts) {
      try {
        final mounts = await battleNetRepository.getMounts(token);
        ownedMountIds.addAll(mounts.map((mount) => mount.id));
      } catch (e, stack) {
        debugPrint('BATTLE.NET MOUNTS ERROR: $e');
        debugPrint('$stack');
      }
    }

    final updatedItems = _applyProgress(
      items,
      ownedMountIds: ownedMountIds,
      ownedPetIds: ownedPetIds,
      ownedAchievementIds: ownedAchievementIds,
    );

    if (!mounted || generation != _loadGeneration) return;

    setState(() {
      _items = updatedItems;
    });
  }

  List<TrackingItem> _applyProgress(
    List<TrackingItem> items, {
    Set<int> ownedMountIds = const <int>{},
    Set<int> ownedPetIds = const <int>{},
    Set<int> ownedAchievementIds = const <int>{},
  }) {
    final expandedOwnedAchievementIds = AchievementFactionEquivalents.expand(
      ownedAchievementIds,
    );

    return [
      for (final item in items)
        item.copyWith(
          obtained:
              (item.category == TrackingCategory.mounts &&
                  item.blizzardId != null &&
                  ownedMountIds.contains(item.blizzardId)) ||
              (item.category == TrackingCategory.pets &&
                  item.blizzardId != null &&
                  ownedPetIds.contains(item.blizzardId)) ||
              (item.category == TrackingCategory.achievements &&
                  item.blizzardId != null &&
                  expandedOwnedAchievementIds.contains(item.blizzardId)),
        ),
    ];
  }

  List<String> _groupOptions() {
    final groups = _items.map(_groupLabel).toSet().toList();

    groups.sort(_compareGroups);
    return groups;
  }

  List<WowExpansion> _extensionOptions() {
    final expansions = _items
        .map((item) => item.expansion)
        .where(_isFilterableExpansion)
        .toSet()
        .toList();

    expansions.sort((left, right) => left.index.compareTo(right.index));
    return expansions;
  }

  bool _isFilterableExpansion(WowExpansion expansion) {
    return expansion != WowExpansion.total &&
        expansion != WowExpansion.allAchievements &&
        expansion != WowExpansion.allMounts &&
        expansion != WowExpansion.allPets;
  }

  List<String> _difficultyOptions() {
    final difficulties = _items
        .map(_difficultyFilterLabel)
        .whereType<String>()
        .toSet()
        .toList();

    difficulties.sort(_compareDifficulties);
    return difficulties;
  }

  String? _difficultyLabel(TrackingItem item) {
    final label = item.difficulty.trim();
    if (label.isEmpty) return null;

    final normalized = WowRegionFilter.normalize(label);
    if (normalized.isEmpty ||
        normalized == 'a verifier' ||
        normalized == 'unknown' ||
        normalized == 'source a verifier') {
      return null;
    }

    return label;
  }

  String? _difficultyFilterLabel(TrackingItem item) {
    final label = _difficultyLabel(item);
    if (label != null) return label;

    if (_isPetsPlanner) {
      return 'Non renseignée';
    }

    return null;
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
    if (achievementGroup != null) {
      return _usesFlatAchievementGroups
          ? AchievementGroupHierarchy.rootLabel(achievementGroup)
          : achievementGroup;
    }

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

    return _usesObtainmentTypeLabels
        ? _compactObtainmentTypeLabel(group)
        : group;
  }

  bool get _usesFlatAchievementGroups =>
      _isAllAchievementsPlanner || _usesObtainmentTypeLabels;

  String _compactObtainmentTypeLabel(String label) {
    final separatorIndex = label.indexOf(' > ');
    if (separatorIndex == -1) return label;

    final parentLabel = label.substring(0, separatorIndex).trim();
    return parentLabel.isEmpty ? label : parentLabel;
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

  int _compareDifficulties(String left, String right) {
    const preferred = [
      'Facile',
      'Moyen',
      'Difficile',
      'Indisponible',
      'Argent reel',
    ];
    final leftNormalized = WowRegionFilter.normalize(left);
    final rightNormalized = WowRegionFilter.normalize(right);
    final leftIndex = preferred.indexWhere(
      (value) => WowRegionFilter.normalize(value) == leftNormalized,
    );
    final rightIndex = preferred.indexWhere(
      (value) => WowRegionFilter.normalize(value) == rightNormalized,
    );

    if (leftIndex != -1 || rightIndex != -1) {
      return (leftIndex == -1 ? preferred.length : leftIndex).compareTo(
        rightIndex == -1 ? preferred.length : rightIndex,
      );
    }

    return left.compareTo(right);
  }

  Future<void> _setSoloSelected(TrackingItem item, bool selected) async {
    await _soloPlannerService.setSelected(item.id, selected);

    if (!mounted) return;

    setState(() {
      if (selected) {
        _soloItemIds.add(item.id);
      } else {
        _soloItemIds.remove(item.id);
      }
    });
  }

  void _backToProgress() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openWhishlist() async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SoloPlannerPage()),
    );
  }

  Future<void> _openRoute() async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoutePlannerPage()),
    );
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
        useObtainmentTypeLabels: _usesObtainmentTypeLabels,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedGroups
        ..clear()
        ..addAll(result);
      _collapsedGroups.removeAll(result);
    });
  }

  Future<void> _openExtensionSelector(
    List<WowExpansion> extensionOptions,
  ) async {
    final result = await showModalBottomSheet<Set<WowExpansion>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExtensionFilterSheet(
        options: extensionOptions,
        selectedExtensions: _selectedExtensions,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedExtensions
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _openDifficultySelector(List<String> difficultyOptions) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DifficultyFilterSheet(
        options: difficultyOptions,
        selectedDifficulties: _selectedDifficulties,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedDifficulties
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
    final extensionOptions = _extensionOptions();
    final difficultyOptions = _difficultyOptions();
    final categoryOptions = _categoryOptions();

    final filteredItems = _items.where((item) {
      final group = _groupLabel(item);
      final difficulty = _difficultyFilterLabel(item);
      final matchesCategory =
          !_isExtensionPlanner ||
          _selectedCategories.isEmpty ||
          _selectedCategories.contains(item.category);
      final matchesGroup =
          _selectedGroups.isEmpty || _selectedGroups.contains(group);
      final matchesExtension =
          _selectedExtensions.isEmpty ||
          _selectedExtensions.contains(item.expansion);
      final matchesDifficulty =
          _selectedDifficulties.isEmpty ||
          (difficulty != null && _selectedDifficulties.contains(difficulty));
      final matchesRegion =
          _selectedRegionFilter == null || _selectedRegionFilter!.matches(item);
      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.expansion.label.toLowerCase().contains(query) ||
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
          matchesExtension &&
          matchesGroup &&
          matchesDifficulty &&
          matchesSearch &&
          matchesMissingOnly &&
          matchesAvailability;
    }).toList();

    final groupedItems = _groupedItems(filteredItems);
    final totalCount = filteredItems.length;
    final missingCount = filteredItems.where((item) => !item.obtained).length;
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
            tooltip: 'Réinitialiser les filtres et resynchroniser',
            icon: const Icon(Icons.refresh),
            onPressed: _resetFiltersAndRefresh,
          ),
        ],
        bottom: JourneyStepBar(
          currentStep: 1,
          onStep1: _backToProgress,
          onStep2: _openWhishlist,
          onStep3: _openRoute,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : WebSponsorSliverPageBody(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ScrollingNoticeBanner(
                        message:
                            'ATTENTION : verification manuelle de localisation des items toujours en cours',
                      ),
                      const SizedBox(height: 12),
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
                            if (value.trim().isNotEmpty) {
                              _collapsedGroups.clear();
                            }
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
                      if (extensionOptions.length > 1) ...[
                        _ExtensionFilterField(
                          selectedExtensions: _selectedExtensions,
                          onTap: () => _openExtensionSelector(extensionOptions),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _GroupFilterField(
                        selectedGroups: _selectedGroups,
                        useObtainmentTypeLabels: _usesObtainmentTypeLabels,
                        onTap: () => _openGroupSelector(groupOptions),
                      ),
                      const SizedBox(height: 12),
                      if (difficultyOptions.isNotEmpty) ...[
                        _DifficultyFilterField(
                          selectedDifficulties: _selectedDifficulties,
                          onTap: () =>
                              _openDifficultySelector(difficultyOptions),
                        ),
                        const SizedBox(height: 12),
                      ],
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
                        _missingSummary(missingCount, totalCount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
                      selectedForSolo: _soloItemIds.contains(item.id),
                      selectionTagLabel: 'Whishlist',
                      onChanged: (value) =>
                          _setSoloSelected(item, value ?? false),
                    );
                  }, childCount: listEntries.length),
                ),
              ],
            ),
    );
  }

  String _missingSummary(int missingCount, int totalCount) {
    if (totalCount == 0) return 'Aucun item dans cette selection';
    if (missingCount == 0) return 'Il ne te manque aucun item';
    if (missingCount == 1) return 'Il te manque 1 item';

    return 'Il te manque $missingCount items';
  }
}

class SoloPlannerPage extends StatefulWidget {
  const SoloPlannerPage({super.key});

  @override
  State<SoloPlannerPage> createState() => _SoloPlannerPageState();
}

enum _SoloPlannerSortMode { location, category }

enum _AdventureCrewMode { solo, friends }

class _SoloPlannerPageState extends State<SoloPlannerPage> {
  final PlannerRepository _repository = JsonPlannerRepository();
  final SoloPlannerService _soloPlannerService = SoloPlannerService();
  final Set<String> _collapsedGroups = {};

  List<TrackingItem> _items = [];
  Set<String> _todayItemIds = {};
  bool _isLoading = true;
  String _searchQuery = '';
  _SoloPlannerSortMode _sortMode = _SoloPlannerSortMode.location;
  _AdventureCrewMode _crewMode = _AdventureCrewMode.solo;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    final soloItemIds = await _soloPlannerService.selectedItemIds();
    final todayItemIds = await _soloPlannerService.selectedTodayItemIds(
      soloItemIds,
    );
    final allCatalogItems = await Future.wait([
      _repository.getItems(
        WowExpansion.allAchievements,
        category: TrackingCategory.achievements,
      ),
      _repository.getItems(WowExpansion.allMounts),
      _repository.getItems(
        WowExpansion.allPets,
        category: TrackingCategory.pets,
      ),
    ]);

    final selectedItemsById = <String, TrackingItem>{};

    for (final catalogItems in allCatalogItems) {
      for (final item in catalogItems) {
        if (soloItemIds.contains(item.id)) {
          selectedItemsById.putIfAbsent(item.id, () => item);
        }
      }
    }

    final selectedItems = selectedItemsById.values.toList();

    if (!mounted) return;

    setState(() {
      _items = selectedItems;
      _todayItemIds = todayItemIds;
      _isLoading = false;
    });
  }

  int _compareCategoryItems(TrackingItem left, TrackingItem right) {
    final categoryCompare = left.category.index.compareTo(right.category.index);
    if (categoryCompare != 0) return categoryCompare;

    final expansionCompare = left.expansion.index.compareTo(
      right.expansion.index,
    );
    if (expansionCompare != 0) return expansionCompare;

    return left.name.compareTo(right.name);
  }

  int _compareLocationItems(TrackingItem left, TrackingItem right) {
    final locationCompare = _locationGroupLabel(
      left,
    ).compareTo(_locationGroupLabel(right));
    if (locationCompare != 0) return locationCompare;

    final categoryCompare = left.category.index.compareTo(right.category.index);
    if (categoryCompare != 0) return categoryCompare;

    return left.name.compareTo(right.name);
  }

  int _compareItems(TrackingItem left, TrackingItem right) {
    return switch (_sortMode) {
      _SoloPlannerSortMode.location => _compareLocationItems(left, right),
      _SoloPlannerSortMode.category => _compareCategoryItems(left, right),
    };
  }

  String _groupLabel(TrackingItem item) {
    return switch (_sortMode) {
      _SoloPlannerSortMode.location => _locationGroupLabel(item),
      _SoloPlannerSortMode.category => item.category.label,
    };
  }

  String _locationGroupLabel(TrackingItem item) {
    final values = [item.world, item.region, item.zone];
    final uniqueValues = <String>[];
    final seen = <String>{};

    for (final value in values) {
      final trimmed = value.trim();
      if (!_hasUsefulLocationLabel(trimmed)) continue;

      final normalized = WowRegionFilter.normalize(trimmed);
      if (normalized.isEmpty || !seen.add(normalized)) continue;

      uniqueValues.add(trimmed);
    }

    if (uniqueValues.isEmpty) return TrackingItem.unknownZone;

    return uniqueValues.join(' > ');
  }

  bool _hasUsefulLocationLabel(String value) {
    final normalized = WowRegionFilter.normalize(value);

    return normalized.isNotEmpty &&
        normalized != WowRegionFilter.normalize(TrackingItem.unknownZone) &&
        normalized != 'unknown' &&
        normalized != 'a definir';
  }

  Map<String, List<TrackingItem>> _groupedItems(List<TrackingItem> items) {
    final groupedItems = <String, List<TrackingItem>>{};

    for (final item in items) {
      groupedItems.putIfAbsent(_groupLabel(item), () => []).add(item);
    }

    return groupedItems;
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

  void _setSortMode(_SoloPlannerSortMode sortMode) {
    if (_sortMode == sortMode) return;

    setState(() {
      _sortMode = sortMode;
      _collapsedGroups.clear();
    });
  }

  Future<void> _setTodaySelected(TrackingItem item, bool selected) async {
    await _soloPlannerService.setTodaySelected(item.id, selected);

    if (!mounted) return;

    setState(() {
      if (selected) {
        _todayItemIds.add(item.id);
      } else {
        _todayItemIds.remove(item.id);
      }
    });
  }

  Future<void> _clearTodaySelection() async {
    await _soloPlannerService.clearTodaySelected();

    if (!mounted) return;

    setState(_todayItemIds.clear);
  }

  Future<void> _selectAllToday() async {
    final allItemIds = _items.map((item) => item.id).toSet();
    await _soloPlannerService.setAllTodaySelected(allItemIds);

    if (!mounted) return;

    setState(() {
      _todayItemIds = allItemIds;
    });
  }

  void _backToProgress() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openRoute() async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoutePlannerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase();
    final filteredItems = _items.where((item) {
      if (query.isEmpty) return true;

      return item.name.toLowerCase().contains(query) ||
          item.expansion.label.toLowerCase().contains(query) ||
          item.category.label.toLowerCase().contains(query) ||
          item.zone.toLowerCase().contains(query) ||
          item.region.toLowerCase().contains(query) ||
          item.instance.toLowerCase().contains(query) ||
          item.source.toLowerCase().contains(query);
    }).toList()..sort(_compareItems);
    final groupedItems = _groupedItems(filteredItems);
    final listEntries = <_PlannerListEntry>[];

    for (final entry in groupedItems.entries) {
      listEntries.add(_PlannerListEntry.group(entry.key, entry.value.length));

      if (!_collapsedGroups.contains(entry.key)) {
        listEntries.addAll(entry.value.map(_PlannerListEntry.item));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Whishlist'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
          ),
        ],
        bottom: JourneyStepBar(
          currentStep: 2,
          onStep1: _backToProgress,
          onStep2: () {},
          onStep3: _openRoute,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : WebSponsorSliverPageBody(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ScrollingNoticeBanner(
                        message:
                            'ATTENTION : verification manuelle de localisation des items toujours en cours',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Organise ta whishlist',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AdventureCrewPicker(
                        selectedMode: _crewMode,
                        onChanged: (mode) {
                          setState(() {
                            _crewMode = mode;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Rechercher dans ma whishlist',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            if (value.trim().isNotEmpty) {
                              _collapsedGroups.clear();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _SoloPlannerActionBar(
                        countLabel: _soloCountLabel(filteredItems.length),
                        hasTodaySelection: _todayItemIds.isNotEmpty,
                        allItemsSelected: _todayItemIds.length == _items.length,
                        sortMode: _sortMode,
                        onClearSelection: _clearTodaySelection,
                        onSelectAll: _selectAllToday,
                        onOpenRoute: _openRoute,
                        onSortModeChanged: _setSortMode,
                      ),
                      const SizedBox(height: 20),
                      const AppNativeAd(),
                      if (filteredItems.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              _items.isEmpty
                                  ? 'Ta whishlist est vide pour le moment.'
                                  : 'Aucun item ne correspond à cette recherche.',
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
                      selectedForSolo: _todayItemIds.contains(item.id),
                      selectionTagLabel: 'Balade du jour',
                      onChanged: (value) =>
                          _setTodaySelected(item, value ?? false),
                    );
                  }, childCount: listEntries.length),
                ),
              ],
            ),
    );
  }

  String _soloCountLabel(int count) {
    final selectedCount = _todayItemIds.length;
    if (count == 0) return 'Aucun item dans ta whishlist';
    if (count == 1) return '1 item dans ta whishlist - $selectedCount prévu';

    return '$count items dans ta whishlist - $selectedCount prévus';
  }
}

class RoutePlannerPage extends StatefulWidget {
  const RoutePlannerPage({super.key});

  @override
  State<RoutePlannerPage> createState() => _RoutePlannerPageState();
}

class _RoutePlannerPageState extends State<RoutePlannerPage> {
  final PlannerRepository _repository = JsonPlannerRepository();
  final SoloPlannerService _soloPlannerService = SoloPlannerService();
  final SelectedCharacterService _selectedCharacterService =
      SelectedCharacterService();

  List<TrackingItem> _items = [];
  WowCharacter? _selectedCharacter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRouteItems();
  }

  Future<void> _loadRouteItems() async {
    setState(() {
      _isLoading = true;
    });

    final wishlistItemIds = await _soloPlannerService.selectedItemIds();
    final todayItemIds = await _soloPlannerService.selectedTodayItemIds(
      wishlistItemIds,
    );
    final character = await _selectedCharacterService.loadCharacter();
    final allCatalogItems = await Future.wait([
      _repository.getItems(
        WowExpansion.allAchievements,
        category: TrackingCategory.achievements,
      ),
      _repository.getItems(WowExpansion.allMounts),
      _repository.getItems(
        WowExpansion.allPets,
        category: TrackingCategory.pets,
      ),
    ]);

    final selectedItemsById = <String, TrackingItem>{};

    for (final catalogItems in allCatalogItems) {
      for (final item in catalogItems) {
        if (todayItemIds.contains(item.id)) {
          selectedItemsById.putIfAbsent(item.id, () => item);
        }
      }
    }

    final items = selectedItemsById.values.toList()..sort(_compareRouteItems);

    if (!mounted) return;

    setState(() {
      _items = items;
      _selectedCharacter = character;
      _isLoading = false;
    });
  }

  int _compareRouteItems(TrackingItem left, TrackingItem right) {
    final locationCompare = _locationGroupLabel(
      left,
    ).compareTo(_locationGroupLabel(right));
    if (locationCompare != 0) return locationCompare;

    final categoryCompare = left.category.index.compareTo(right.category.index);
    if (categoryCompare != 0) return categoryCompare;

    return left.name.compareTo(right.name);
  }

  Map<String, List<TrackingItem>> _groupedItems() {
    final groupedItems = <String, List<TrackingItem>>{};

    for (final item in _items) {
      groupedItems.putIfAbsent(_locationGroupLabel(item), () => []).add(item);
    }

    return groupedItems;
  }

  String _locationGroupLabel(TrackingItem item) {
    final values = [item.world, item.region, item.zone];
    final uniqueValues = <String>[];
    final seen = <String>{};

    for (final value in values) {
      final trimmed = value.trim();
      if (!_hasUsefulLocationLabel(trimmed)) continue;

      final normalized = WowRegionFilter.normalize(trimmed);
      if (normalized.isEmpty || !seen.add(normalized)) continue;

      uniqueValues.add(trimmed);
    }

    if (uniqueValues.isEmpty) return TrackingItem.unknownZone;

    return uniqueValues.join(' > ');
  }

  bool _hasUsefulLocationLabel(String value) {
    final normalized = WowRegionFilter.normalize(value);

    return normalized.isNotEmpty &&
        normalized != WowRegionFilter.normalize(TrackingItem.unknownZone) &&
        normalized != 'unknown' &&
        normalized != 'a definir';
  }

  String get _startingCapital {
    final faction = WowRegionFilter.normalize(
      _selectedCharacter?.faction ?? '',
    );

    if (faction == 'alliance') return 'Hurlevent';

    return 'Orgrimmar';
  }

  void _backToProgress() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openWhishlist() async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SoloPlannerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupedItems();
    var stepNumber = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route du jour'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: _loadRouteItems,
          ),
        ],
        bottom: JourneyStepBar(
          currentStep: 3,
          onStep1: _backToProgress,
          onStep2: _openWhishlist,
          onStep3: () {},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : WebSponsorSliverPageBody(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ScrollingNoticeBanner(
                        message:
                            'ATTENTION : Algorithme de calcul de route en cours de developpement',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Prends la route',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _RouteStartCard(capital: _startingCapital),
                      const SizedBox(height: 18),
                      Text(
                        _routeCountLabel(_items.length),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),
                      const AppNativeAd(),
                      if (_items.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              'Aucun item sélectionné pour cette balade.',
                              style: const TextStyle(color: AppTheme.mutedText),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    for (final entry in groupedItems.entries) ...[
                      _PlannerGroupHeader(
                        title: entry.key,
                        count: entry.value.length,
                        isCollapsed: false,
                        onToggle: () {},
                      ),
                      for (final item in entry.value)
                        _PlannerItemCard(
                          item: item,
                          selectedForSolo: false,
                          stepNumber: ++stepNumber,
                          onChanged: (_) {},
                        ),
                    ],
                  ]),
                ),
              ],
            ),
    );
  }

  String _routeCountLabel(int count) {
    if (count == 0) return 'Aucun objectif pour aujourd\'hui';
    if (count == 1) return '1 objectif pour cette balade';

    return '$count objectifs pour cette balade';
  }
}

class _RouteStartCard extends StatelessWidget {
  const _RouteStartCard({required this.capital});

  final String capital;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.flag_rounded, color: AppTheme.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Départ : $capital',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteStepNumberBadge extends StatelessWidget {
  const _RouteStepNumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: Text(
        '$number',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.gold,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AdventureCrewPicker extends StatelessWidget {
  const _AdventureCrewPicker({
    required this.selectedMode,
    required this.onChanged,
  });

  final _AdventureCrewMode selectedMode;
  final ValueChanged<_AdventureCrewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 560;
            final buttons = [
              _CrewButton(
                icon: Icons.explore_outlined,
                label: 'Solo',
                selected: selectedMode == _AdventureCrewMode.solo,
                onPressed: () => onChanged(_AdventureCrewMode.solo),
              ),
              _CrewButton(
                icon: Icons.groups_2_outlined,
                label: 'Avec des amis',
                selected: selectedMode == _AdventureCrewMode.friends,
                onPressed: null,
              ),
            ];

            final buttonRow = isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < buttons.length; index++) ...[
                        buttons[index],
                        if (index < buttons.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      for (var index = 0; index < buttons.length; index++) ...[
                        Expanded(child: buttons[index]),
                        if (index < buttons.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Composition de l\'équipage :',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                buttonRow,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CrewButton extends StatelessWidget {
  const _CrewButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? AppTheme.gold.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.025);
    final foregroundColor = selected ? AppTheme.gold : AppTheme.text;
    final borderColor = selected
        ? AppTheme.gold.withValues(alpha: 0.78)
        : AppTheme.gold.withValues(alpha: 0.24);

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label, textAlign: TextAlign.center),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        backgroundColor: backgroundColor,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.025),
        foregroundColor: foregroundColor,
        disabledForegroundColor: AppTheme.mutedText.withValues(alpha: 0.72),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: borderColor, width: selected ? 1.2 : 1),
      ),
    );
  }
}

class _SoloPlannerActionBar extends StatelessWidget {
  const _SoloPlannerActionBar({
    required this.countLabel,
    required this.hasTodaySelection,
    required this.allItemsSelected,
    required this.sortMode,
    required this.onClearSelection,
    required this.onSelectAll,
    required this.onOpenRoute,
    required this.onSortModeChanged,
  });

  final String countLabel;
  final bool hasTodaySelection;
  final bool allItemsSelected;
  final _SoloPlannerSortMode sortMode;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onOpenRoute;
  final ValueChanged<_SoloPlannerSortMode> onSortModeChanged;

  @override
  Widget build(BuildContext context) {
    final count = Text(
      countLabel,
      style: const TextStyle(fontWeight: FontWeight.w700),
    );
    final clearButton = OutlinedButton.icon(
      onPressed: hasTodaySelection ? onClearSelection : null,
      icon: const Icon(Icons.remove_done_outlined),
      label: const Text('Tout désactiver'),
    );
    final selectAllButton = OutlinedButton.icon(
      onPressed: allItemsSelected ? null : onSelectAll,
      icon: const Icon(Icons.done_all_outlined),
      label: const Text('Tout activer'),
    );
    final routeButton = FilledButton.icon(
      onPressed: hasTodaySelection ? onOpenRoute : null,
      icon: const Icon(Icons.route_rounded),
      label: const Text('Générer ma route'),
    );
    final sortControls = _SoloPlannerSortControls(
      selectedMode: sortMode,
      onChanged: onSortModeChanged,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              count,
              clearButton,
              selectAllButton,
              routeButton,
              sortControls,
            ],
          );
        }

        return Row(
          children: [
            count,
            const SizedBox(width: 10),
            clearButton,
            const SizedBox(width: 10),
            selectAllButton,
            const SizedBox(width: 10),
            routeButton,
            const Spacer(),
            sortControls,
          ],
        );
      },
    );
  }
}

class _SoloPlannerSortControls extends StatelessWidget {
  const _SoloPlannerSortControls({
    required this.selectedMode,
    required this.onChanged,
  });

  final _SoloPlannerSortMode selectedMode;
  final ValueChanged<_SoloPlannerSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SoloPlannerSortIconButton(
          icon: Icons.travel_explore,
          tooltip: 'Trier par Localisation',
          selected: selectedMode == _SoloPlannerSortMode.location,
          onPressed: () => onChanged(_SoloPlannerSortMode.location),
        ),
        const SizedBox(width: 8),
        _SoloPlannerSortIconButton(
          icon: Icons.category_outlined,
          tooltip: 'Trier par Catégories',
          selected: selectedMode == _SoloPlannerSortMode.category,
          onPressed: () => onChanged(_SoloPlannerSortMode.category),
        ),
      ],
    );
  }
}

class _SoloPlannerSortIconButton extends StatelessWidget {
  const _SoloPlannerSortIconButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? AppTheme.gold.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.025);
    final foregroundColor = selected ? AppTheme.gold : AppTheme.text;
    final borderColor = selected
        ? AppTheme.gold.withValues(alpha: 0.78)
        : AppTheme.gold.withValues(alpha: 0.24);

    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(38),
        minimumSize: const Size.square(38),
        padding: EdgeInsets.zero,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: BorderSide(color: borderColor, width: selected ? 1.2 : 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
  const _GroupFilterField({
    required this.selectedGroups,
    required this.onTap,
    this.useObtainmentTypeLabels = false,
  });

  final Set<String> selectedGroups;
  final VoidCallback onTap;
  final bool useObtainmentTypeLabels;

  String get _label {
    if (selectedGroups.isEmpty) {
      return useObtainmentTypeLabels
          ? 'Tous les types d\'obtention'
          : 'Tous les groupes';
    }

    if (selectedGroups.length <= 2) {
      return selectedGroups.join(', ');
    }

    return useObtainmentTypeLabels
        ? '${selectedGroups.length} types sélectionnés'
        : '${selectedGroups.length} groupes sélectionnés';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: useObtainmentTypeLabels ? 'Types d\'obtention' : 'Groupes',
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

class _ExtensionFilterField extends StatelessWidget {
  const _ExtensionFilterField({
    required this.selectedExtensions,
    required this.onTap,
  });

  final Set<WowExpansion> selectedExtensions;
  final VoidCallback onTap;

  String get _label {
    if (selectedExtensions.isEmpty) {
      return 'Toutes les extensions';
    }

    if (selectedExtensions.length <= 2) {
      return selectedExtensions.map((extension) => extension.label).join(', ');
    }

    return '${selectedExtensions.length} extensions sélectionnées';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Extensions',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            const Icon(Icons.public, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (selectedExtensions.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                selectedExtensions.length.toString(),
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

class _DifficultyFilterField extends StatelessWidget {
  const _DifficultyFilterField({
    required this.selectedDifficulties,
    required this.onTap,
  });

  final Set<String> selectedDifficulties;
  final VoidCallback onTap;

  String get _label {
    if (selectedDifficulties.isEmpty) {
      return 'Toutes les difficultés';
    }

    if (selectedDifficulties.length <= 2) {
      return selectedDifficulties.join(', ');
    }

    return '${selectedDifficulties.length} difficultés sélectionnées';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Difficulté',
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
            if (selectedDifficulties.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                selectedDifficulties.length.toString(),
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
    this.useObtainmentTypeLabels = false,
  });

  final List<String> options;
  final Set<String> selectedGroups;
  final bool useObtainmentTypeLabels;

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
                      widget.useObtainmentTypeLabels
                          ? 'Types d\'obtention'
                          : 'Groupes',
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
              title: Text(
                widget.useObtainmentTypeLabels
                    ? 'Tous les types d\'obtention'
                    : 'Tous les groupes',
              ),
              subtitle: Text(
                widget.useObtainmentTypeLabels
                    ? 'Aucun type d\'obtention filtré'
                    : 'Aucun groupe filtré',
              ),
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
                        ? widget.useObtainmentTypeLabels
                              ? 'Afficher tous les types d\'obtention'
                              : 'Afficher tous les groupes'
                        : widget.useObtainmentTypeLabels
                        ? 'Appliquer ${_tempSelected.length} type(s)'
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

class _ExtensionFilterSheet extends StatefulWidget {
  const _ExtensionFilterSheet({
    required this.options,
    required this.selectedExtensions,
  });

  final List<WowExpansion> options;
  final Set<WowExpansion> selectedExtensions;

  @override
  State<_ExtensionFilterSheet> createState() => _ExtensionFilterSheetState();
}

class _ExtensionFilterSheetState extends State<_ExtensionFilterSheet> {
  late final Set<WowExpansion> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = {...widget.selectedExtensions};
  }

  void _toggle(WowExpansion extension, bool selected) {
    setState(() {
      if (selected) {
        _tempSelected.add(extension);
      } else {
        _tempSelected.remove(extension);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Extensions',
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
              title: const Text('Toutes les extensions'),
              subtitle: const Text('Aucune extension filtrée'),
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
                  final extension = widget.options[index];
                  final selected = _tempSelected.contains(extension);

                  return CheckboxListTile(
                    value: selected,
                    title: Text(extension.label),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) => _toggle(extension, value ?? false),
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
                        ? 'Afficher toutes les extensions'
                        : 'Appliquer ${_tempSelected.length} extension(s)',
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

class _DifficultyFilterSheet extends StatefulWidget {
  const _DifficultyFilterSheet({
    required this.options,
    required this.selectedDifficulties,
  });

  final List<String> options;
  final Set<String> selectedDifficulties;

  @override
  State<_DifficultyFilterSheet> createState() => _DifficultyFilterSheetState();
}

class _DifficultyFilterSheetState extends State<_DifficultyFilterSheet> {
  late final Set<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = {...widget.selectedDifficulties};
  }

  void _toggle(String difficulty, bool selected) {
    setState(() {
      if (selected) {
        _tempSelected.add(difficulty);
      } else {
        _tempSelected.remove(difficulty);
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
                      'Difficulté',
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
              title: const Text('Toutes les difficultés'),
              subtitle: const Text('Aucune difficulté filtrée'),
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
                  final difficulty = widget.options[index];
                  final selected = _tempSelected.contains(difficulty);

                  return CheckboxListTile(
                    value: selected,
                    title: Text(difficulty),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) => _toggle(difficulty, value ?? false),
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
                        ? 'Afficher toutes les difficultés'
                        : 'Appliquer ${_tempSelected.length} difficulté(s)',
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
  const _PlannerItemCard({
    required this.item,
    required this.selectedForSolo,
    this.selectionTagLabel = 'Balade du jour',
    this.stepNumber,
    required this.onChanged,
  });

  final TrackingItem item;
  final bool selectedForSolo;
  final String selectionTagLabel;
  final int? stepNumber;
  final ValueChanged<bool?> onChanged;

  String _wowheadUrl(BuildContext context) {
    final preferredLocale = WowheadUrlBuilder.preferredLocaleCode(
      WidgetsBinding.instance.platformDispatcher.locales.map(
        (locale) => locale.toLanguageTag(),
      ),
      fallback: Localizations.localeOf(context).languageCode,
    );
    final locale =
        item.category == TrackingCategory.mounts ||
            item.category == TrackingCategory.achievements ||
            item.category == TrackingCategory.pets
        ? 'fr'
        : preferredLocale;

    if (item.wowheadUrl.isNotEmpty) {
      return WowheadUrlBuilder.localizeUrl(item.wowheadUrl, locale: locale);
    }

    return WowheadUrlBuilder.build(item: item, locale: locale);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }

  bool _isWowheadUrl(String url) {
    final host = Uri.tryParse(url.trim())?.host.toLowerCase();

    return host == 'wowhead.com' ||
        host == 'www.wowhead.com' ||
        (host?.endsWith('.wowhead.com') ?? false);
  }

  List<_PlannerTag> _metadataTags() {
    final dropRateTag = _dropRateTag();
    final extensionTag = _extensionTag();
    final regionLabel = _regionLabel();

    return [
      ?dropRateTag,
      ?extensionTag,
      if (regionLabel != null) _PlannerTag(label: regionLabel),
    ];
  }

  String _displayDifficultyLabel(String label) {
    final normalized = WowRegionFilter.normalize(label);
    if (item.category == TrackingCategory.mounts &&
        (normalized.contains('reel') || normalized.contains('argent'))) {
      return 'Achat IRL';
    }

    return label;
  }

  _PlannerTag? _difficultyTag() {
    final label = item.difficulty.trim();
    if (!_hasUsefulMetadataLabel(label)) return null;

    final normalized = WowRegionFilter.normalize(label);
    if (item.unavailable && normalized == 'indisponible') return null;

    final colors = _difficultyColors(normalized);

    return _PlannerTag(
      label: _displayDifficultyLabel(label),
      backgroundColor: colors.$1,
      foregroundColor: colors.$2,
    );
  }

  _PlannerTag? _dropRateTag() {
    if (item.category != TrackingCategory.mounts &&
        item.category != TrackingCategory.pets) {
      return null;
    }

    final label = _dropRateLabel(item.dropRate);
    if (label == null) return null;

    final colors = _dropRateColors(label);
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

  bool _isDungeonTag(String tag) => WowRegionFilter.normalize(tag) == 'donjon';

  List<_PlannerTag> _manualTags({bool includeDungeonTag = true}) {
    return [
      for (final tag in item.tags)
        if (_hasUsefulMetadataLabel(tag) &&
            (includeDungeonTag || !_isDungeonTag(tag)))
          _PlannerTag(label: _displayManualTagLabel(tag)),
    ];
  }

  _PlannerTag? _dungeonTag() {
    final hasDungeonTag = item.tags.any(
      (tag) => _hasUsefulMetadataLabel(tag) && _isDungeonTag(tag),
    );

    return hasDungeonTag ? const _PlannerTag(label: 'Donjon') : null;
  }

  String _displayManualTagLabel(String label) {
    final normalized = WowRegionFilter.normalize(label);
    if (item.category == TrackingCategory.mounts &&
        (normalized == 'reel' || normalized == 'argent reel')) {
      return 'Achat IRL';
    }

    return label;
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

  String? _dropRateLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final normalized = WowRegionFilter.normalize(trimmed);
    if (normalized == 'n a' ||
        normalized == 'na' ||
        normalized == 'inconnu' ||
        normalized == 'unknown' ||
        normalized == 'a verifier' ||
        normalized == 'non renseigne' ||
        normalized == 'pas de taux') {
      return null;
    }

    final match = RegExp(r'(\d+(?:[,.]\d+)?)').firstMatch(trimmed);
    if (match == null) return trimmed;

    final rate = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (rate == null) return trimmed;

    final formatted = rate == rate.roundToDouble()
        ? rate.toInt().toString()
        : rate.toString().replaceAll('.', ',');

    return '$formatted%';
  }

  (Color, Color) _dropRateColors(String label) {
    final match = RegExp(r'(\d+(?:[,.]\d+)?)').firstMatch(label);
    final rate = match == null
        ? null
        : double.tryParse(match.group(1)!.replaceAll(',', '.'));

    if (rate == null) {
      return (const Color(0xFF334155), const Color(0xFFE2E8F0));
    }

    if (rate >= 50) {
      return (const Color(0xFF14532D), const Color(0xFF86EFAC));
    }
    if (rate >= 5) {
      return (const Color(0xFF713F12), const Color(0xFFFDE68A));
    }

    return (const Color(0xFF7F1D1D), const Color(0xFFFCA5A5));
  }

  String _descriptionText(String groupLabel) {
    final values = [
      if (item.category != TrackingCategory.mounts &&
          item.category != TrackingCategory.pets)
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
    ];
    final seen = <String>{};
    final uniqueValues = <String>[];

    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;

      final normalized = WowRegionFilter.normalize(trimmed);
      if (normalized.isEmpty || !seen.add(normalized)) continue;

      uniqueValues.add(trimmed);
    }

    return uniqueValues.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final isMount = item.category == TrackingCategory.mounts;
    final mamytwinkUrl = item.mamytwinkUrl.trim();
    final wowheadUrl = _wowheadUrl(context);
    final hasWowheadLink = _isWowheadUrl(wowheadUrl);
    final groupLabel =
        AchievementGroupHierarchy.labelFor(item) ?? item.instance;
    final difficultyTag = _difficultyTag();
    final dropRateTag = _dropRateTag();
    final extensionTag = _extensionTag();
    final regionLabel = _regionLabel();
    final dungeonTag = _dungeonTag();
    final frequencyLabel = item.frequencyLabel.trim().isEmpty
        ? item.weeklyLockout
              ? 'Hebdomadaire'
              : 'Farm libre'
        : item.frequencyLabel.trim();
    final tags = isMount
        ? <Widget>[
            if (item.unavailable)
              const _PlannerTag(
                label: 'Indisponible',
                backgroundColor: Color(0xFF7F1D1D),
                foregroundColor: Color(0xFFFEE2E2),
              ),
            _CategoryPlannerTag(category: item.category),
            ?difficultyTag,
            ?dropRateTag,
            ?extensionTag,
            if (regionLabel != null) _PlannerTag(label: regionLabel),
            ?dungeonTag,
            _PlannerTag(label: frequencyLabel),
            if (item.obtained) const _PlannerTag(label: 'Obtenu'),
            if (selectedForSolo) _PlannerTag(label: selectionTagLabel),
            ..._manualTags(includeDungeonTag: false),
          ]
        : <Widget>[
            if (item.unavailable)
              const _PlannerTag(
                label: 'Indisponible',
                backgroundColor: Color(0xFF7F1D1D),
                foregroundColor: Color(0xFFFEE2E2),
              ),
            _CategoryPlannerTag(category: item.category),
            ..._metadataTags(),
            _PlannerTag(label: frequencyLabel),
            if (item.obtained) const _PlannerTag(label: 'Obtenu'),
            if (selectedForSolo) _PlannerTag(label: selectionTagLabel),
            ?difficultyTag,
            ..._manualTags(),
          ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (stepNumber != null)
              _RouteStepNumberBadge(number: stepNumber!)
            else
              SizedBox(
                width: 72,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: selectedForSolo
                          ? 'Retirer de $selectionTagLabel'
                          : 'Ajouter à $selectionTagLabel',
                      child: Checkbox(
                        value: selectedForSolo,
                        onChanged: onChanged,
                      ),
                    ),
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
                            child: const _WowheadRocketIcon(),
                          ),
                        ],
                      )
                    else
                      hasWowheadLink
                          ? _MountExternalLinkButton(
                              tooltip: 'Ouvrir sur Wowhead',
                              onPressed: () => _openUrl(wowheadUrl),
                              child: const _WowheadRocketIcon(),
                            )
                          : IconButton(
                              tooltip: 'Ouvrir la fiche',
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
                    _descriptionText(groupLabel),
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

class _WowheadRocketIcon extends StatelessWidget {
  const _WowheadRocketIcon();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 1),
        Icon(Icons.rocket_launch_rounded, size: 12),
      ],
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

class _CategoryPlannerTag extends StatelessWidget {
  const _CategoryPlannerTag({required this.category});

  final TrackingCategory category;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category) {
      TrackingCategory.achievements => '🏆',
      TrackingCategory.mounts => '🐴',
      TrackingCategory.pets => '🐾',
      _ => null,
    };

    if (icon == null) {
      return _PlannerTag(label: category.label);
    }

    return Semantics(
      label: category.label,
      child: Chip(
        label: Text(icon, style: const TextStyle(fontSize: 16, height: 1)),
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.white10,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
