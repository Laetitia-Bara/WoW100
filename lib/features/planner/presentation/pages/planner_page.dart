import 'package:flutter/material.dart';
import 'package:wow100/core/services/battle_net_token_service.dart';
import 'package:wow100/data/models/tracking_category.dart';
import 'package:wow100/data/repositories/battle_net_repository.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/tracking_item.dart';
import '../../../../data/models/wow_expansion.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/wowhead_url_builder.dart';
import '../../../../data/repositories/planner_repository.dart';
import '../../../../core/services/local_check_service.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key, required this.extension});
  final WowExpansion extension;

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  List<TrackingItem> _items = [];
  final PlannerRepository _repository = JsonPlannerRepository();
  bool _isLoading = true;
  final LocalCheckService _localCheckService = LocalCheckService();
  TrackingCategory? _selectedCategory;
  String _searchQuery = '';
  PlannerSort _sort = PlannerSort.instance;
  bool _missingOnly = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _repository.getItems(widget.extension);

      final updatedItems = <TrackingItem>[];
      final token = await BattleNetTokenService().loadToken();

      final ownedMountIds = <int>{};

      if (token != null) {
        final battleNetRepository = BattleNetRepository();

        final mounts = await battleNetRepository.getMounts(token);
        ownedMountIds.addAll(mounts.map((mount) => mount.id));
      }

      for (final item in items) {
        final checked = await _localCheckService.isChecked(item.id);

        final ownedMount =
            item.category == TrackingCategory.mounts &&
            item.blizzardId != null &&
            ownedMountIds.contains(item.blizzardId);

        updatedItems.add(item.copyWith(obtained: checked || ownedMount));
      }

      setState(() {
        _items = updatedItems;
        _isLoading = false;
      });
      // ignore: strict_top_level_inference
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

  @override
  Widget build(BuildContext context) {
    final groupedItems = <String, List<TrackingItem>>{};

    final filteredItems = _items.where((item) {
      final matchesCategory =
          _selectedCategory == null || item.category == _selectedCategory;

      final matchesSearch =
          _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.instance.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.source.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesMissingOnly = !_missingOnly || !item.obtained;

      return matchesCategory && matchesSearch && matchesMissingOnly;
    }).toList();

    filteredItems.sort((a, b) {
      switch (_sort) {
        case PlannerSort.instance:
          return a.instance.compareTo(b.instance);
        case PlannerSort.category:
          return a.category.index.compareTo(b.category.index);
        case PlannerSort.name:
          return a.name.compareTo(b.name);
      }
    });

    final obtainedCount = filteredItems.where((item) => item.obtained).length;

    final totalCount = filteredItems.length;

    final progress = totalCount == 0 ? 0.0 : obtainedCount / totalCount;

    for (final item in filteredItems) {
      groupedItems.putIfAbsent(item.instance, () => []).add(item);
    }

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
                  'À récupérer dans cette extension',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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

                DropdownButtonFormField<TrackingCategory?>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<TrackingCategory?>(
                      value: null,
                      child: Text('Toutes les catégories'),
                    ),
                    ...TrackingCategory.values.map(
                      (category) => DropdownMenuItem<TrackingCategory?>(
                        value: category,
                        child: Text(category.label),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<PlannerSort>(
                  initialValue: _sort,
                  decoration: const InputDecoration(
                    labelText: 'Trier par',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: PlannerSort.instance,
                      child: Text('Lieu / instance'),
                    ),
                    DropdownMenuItem(
                      value: PlannerSort.category,
                      child: Text('Catégorie'),
                    ),
                    DropdownMenuItem(
                      value: PlannerSort.name,
                      child: Text('Nom'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _sort = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                SwitchListTile(
                  value: _missingOnly,
                  title: const Text('Afficher uniquement les manquants'),
                  subtitle: const Text('Masquer les éléments déjà obtenus'),
                  onChanged: (value) {
                    setState(() {
                      _missingOnly = value;
                    });
                  },
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

                const SizedBox(height: 8),

                const Text(
                  'Checklist provisoire mockée. Plus tard elle sera synchronisée avec ta progression Battle.net.',
                  style: TextStyle(color: AppTheme.mutedText),
                ),
                const SizedBox(height: 20),

                if (filteredItems.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Aucun élément ne correspond à cette recherche.',
                        style: TextStyle(color: AppTheme.mutedText),
                      ),
                    ),
                  ),

                for (final entry in groupedItems.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      '📍 ${entry.key}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.gold,
                      ),
                    ),
                  ),
                  for (final item in entry.value)
                    _PlannerItemCard(
                      item: item,
                      onChanged: (value) async {
                        final checked = value ?? false;

                        await _localCheckService.setChecked(item.id, checked);

                        setState(() {
                          _items = _items.map((current) {
                            if (current.id == item.id) {
                              return current.copyWith(obtained: checked);
                            }

                            return current;
                          }).toList();
                        });
                      },
                    ),
                ],
              ],
            ),
    );
  }
}

class _PlannerItemCard extends StatelessWidget {
  const _PlannerItemCard({required this.item, required this.onChanged});

  final TrackingItem item;
  final ValueChanged<bool?> onChanged;

  Future<void> _openWowhead() async {
    final url = WowheadUrlBuilder.build(item: item, locale: 'fr');
    final uri = Uri.parse(url);

    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      child: CheckboxListTile(
        value: item.obtained,
        onChanged: onChanged,
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            decoration: item.obtained ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

        secondary: IconButton(
          tooltip: item.externalUrl.isNotEmpty
              ? 'Ouvrir la fiche Mamytwink'
              : 'Ouvrir sur Wowhead',
          icon: const Icon(Icons.open_in_new),
          onPressed: _openWowhead,
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

enum PlannerSort { instance, category, name }
