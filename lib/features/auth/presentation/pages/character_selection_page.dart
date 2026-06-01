import 'package:flutter/material.dart';

import '../../../../core/services/selected_character_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/wow_character.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';

class CharacterSelectionPage extends StatefulWidget {
  const CharacterSelectionPage({super.key, required this.characters});

  final List<WowCharacter> characters;

  @override
  State<CharacterSelectionPage> createState() => _CharacterSelectionPageState();
}

class _CharacterSelectionPageState extends State<CharacterSelectionPage> {
  final SelectedCharacterService _service = SelectedCharacterService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un personnage')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final character in widget.characters)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  character.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${character.characterClass} ${character.level} • ${character.realm} • ${character.faction}',
                  style: const TextStyle(color: AppTheme.mutedText),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await _service.saveCharacter(character);

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const DashboardPage()),
                    (route) => false,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
