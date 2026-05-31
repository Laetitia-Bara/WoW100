import 'package:flutter/material.dart';
import 'package:wow100/data/models/tracking_category.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/tracking_item.dart';
import '../../../../data/models/wow_expansion.dart';
import '../../../../data/sources/mock_planner_source.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/wowhead_url_builder.dart';
import '../../../../data/repositories/planner_repository.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key, required this.extension});

  final WowExpansion extension;

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  List<TrackingItem> _items = [];
  final PlannerRepository _repository = MockPlannerRepository();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _repository.getItems(widget.extension);

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = <String, List<TrackingItem>>{};

    final obtainedCount = _items.where((item) => item.obtained).length;

    final totalCount = _items.length;

    final progress = totalCount == 0 ? 0.0 : obtainedCount / totalCount;

    for (final item in _items) {
      groupedItems.putIfAbsent(item.instance, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.extension.label),
        actions: [
          IconButton(
            tooltip: 'Tout décocher',
            icon: const Icon(Icons.refresh),
            onPressed: () {
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

                if (_items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Aucun élément mocké pour cette extension pour le moment.',
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
                      onChanged: (value) {
                        setState(() {
                          _items = _items.map((current) {
                            if (current.id == item.id) {
                              return current.copyWith(obtained: value ?? false);
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
      item.category.label,
      item.weeklyLockout ? 'Hebdomadaire' : 'Farm libre',
      item.groupRequired ? 'Groupe conseillé' : 'Solo possible',
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
                '${item.zone} • ${item.source}',
                style: const TextStyle(color: AppTheme.mutedText),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) => _PlannerTag(label: tag)).toList(),
              ),
            ],
          ),
        ),
        secondary: IconButton(
          tooltip: 'Ouvrir sur Wowhead',
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
