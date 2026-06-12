import 'package:flutter/material.dart';
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
    await service.openAuthorization();
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
      builder: (_) =>
          _CategoryFilterSheet(selectedCategories: _visibleCategories),
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

  Future<void> _openPlanner(
    WowExpansion expansion, {
    TrackingCategory? category,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlannerPage(extension: expansion, category: category),
      ),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/icones/icone192.png',
                height: 30,
                width: 30,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Text(
                  'WoW100%',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Informations légales',
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
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
              label: const Text('Mes personnages'),
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
                    onAchievementsTap: () => _openPlanner(
                      WowExpansion.allAchievements,
                      category: TrackingCategory.achievements,
                    ),
                    onMountsTap: () => _openPlanner(WowExpansion.allMounts),
                    onPetsTap: () => _openPlanner(
                      WowExpansion.allPets,
                      category: TrackingCategory.pets,
                    ),
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
                            mainAxisExtent: 282,
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
                          onOpenPlanner: () => _openPlanner(progress.expansion),
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
                          onOpenPlanner: () => _openPlanner(progress.expansion),
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
    final characterClassColor = hasCharacter
        ? _wowClassColor(character!.characterClass)
        : AppTheme.text;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasCharacter) _CharacterIdentityBackdrop(character: character!),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCharacter
                      ? character!.name
                      : 'Companion de collection WoW',
                  style: TextStyle(
                    color: characterClassColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasCharacter
                      ? '${character!.race} ${character!.characterClass} • ${character!.realm} • ${character!.faction} • Niveau ${character!.level}'
                      : 'Connecte ton compte Battle.net, choisis ton personnage principal, puis suis ta progression par extension.',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    height: 1.4,
                  ),
                ),
                if (hasCharacter) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Points de HF : ${_formatNumber(character!.achievementPoints)}',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _TotalProgressSummary(
                  progress: totalProgress,
                  visibleCategories: visibleCategories,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterIdentityBackdrop extends StatelessWidget {
  const _CharacterIdentityBackdrop({required this.character});

  final WowCharacter character;

  @override
  Widget build(BuildContext context) {
    final faction = _identityKey(character.faction);

    String bannerAsset;

    switch (faction) {
      case 'alliance':
        bannerAsset = 'assets/images/bann/bann_perso_alliance.png';
        break;

      case 'horde':
        bannerAsset = 'assets/images/bann/bann_perso_horde.png';
        break;

      default:
        bannerAsset = 'assets/images/bann/bann_perso_horde.png';
    }

    return Positioned.fill(child: Image.asset(bannerAsset, fit: BoxFit.cover));
  }
}

String _identityKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('ç', 'c')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u');
}

Color _wowClassColor(String characterClass) {
  switch (_identityKey(characterClass)) {
    case 'chevalier de la mort':
      return const Color(0xFFC41E3A);
    case 'chasseur de demons':
      return const Color(0xFFA330C9);
    case 'druide':
      return const Color(0xFFFF7C0A);
    case 'evocateur':
      return const Color(0xFF33937F);
    case 'chasseur':
      return const Color(0xFFAAD372);
    case 'mage':
      return const Color(0xFF3FC7EB);
    case 'moine':
      return const Color(0xFF00FF98);
    case 'paladin':
      return const Color(0xFFF48CBA);
    case 'pretre':
      return const Color(0xFFFFFFFF);
    case 'voleur':
      return const Color(0xFFFFF468);
    case 'chaman':
      return const Color(0xFF0070DD);
    case 'demoniste':
      return const Color(0xFF8788EE);
    case 'guerrier':
      return const Color(0xFFC69B6D);
    default:
      return AppTheme.text;
  }
}

