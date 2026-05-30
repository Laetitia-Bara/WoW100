import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PlannerPage extends StatelessWidget {
  const PlannerPage({super.key, required this.extensionName});

  final String extensionName;

  @override
  Widget build(BuildContext context) {
    final missingItems = [
      'Haut-fait : Exploration complète',
      'Monture : Rênes du destrier de la mort',
      'Mascotte : Jeune dragonnet sombre',
      'Métier : Cuisine classique',
      'Réputation : Aube d’argent',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(extensionName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'À récupérer dans cette extension',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Liste provisoire mockée. Plus tard elle sera croisée avec ta progression Battle.net.',
            style: TextStyle(color: AppTheme.mutedText),
          ),
          const SizedBox(height: 20),
          for (final item in missingItems)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: CheckboxListTile(
                value: false,
                onChanged: (_) {},
                title: Text(item),
                subtitle: const Text(
                  'Source : zone / donjon / raid à définir',
                  style: TextStyle(color: AppTheme.mutedText),
                ),
                secondary: const Icon(Icons.location_on_outlined),
              ),
            ),
        ],
      ),
    );
  }
}
