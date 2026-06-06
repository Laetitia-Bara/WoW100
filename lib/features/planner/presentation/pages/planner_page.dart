import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wow100/core/services/battle_net_token_service.dart';
import 'package:wow100/data/models/tracking_category.dart';
import 'package:wow100/data/repositories/battle_net_repository.dart';

import '../../../../core/services/local_check_service.dart';
import '../../../../core/services/wowhead_url_builder.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/tracking_item.dart';
import '../../../../data/models/wow_expansion.dart';
import '../../../../data/repositories/planner_repository.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({
    super.key,
    required this.extension,
    this.category = TrackingCategory.mounts,
  });

  final WowExpansion extension;
  final TrackingCategory category;

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final PlannerRepository _repository = JsonPlannerRepository();
  final LocalCheckService _localCheckService = LocalCheckService();
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
  bool _missingOnly = false;
  String _searchQuery = '';
  final Set<String> _selectedGroups = {};

  bool get _isPetsPlanner =>
      widget.category == TrackingCategory.pets ||
      widget.extension == WowExpansion.allPets;

  String get _collectionName => _isPetsPlanner ? 'mascottes' : 'montures';

  String get _allCollectionTitle =>
      _isPetsPlanner ? 'Toutes les mascottes' : 'Toutes les montures';

  String get _plannerTitle =>
      _isPetsPlanner ? 'Mascottes à récupérer' : 'Montures à récupérer';

  @override
  void initState() {
    super.initState();
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

      if (token != null) {
        if (_isPetsPlanner) {
          final pets = await BattleNetRepository().getPets(token);
          ownedPetIds.addAll(pets.map((pet) => pet.id));
        } else {
          final mounts = await BattleNetRepository().getMounts(token);
          ownedMountIds.addAll(mounts.map((mount) => mount.id));
        }
      }

      final updatedItems = <TrackingItem>[];

      for (final item in items) {
        final checked = await _localCheckService.isChecked(item.id);
        final ownedMount =
            item.category == TrackingCategory.mounts &&
            item.blizzardId != null &&
            ownedMountIds.contains(item.blizzardId);
        final ownedPet =
            item.category == TrackingCategory.pets &&
            item.blizzardId != null &&
            ownedPetIds.contains(item.blizzardId);

        updatedItems.add(
          item.copyWith(obtained: checked || ownedMount || ownedPet),
        );
      }

      if (!mounted) return;

      setState(() {
        _items = updatedItems;
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
    await _localCheckService.setChecked(item.id, checked);

    if (!mounted) return;

    setState(() {
      _items = _items.map((current) {
        if (current.id == item.id) {
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

  @override
  Widget build(BuildContext context) {
    final groupOptions = _groupOptions();

    final filteredItems = _items.where((item) {
      final group = _groupLabel(item);
      final matchesGroup =
          _selectedGroups.isEmpty || _selectedGroups.contains(group);
      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          group.toLowerCase().contains(query) ||
          item.instance.toLowerCase().contains(query) ||
          item.source.toLowerCase().contains(query);

      final matchesMissingOnly = !_missingOnly || !item.obtained;

      return matchesGroup && matchesSearch && matchesMissingOnly;
    }).toList();

    final groupedItems = _groupedItems(filteredItems);
    final obtainedCount = filteredItems.where((item) => item.obtained).length;
    final totalCount = filteredItems.length;
    final progress = totalCount == 0 ? 0.0 : obtainedCount / totalCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.extension.label),
        actions: [
          IconButton(
            tooltip: 'Tout décocher',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              for (final item in _items) {
                await _localCheckService.clearChecked(item.id);
              }

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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.extension == WowExpansion.allMounts ||
                          widget.extension == WowExpansion.allPets
                      ? _allCollectionTitle
                      : _plannerTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Rechercher',
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
                _GroupFilterField(
                  selectedGroups: _selectedGroups,
                  onTap: () => _openGroupSelector(groupOptions),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: _missingOnly,
                      onChanged: (value) {
                        setState(() {
                          _missingOnly = value;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Afficher uniquement les manquants'),
                          const SizedBox(height: 2),
                          Text(
                            'Masquer les $_collectionName déjà obtenues',
                            style: const TextStyle(color: AppTheme.mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '$obtainedCount / $totalCount obtenus',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 20),
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
                for (final entry in groupedItems.entries) ...[
                  _PlannerGroupHeader(
                    title: entry.key,
                    count: entry.value.length,
                    isCollapsed: _collapsedGroups.contains(entry.key),
                    onToggle: () => _toggleGroup(entry.key),
                  ),
                  if (!_collapsedGroups.contains(entry.key))
                    for (final item in entry.value)
                      _PlannerItemCard(
                        item: item,
                        onChanged: (value) => _setChecked(item, value ?? false),
                      ),
                ],
              ],
            ),
    );
  }
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

class _GroupFilterField extends StatelessWidget {
  const _GroupFilterField({required this.selectedGroups, required this.onTap});

  final Set<String> selectedGroups;
  final VoidCallback onTap;

  String get _label {
    if (selectedGroups.isEmpty) {
      return 'Toutes les catégories';
    }

    if (selectedGroups.length <= 2) {
      return selectedGroups.join(', ');
    }

    return '${selectedGroups.length} catégories sélectionnées';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Catégorie',
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
              subtitle: const Text('Aucune catégorie filtrée'),
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

class _PlannerItemCard extends StatelessWidget {
  const _PlannerItemCard({required this.item, required this.onChanged});

  final TrackingItem item;
  final ValueChanged<bool?> onChanged;

  Future<void> _openExternal(BuildContext context) async {
    final locale = Localizations.localeOf(context).languageCode;
    final url = WowheadUrlBuilder.build(item: item, locale: locale);
    final uri = Uri.parse(url);

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tags = [
      _PlannerTag(label: item.category.label),
      _PlannerTag(label: item.weeklyLockout ? 'Hebdomadaire' : 'Farm libre'),
      _PlannerTag(
        label: item.groupRequired ? 'Groupe conseillé' : 'Solo possible',
      ),
      if (item.obtained) const _PlannerTag(label: 'Obtenu'),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(value: item.obtained, onChanged: onChanged),
            IconButton(
              tooltip: item.wowheadItemId != null
                  ? 'Ouvrir sur Wowhead'
                  : 'Ouvrir la fiche',
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _openExternal(context),
            ),
            const SizedBox(width: 8),
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
                      item.zone,
                      item.instance,
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

class _PlannerTag extends StatelessWidget {
  const _PlannerTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.white10,
      side: BorderSide.none,
    );
  }
}