String _formatNumber(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();

  for (var index = 0; index < raw.length; index++) {
    final remaining = raw.length - index;
    buffer.write(raw[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(' ');
    }
  }

  return buffer.toString();
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
    final completionRate = progress.completionRateFor(visibleCategories);
    final percent = (completionRate * 100).round();
    final obtainableCompletionRate = progress.obtainableCompletionRateFor(
      visibleCategories,
    );
    final obtainablePercent = (obtainableCompletionRate * 100).round();

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
                color: Color.fromARGB(255, 248, 246, 243),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _DualProgressBars(
          completionRate: completionRate,
          obtainableCompletionRate: obtainableCompletionRate,
          obtainablePercent: obtainablePercent,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: visibleCategories.map((category) {
            final completed = progress.completed[category] ?? 0;
            final total = progress.total[category] ?? 0;
            final statPercent = total == 0
                ? 0
                : ((completed / total) * 100).round();

            return _MiniStat(
              label: category.shortLabel,
              value: '$completed/$total',
              percent: statPercent,
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
    required this.onAchievementsTap,
    required this.onMountsTap,
    required this.onPetsTap,
    required this.onFilterTap,
    required this.onSortTap,
  });

  final bool newestFirst;
  final VoidCallback onAchievementsTap;
  final VoidCallback onMountsTap;
  final VoidCallback onPetsTap;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    final collectableButtons = [
      OutlinedButton.icon(
        onPressed: onAchievementsTap,
        icon: const Icon(Icons.emoji_events_outlined),
        label: const Text('HF'),
      ),
      OutlinedButton.icon(
        onPressed: onMountsTap,
        icon: const Icon(Icons.pets),
        label: const Text('Montures'),
      ),
      OutlinedButton.icon(
        onPressed: onPetsTap,
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
          newestFirst ? Icons.vertical_align_bottom : Icons.vertical_align_top,
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
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: collectableButtons,
              ),
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
    required this.onOpenPlanner,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.visibleCategories,
  });

  final ExpansionProgress progress;
  final VoidCallback onOpenPlanner;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final Set<TrackingCategory> visibleCategories;

  @override
  Widget build(BuildContext context) {
    final completionRate = progress.completionRateFor(visibleCategories);
    final percent = (completionRate * 100).round();
    final obtainableCompletionRate = progress.obtainableCompletionRateFor(
      visibleCategories,
    );
    final obtainablePercent = (obtainableCompletionRate * 100).round();
    final info = WowExpansionCatalog.infoOf(progress.expansion);

    return InkWell(
      onTap: onOpenPlanner,
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
                    _DualProgressBars(
                      completionRate: completionRate,
                      obtainableCompletionRate: obtainableCompletionRate,
                      obtainablePercent: obtainablePercent,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: visibleCategories.map((category) {
                        final completed = progress.completed[category] ?? 0;
                        final total = progress.total[category] ?? 0;
                        final statPercent = total == 0
                            ? 0
                            : ((completed / total) * 100).round();

                        return _MiniStat(
                          label: category.shortLabel,
                          value: '$completed/$total',
                          percent: statPercent,
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

class _DualProgressBars extends StatelessWidget {
  const _DualProgressBars({
    required this.completionRate,
    required this.obtainableCompletionRate,
    required this.obtainablePercent,
  });

  final double completionRate;
  final double obtainableCompletionRate;
  final int obtainablePercent;

  @override
  Widget build(BuildContext context) {
    final safeCompletionRate = completionRate.clamp(0.0, 1.0).toDouble();
    final safeObtainableRate = obtainableCompletionRate
        .clamp(0.0, 1.0)
        .toDouble();

    return Column(
      children: [
        LinearProgressIndicator(
          value: safeCompletionRate,
          minHeight: 8,
          borderRadius: BorderRadius.circular(999),
          backgroundColor: Colors.white10,
          color: AppTheme.gold,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: safeObtainableRate,
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: Colors.white10,
                color: const Color(0xFF34D399),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$obtainablePercent%',
              style: const TextStyle(
                color: Color(0xFF34D399),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.percent,
  });

  final String label;
  final String value;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            '$percent%',
            style: const TextStyle(color: AppTheme.mutedText, fontSize: 11),
          ),
        ],
      ),
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
