import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wow100/core/services/battle_net_auth_service.dart';
import 'package:wow100/core/services/battle_net_token_service.dart';

import '../../../../core/services/selected_character_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/expansion_progress.dart';
import '../../../../data/models/tracking_category.dart';
import '../../../../data/models/wow_character.dart';
import '../../../../data/models/wow_expansion.dart';
import '../../../../data/repositories/progress_repository.dart';
import '../../../../data/sources/wow_expansion_catalog.dart';
import '../../../auth/presentation/pages/character_switch_page.dart';
import '../../../legal/presentation/pages/legal_page.dart';
import '../../../planner/presentation/pages/planner_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Set<WowExpansion> _collapsedExpansions = {};
  final Set<TrackingCategory> _visibleCategories = {
    TrackingCategory.achievements,
    TrackingCategory.mounts,
    TrackingCategory.pets,
  };
  final ProgressRepository _repository = JsonProgressRepository();
  final SelectedCharacterService _selectedCharacterService =
      SelectedCharacterService();

  bool _newestFirst = false;
  bool _isLoading = true;
  List<ExpansionProgress> _progresses = [];
  WowCharacter? _mainCharacter;

  @override
  void initState() {
    super.initState();
    _loadCharacter();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progresses = await _repository.getProgress();

    if (!mounted) return;

    setState(() {
      _progresses = progresses;
      _isLoading = false;
    });
  }

  Future<void> _loadCharacter() async {
    final character = await _selectedCharacterService.loadCharacter();

    if (!mounted) return;

    setState(() {
      _mainCharacter = character;
    });
  }

  Future<void> _disconnectBattleNet() async {
    await BattleNetTokenService().clearToken();
    await _selectedCharacterService.clearCharacter();

    if (!mounted) return;

    setState(() {
      _mainCharacter = null;
      _isLoading = true;
    });

    await _loadProgress();
  }

  Future<void> _openBattleNetLogin() async {
    await BattleNetTokenService().clearToken();
    await _selectedCharacterService.clearCharacter();

    final service = BattleNetAuthService();
    final url = service.buildAuthorizationUrl();

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _openCharacterSwitch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CharacterSwitchPage()),
    );

    await _loadCharacter();
    await _loadProgress();
  }

  Future<void> _openCategoryFilters() async {
    final result = await showModalBottomSheet<Set<TrackingCategory>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryFilterSheet(
        selectedCategories: _visibleCategories,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _visibleCategories
        ..clear()
        ..addAll(result);
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _newestFirst = !_newestFirst;
    });
  }

  void _toggleCollapse(WowExpansion expansion) {
    setState(() {
      if (_collapsedExpansions.contains(expansion)) {
        _collapsedExpansions.remove(expansion);
      } else {
        _collapsedExpansions.add(expansion);
      }
    });
  }

  Future<void> _openPlanner(WowExpansion expansion) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlannerPage(extension: expansion)),
    );

    await _loadProgress();
  }

  void _openLegalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LegalPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalProgress = _progresses.firstWhere(
      (progress) => progress.expansion == WowExpansion.total,
    );

    final extensionProgresses = _progresses
        .where((progress) => progress.expansion != WowExpansion.total)
        .toList();

    if (_newestFirst) {
      extensionProgresses.sort(
        (a, b) => b.expansion.index.compareTo(a.expansion.index),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('WoW100%'),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Informations légales',
              constraints: const BoxConstraints.tightFor(
                width: 36,
                height: 36,
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.info_outline),
              onPressed: _openLegalPage,
            ),
          ],
        ),
        actions: [
          if (_mainCharacter == null)
            TextButton.icon(
              onPressed: _openBattleNetLogin,
              icon: const Icon(Icons.login),
              label: const Text('Connexion'),
            )
          else ...[
            TextButton.icon(
              onPressed: _openCharacterSwitch,
              icon: const Icon(Icons.person),
              label: const Text('Changer'),
            ),
            IconButton(
              tooltip: 'Déconnexion',
              icon: const Icon(Icons.logout),
              onPressed: _disconnectBattleNet,
            ),
          ],
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;
          final contentWidth = isWide ? 1180.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeroCard(
                    character: _mainCharacter,
                    totalProgress: totalProgress,
                    visibleCategories: _visibleCategories,
                  ),
                  const SizedBox(height: 20),
                  _DashboardActionBar(
                    newestFirst: _newestFirst,
                    onMountsTap: () => _openPlanner(WowExpansion.allMounts),
                    onFilterTap: _openCategoryFilters,
                    onSortTap: _toggleSortOrder,
                  ),
                  const SizedBox(height: 20),
                  if (isWide)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 248,
                          ),
                      itemCount: extensionProgresses.length,
                      itemBuilder: (context, index) {
                        final progress = extensionProgresses[index];

                        return _ExpansionCard(
                          progress: progress,
                          visibleCategories: _visibleCategories,
                          isCollapsed: _collapsedExpansions.contains(
                            progress.expansion,
                          ),
                          onToggleCollapse: () =>
                              _toggleCollapse(progress.expansion),
                          onTap: () => _openPlanner(progress.expansion),
                        );
                      },
                    )
                  else
                    for (final progress in extensionProgresses)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ExpansionCard(
                          progress: progress,
                          visibleCategories: _visibleCategories,
                          isCollapsed: _collapsedExpansions.contains(
                            progress.expansion,
                          ),
                          onToggleCollapse: () =>
                              _toggleCollapse(progress.expansion),
                          onTap: () => _openPlanner(progress.expansion),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.character,
    required this.totalProgress,
    required this.visibleCategories,
  });

  final WowCharacter? character;
  final ExpansionProgress totalProgress;
  final Set<TrackingCategory> visibleCategories;

  @override
  Widget build(BuildContext context) {
    final hasCharacter = character != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasCharacter ? character!.name : 'Companion de collection WoW',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              hasCharacter
                  ? '${character!.race} ${character!.characterClass} • ${character!.realm} • ${character!.faction} • Niveau ${character!.level}'
                  : 'Connecte ton compte Battle.net, choisis ton personnage principal, puis suis ta progression par extension.',
              style: const TextStyle(color: AppTheme.mutedText, height: 1.4),
            ),
            const SizedBox(height: 18),
            _TotalProgressSummary(
              progress: totalProgress,
              visibleCategories: visibleCategories,
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalProgressSummary extends StatelessWidget {
  const _TotalProgressSummary({
    required this.progress,
    required this.visibleCategories,
  });

  final ExpansionProgress progress;
  final Set<TrackingCategory> visibleCategories;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.completionRate * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Vue totale',
                style: TextStyle(fontWeight: FontWeight.w800),
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
        const SizedBox(height: 10),
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
    );
  }
}

