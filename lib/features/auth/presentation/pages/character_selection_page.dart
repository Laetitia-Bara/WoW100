import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/services/battle_net_session_service.dart';
import '../../../../core/services/selected_character_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/wow_character.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';

const _playableRaces = <_CollectionEntry>[
  _CollectionEntry('Humain', tag: 'A'),
  _CollectionEntry('Nain', tag: 'A'),
  _CollectionEntry('Elfe de la nuit', tag: 'A'),
  _CollectionEntry('Gnome', tag: 'A'),
  _CollectionEntry('Draeneï', tag: 'A'),
  _CollectionEntry('Worgen', tag: 'A'),
  _CollectionEntry('Elfe du Vide', tag: 'A'),
  _CollectionEntry('Draeneï sancteforge', tag: 'A'),
  _CollectionEntry('Nain sombrefer', tag: 'A'),
  _CollectionEntry('Kultirassien', tag: 'A', aliases: ['Humain de Kul Tiras']),
  _CollectionEntry('Mécagnome', tag: 'A'),
  _CollectionEntry('Orc', tag: 'H'),
  _CollectionEntry('Mort-vivant', tag: 'H', aliases: ['Réprouvé']),
  _CollectionEntry('Tauren', tag: 'H'),
  _CollectionEntry('Troll', tag: 'H'),
  _CollectionEntry('Elfe de sang', tag: 'H'),
  _CollectionEntry('Gobelin', tag: 'H'),
  _CollectionEntry('Sacrenuit', tag: 'H'),
  _CollectionEntry('Tauren de Haut-Roc', tag: 'H'),
  _CollectionEntry('Troll zandalari', tag: 'H'),
  _CollectionEntry('Orc mag’har', tag: 'H', aliases: ["Orc mag'har"]),
  _CollectionEntry('Vulperin', tag: 'H'),
  _CollectionEntry('Pandaren', tag: 'A/H'),
  _CollectionEntry('Dracthyr', tag: 'A/H'),
  _CollectionEntry('Terrestre', tag: 'A/H'),
  _CollectionEntry('Haranir', tag: 'A/H'),
];

const _playableClasses = <_CollectionEntry>[
  _CollectionEntry('Chevalier de la mort'),
  _CollectionEntry('Chasseur de démons'),
  _CollectionEntry('Druide'),
  _CollectionEntry('Évocateur'),
  _CollectionEntry('Chasseur'),
  _CollectionEntry('Mage'),
  _CollectionEntry('Moine'),
  _CollectionEntry('Paladin'),
  _CollectionEntry('Prêtre'),
  _CollectionEntry('Voleur'),
  _CollectionEntry('Chaman'),
  _CollectionEntry('Démoniste'),
  _CollectionEntry('Guerrier'),
];

const _playableProfessions = <_CollectionEntry>[
  _CollectionEntry('Alchimie'),
  _CollectionEntry('Calligraphie'),
  _CollectionEntry('Couture'),
  _CollectionEntry('Dépeçage'),
  _CollectionEntry('Enchantement'),
  _CollectionEntry('Forge'),
  _CollectionEntry('Herboristerie'),
  _CollectionEntry('Ingénierie'),
  _CollectionEntry('Joaillerie'),
  _CollectionEntry('Minage'),
  _CollectionEntry('Travail du cuir'),
  _CollectionEntry('Cuisine'),
  _CollectionEntry('Pêche'),
  _CollectionEntry('Archéologie'),
];

class _CollectionEntry {
  const _CollectionEntry(this.name, {this.tag, this.aliases = const []});

  final String name;
  final String? tag;
  final List<String> aliases;

  bool isOwnedBy(Set<String> ownedKeys) {
    return ownedKeys.contains(_collectionKey(name)) ||
        aliases.any((alias) => ownedKeys.contains(_collectionKey(alias)));
  }
}

