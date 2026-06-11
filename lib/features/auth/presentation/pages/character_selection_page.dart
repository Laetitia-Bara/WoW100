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

  WowCharacter? _mainCharacter;

  @override
  void initState() {
    super.initState();
    _loadMainCharacter();
  }

  Future<void> _loadMainCharacter() async {
    final character = await _service.loadCharacter();

    if (!mounted) return;

    setState(() {
      _mainCharacter = character;
    });
  }

  Future<void> _setMainCharacter(WowCharacter character) async {
    await _service.saveCharacter(character);

    if (!mounted) return;

    setState(() {
      _mainCharacter = character;
    });
  }

  Future<void> _selectCharacter(
    BuildContext context,
    WowCharacter character,
  ) async {
    await _setMainCharacter(character);

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (route) => false,
    );
  }

  List<WowCharacter> _sortedCharacters() {
    return [...widget.characters]..sort((a, b) {
      final levelCompare = b.level.compareTo(a.level);
      if (levelCompare != 0) return levelCompare;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  bool _isMainCharacter(WowCharacter character) {
    final main = _mainCharacter;
    if (main == null) return false;

    return main.name == character.name && main.realmSlug == character.realmSlug;
  }

  Color _classColor(String characterClass) {
    switch (characterClass.toLowerCase()) {
      case 'chevalier de la mort':
        return const Color(0xFFC41E3A);
      case 'chasseur de demons':
      case 'chasseur de démons':
        return const Color(0xFFA330C9);
      case 'druide':
        return const Color(0xFFFF7C0A);
      case 'evocateur':
      case 'évocateur':
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
      case 'prêtre':
        return const Color(0xFFFFFFFF);
      case 'voleur':
        return const Color(0xFFFFF468);
      case 'chaman':
        return const Color(0xFF0070DD);
      case 'demoniste':
      case 'démoniste':
        return const Color(0xFF8788EE);
      case 'guerrier':
        return const Color(0xFFC69B6D);
      default:
        return Colors.white;
    }
  }

  Color _factionColor(String faction) {
    switch (faction.toLowerCase()) {
      case 'alliance':
        return const Color(0xFF2E8CFF);
      case 'horde':
        return const Color(0xFFE23B3B);
      default:
        return AppTheme.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final characters = _sortedCharacters();

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 2 : 1;
          final contentWidth = constraints.maxWidth >= 900
              ? 1180.0
              : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        '${characters.length} personnages trouvés',
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 78,
                      ),
                      itemCount: characters.length,
                      itemBuilder: (context, index) {
                        final character = characters[index];

                        return _CharacterCard(
                          character: character,
                          classColor: _classColor(character.characterClass),
                          factionColor: _factionColor(character.faction),
                          isMainCharacter: _isMainCharacter(character),
                          onFavoriteTap: () => _setMainCharacter(character),
                          onTap: () => _selectCharacter(context, character),
                        );
                      },
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

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.classColor,
    required this.factionColor,
    required this.isMainCharacter,
    required this.onFavoriteTap,
    required this.onTap,
  });

  final WowCharacter character;
  final Color classColor;
  final Color factionColor;
  final bool isMainCharacter;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(
          character.name,
          style: TextStyle(color: classColor, fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${character.characterClass} ${character.level}',
                style: const TextStyle(color: AppTheme.mutedText),
              ),
              const Text('•', style: TextStyle(color: AppTheme.mutedText)),
              Text(
                character.realm,
                style: const TextStyle(color: AppTheme.mutedText),
              ),
              const Text('•', style: TextStyle(color: AppTheme.mutedText)),
              Text(
                character.faction,
                style: TextStyle(
                  color: factionColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: isMainCharacter
                  ? 'Personnage principal'
                  : 'Définir comme personnage principal',
              icon: Icon(
                isMainCharacter ? Icons.star : Icons.star_border,
                color: isMainCharacter ? AppTheme.gold : AppTheme.mutedText,
              ),
              onPressed: onFavoriteTap,
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
