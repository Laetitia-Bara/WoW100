import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../planner/presentation/pages/planner_page.dart';
import '../../../../data/models/expansion_progress.dart';
import '../../../../data/models/tracking_category.dart';
import '../../../../data/models/wow_expansion.dart';
import '../../../../data/sources/mock_progress_source.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Set<WowExpansion> _collapsedExpansions = {};
  bool _newestFirst = false;

  @override
  Widget build(BuildContext context) {
    final progresses = MockProgressSource.getProgress();

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
            onPressed: () {},
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
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlannerPage(
                            extensionName: progress.expansion.label,
                          ),
                        ),
                      );
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
  });

  final ExpansionProgress progress;
  final VoidCallback? onTap;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.completionRate * 100).round();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
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
                      progress.expansion.label,
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
                  children: TrackingCategory.values.map((category) {
                    final completed = progress.completed[category] ?? 0;
                    final total = progress.total[category] ?? 0;

                    return _MiniStat(
                      label: category.label,
                      value: '$completed/$total',
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
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
