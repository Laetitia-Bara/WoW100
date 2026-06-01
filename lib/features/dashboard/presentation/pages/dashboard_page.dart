import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../planner/presentation/pages/planner_page.dart';
import '../../../../data/models/expansion_progress.dart';
import '../../../../data/models/tracking_category.dart';
import '../../../../data/models/wow_expansion.dart';
import '../../../../data/repositories/progress_repository.dart';
import '../../../../data/sources/wow_expansion_catalog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Set<WowExpansion> _collapsedExpansions = {};
  bool _newestFirst = false;
  final Set<TrackingCategory> _visibleCategories = {
    TrackingCategory.achievements,
    TrackingCategory.mounts,
    TrackingCategory.pets,
    TrackingCategory.professions,
  };
  final ProgressRepository _repository = JsonProgressRepository();
  bool _isLoading = true;
  List<ExpansionProgress> _progresses = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progresses = await _repository.getProgress();

    setState(() {
      _progresses = progresses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progresses = _progresses;
    final totalProgress = progresses.firstWhere(
      (progress) => progress.expansion == WowExpansion.total,
    );

    final expansionProgresses = progresses
        .where((progress) => progress.expansion != WowExpansion.total)
        .toList();

    if (_newestFirst) {
      expansionProgresses.sort(
        (a, b) => b.expansion.index.compareTo(a.expansion.index),
      );
    }

    final orderedProgresses = [totalProgress, ...expansionProgresses];

    return Scaffold(
      appBar: AppBar(
        title: const Text('WoW100%'),
        actions: [
          IconButton(
            tooltip: 'Filtres',
            onPressed: () async {
              final result = await showModalBottomSheet<Set<TrackingCategory>>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _CategoryFilterSheet(
                  selectedCategories: _visibleCategories,
                ),
              );

              if (result != null) {
                setState(() {
                  _visibleCategories
                    ..clear()
                    ..addAll(result);
                });
              }
            },
            icon: const Icon(Icons.filter_alt_outlined),
          ),
          IconButton(
            tooltip: _newestFirst
                ? 'Ordre historique'
                : 'Extensions récentes en premier',
            onPressed: () {
              setState(() {
                _newestFirst = !_newestFirst;
              });
            },
            icon: Icon(
              _newestFirst
                  ? Icons.vertical_align_bottom
                  : Icons.vertical_align_top,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _HeroCard(),
          const SizedBox(height: 20),
          for (final progress in orderedProgresses)
            _ExpansionCard(
              progress: progress,
              visibleCategories: _visibleCategories,
              isCollapsed: _collapsedExpansions.contains(progress.expansion),
              onToggleCollapse: () {
                setState(() {
                  if (_collapsedExpansions.contains(progress.expansion)) {
                    _collapsedExpansions.remove(progress.expansion);
                  } else {
                    _collapsedExpansions.add(progress.expansion);
                  }
                });
              },
              onTap: progress.expansion == WowExpansion.total
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PlannerPage(extension: progress.expansion),
                        ),
                      );

                      await _loadProgress();
                    },
            ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Companion de collection WoW',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connecte ton compte Battle.net, choisis ton personnage principal, puis suis ta progression par extension.',
              style: TextStyle(color: AppTheme.mutedText, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.login),
              label: const Text('Connexion Battle.net'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpansionCard extends StatelessWidget {
  const _ExpansionCard({
    required this.progress,
    required this.onTap,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.visibleCategories,
  });

  final ExpansionProgress progress;
  final VoidCallback? onTap;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final Set<TrackingCategory> visibleCategories;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.completionRate * 100).round();
    final info = WowExpansionCatalog.infoOf(progress.expansion);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (progress.expansion != WowExpansion.total)
              Image.asset(
                info.bannerAsset,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onToggleCollapse,
                        icon: Icon(
                          isCollapsed
                              ? Icons.keyboard_arrow_right
                              : Icons.keyboard_arrow_down,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          info.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress.completionRate,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: Colors.white10,
                      color: AppTheme.gold,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: visibleCategories.map((category) {
                        final completed = progress.completed[category] ?? 0;
                        final total = progress.total[category] ?? 0;

                        return _MiniStat(
                          label: category.shortLabel,
                          value: '$completed/$total',
                        );
                      }).toList(),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CategoryFilterSheet extends StatefulWidget {
  const _CategoryFilterSheet({required this.selectedCategories});

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Text(
                  'Catégories affichées',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      for (final category in TrackingCategory.values)
                        CheckboxListTile(
                          value: _tempSelected.contains(category),
                          title: Text(category.label),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _tempSelected.add(category);
                              } else {
                                _tempSelected.remove(category);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context, _tempSelected);
                  },
                  child: const Text('Appliquer'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