String _collectionKey(String value) {
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
      .replaceAll('ü', 'u')
      .replaceAll('’', "'")
      .replaceAll(RegExp(r"[^a-z0-9']+"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

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

  Future<void> _disconnectBattleNet() async {
    await BattleNetSessionService(
      selectedCharacterService: _service,
    ).clearSession();

    if (!mounted) return;

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
    final ownedRaceKeys = characters
        .map((character) => _collectionKey(character.race))
        .where((key) => key.isNotEmpty)
        .toSet();
    final ownedClassKeys = characters
        .map((character) => _collectionKey(character.characterClass))
        .where((key) => key.isNotEmpty)
        .toSet();
    final ownedProfessionKeys = characters
        .expand((character) => character.professions)
        .map(_collectionKey)
        .where((key) => key.isNotEmpty)
        .toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes personnages...'),
        actions: [
          IconButton(
            tooltip: 'Déconnexion Battle.net',
            icon: const Icon(Icons.logout),
            onPressed: _disconnectBattleNet,
          ),
        ],
      ),
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
                    sliver: SliverToBoxAdapter(
                      child: _CharacterCollectionOverview(
                        ownedRaceKeys: ownedRaceKeys,
                        ownedClassKeys: ownedClassKeys,
                        ownedProfessionKeys: ownedProfessionKeys,
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

class _CharacterCollectionOverview extends StatelessWidget {
  const _CharacterCollectionOverview({
    required this.ownedRaceKeys,
    required this.ownedClassKeys,
    required this.ownedProfessionKeys,
  });

  final Set<String> ownedRaceKeys;
  final Set<String> ownedClassKeys;
  final Set<String> ownedProfessionKeys;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CollectionCard(
        title: 'Races',
        icon: Icons.groups,
        entries: _playableRaces,
        ownedKeys: ownedRaceKeys,
      ),
      _CollectionCard(
        title: 'Classes',
        icon: Icons.auto_awesome,
        entries: _playableClasses,
        ownedKeys: ownedClassKeys,
      ),
      _CollectionCard(
        title: 'Métiers',
        icon: Icons.handyman,
        entries: _playableProfessions,
        ownedKeys: ownedProfessionKeys,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return SizedBox(
            height: 282,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  Expanded(child: cards[index]),
                  if (index < cards.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
          );
        }

        final cardWidth = math.min(340.0, constraints.maxWidth * 0.88);

        return SizedBox(
          height: 262,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(width: cardWidth, child: cards[index]);
            },
          ),
        );
      },
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.title,
    required this.icon,
    required this.entries,
    required this.ownedKeys,
  });

  final String title;
  final IconData icon;
  final List<_CollectionEntry> entries;
  final Set<String> ownedKeys;

  @override
  Widget build(BuildContext context) {
    final ownedCount = entries
        .where((entry) => entry.isOwnedBy(ownedKeys))
        .length;
    final statusColor = _collectionStatusColor(ownedCount, entries.length);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      statusColor.withAlpha(28),
                      AppTheme.card,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: statusColor, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CollectionCountBadge(
                  value: '$ownedCount/${entries.length}',
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in entries)
                      _CollectionChip(
                        entry: entry,
                        isOwned: entry.isOwnedBy(ownedKeys),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _collectionStatusColor(int ownedCount, int totalCount) {
  if (ownedCount <= 0) {
    return AppTheme.text;
  }

  if (ownedCount >= totalCount) {
    return const Color(0xFF34D399);
  }

  return AppTheme.gold;
}

class _CollectionCountBadge extends StatelessWidget {
  const _CollectionCountBadge({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withAlpha(32), AppTheme.card),
        border: Border.all(color: color.withAlpha(170)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CollectionChip extends StatelessWidget {
  const _CollectionChip({required this.entry, required this.isOwned});

  final _CollectionEntry entry;
  final bool isOwned;

  @override
  Widget build(BuildContext context) {
    final color = isOwned ? const Color(0xFF34D399) : AppTheme.mutedText;

    return Tooltip(
      message: isOwned ? '${entry.name} présent' : '${entry.name} manquant',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.tag != null) ...[
              _FactionTag(label: entry.tag!, isOwned: isOwned),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isOwned ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactionTag extends StatelessWidget {
  const _FactionTag({required this.label, required this.isOwned});

  final String label;
  final bool isOwned;

  @override
  Widget build(BuildContext context) {
    final color = isOwned ? const Color(0xFF34D399) : AppTheme.mutedText;

    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color.withAlpha(isOwned ? 210 : 150),
        fontSize: 9,
        fontWeight: FontWeight.w900,
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
