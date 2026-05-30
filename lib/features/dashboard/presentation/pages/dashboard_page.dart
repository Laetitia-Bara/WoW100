import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import './planner_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final extensions = [
      'Vue totale',
      'Vanilla',
      'The Burning Crusade',
      'Wrath of the Lich King',
      'Cataclysm',
      'Mists of Pandaria',
      'Warlords of Draenor',
      'Legion',
      'Battle for Azeroth',
      'Shadowlands',
      'Dragonflight',
      'The War Within',
      'Midnight',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('WoW100%'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_alt_outlined),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.sort_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _HeroCard(),
          const SizedBox(height: 20),
          for (final extension in extensions)
            _ExpansionCard(
              title: extension,
              progress: extension == 'Vue totale' ? 42 : 18,
              onTap: extension == 'Vue totale'
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlannerPage(extensionName: extension),
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
    required this.title,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final int progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
                  const Icon(Icons.keyboard_arrow_down),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '$progress%',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: Colors.white10,
                color: AppTheme.gold,
              ),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MiniStat(label: 'HF', value: '12/120'),
                  _MiniStat(label: 'Montures', value: '4/30'),
                  _MiniStat(label: 'Mascottes', value: '8/55'),
                  _MiniStat(label: 'Métiers', value: '2/10'),
                ],
              ),
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