class _DashboardActionBar extends StatelessWidget {
  const _DashboardActionBar({
    required this.newestFirst,
    required this.onMountsTap,
    required this.onFilterTap,
    required this.onSortTap,
  });

  final bool newestFirst;
  final VoidCallback onMountsTap;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label arrive dans une prochaine étape')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectableButtons = [
      OutlinedButton.icon(
        onPressed: () => _showComingSoon(context, 'Hauts faits'),
        icon: const Icon(Icons.emoji_events_outlined),
        label: const Text('HF'),
      ),
      OutlinedButton.icon(
        onPressed: onMountsTap,
        icon: const Icon(Icons.pets),
        label: const Text('Montures'),
      ),
      OutlinedButton.icon(
        onPressed: () => _showComingSoon(context, 'Mascottes'),
        icon: const Icon(Icons.cruelty_free),
        label: const Text('Mascottes'),
      ),
    ];

    final toolButtons = [
      IconButton.outlined(
        tooltip: 'Filtres',
        onPressed: onFilterTap,
        icon: const Icon(Icons.filter_alt_outlined),
      ),
      IconButton.outlined(
        tooltip: newestFirst
            ? 'Ordre historique'
            : 'Extensions récentes en premier',
        onPressed: onSortTap,
        icon: Icon(
          newestFirst
              ? Icons.vertical_align_bottom
              : Icons.vertical_align_top,
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [...collectableButtons, ...toolButtons],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Wrap(spacing: 10, runSpacing: 10, children: collectableButtons),
            ),
            Wrap(spacing: 8, children: toolButtons),
          ],
        );
      },
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
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
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
                      for (final category in [
                        TrackingCategory.achievements,
                        TrackingCategory.mounts,
                        TrackingCategory.pets,
                      ])
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
