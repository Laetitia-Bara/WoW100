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
  const PlannerPage({super.key, required this.extension});

  final WowExpansion extension;

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
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _repository.getItems(widget.extension);
      final token = await BattleNetTokenService().loadToken();
      final ownedMountIds = <int>{};

      if (token != null) {
        final mounts = await BattleNetRepository().getMounts(token);
        ownedMountIds.addAll(mounts.map((mount) => mount.id));
      }

      final updatedItems = <TrackingItem>[];

      for (final item in items) {
        final checked = await _localCheckService.isChecked(item.id);
        final ownedMount =
            item.category == TrackingCategory.mounts &&
            item.blizzardId != null &&
            ownedMountIds.contains(item.blizzardId);

        updatedItems.add(item.copyWith(obtained: checked || ownedMount));
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

  @override
  Widget build(BuildContext context) {
    final groupOptions = _groupOptions();

    final filteredItems = _items.where((item) {
      final group = _groupLabel(item);
      final matchesGroup = _selectedGroup == null || group == _selectedGroup;
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
                  widget.extension == WowExpansion.allMounts
                      ? 'Toutes les montures'
                      : 'Montures à récupérer',
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
                DropdownButtonFormField<String?>(
                  initialValue: _selectedGroup,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie de monture',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Toutes les catégories'),
                    ),
                    ...groupOptions.map(
                      (group) => DropdownMenuItem<String?>(
                        value: group,
                        child: Text(group),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGroup = value;
                    });
                  },
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Afficher uniquement les manquants'),
                          SizedBox(height: 2),
                          Text(
                            'Masquer les montures déjà obtenues',
                            style: TextStyle(color: AppTheme.mutedText),
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
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Aucune monture ne correspond à cette recherche.',
                        style: TextStyle(color: AppTheme.mutedText),
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
