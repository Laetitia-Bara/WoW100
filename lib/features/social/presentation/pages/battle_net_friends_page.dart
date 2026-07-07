import 'package:flutter/material.dart';

import '../../../../core/ads/app_ads.dart';
import '../../../../core/services/battle_net_friend_service.dart';
import '../../../../core/services/battle_net_token_service.dart';
import '../../../../core/services/selected_character_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/battle_net_friend.dart';
import '../../../../data/models/wow_character.dart';
import '../../../../data/repositories/battle_net_repository.dart';

const _battleNetBlue = Color(0xFF00AEFF);
const _regions = ['EU', 'US', 'KR', 'TW'];

class BattleNetFriendsPage extends StatefulWidget {
  const BattleNetFriendsPage({super.key});

  @override
  State<BattleNetFriendsPage> createState() => _BattleNetFriendsPageState();
}

class _BattleNetFriendsPageState extends State<BattleNetFriendsPage> {
  final _repository = BattleNetRepository();
  final _friendService = BattleNetFriendService();
  final _tokenService = BattleNetTokenService();
  final _selectedCharacterService = SelectedCharacterService();
  final _realmController = TextEditingController();
  final _characterController = TextEditingController();

  List<BattleNetFriend> _friends = [];
  List<BattleNetFriend> _guildMembers = [];
  WowCharacter? _mainCharacter;
  BattleNetFriend? _manualPreview;
  String _selectedRegion = 'EU';
  String? _guildName;
  String? _manualError;
  String? _guildError;
  bool _isLoadingFriends = true;
  bool _isManualLookupLoading = false;
  bool _isGuildLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _realmController.dispose();
    _characterController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      _friendService.loadFriends(),
      _selectedCharacterService.loadCharacter(),
    ]);

    if (!mounted) return;

    setState(() {
      _friends = results[0] as List<BattleNetFriend>;
      _mainCharacter = results[1] as WowCharacter?;
      _isLoadingFriends = false;
    });
  }

  Future<void> _reloadFriends() async {
    final friends = await _friendService.loadFriends();
    if (!mounted) return;

    setState(() {
      _friends = friends;
    });
  }

  Future<void> _lookupManualFriend() async {
    final realm = _realmController.text.trim();
    final characterName = _characterController.text.trim();

    if (realm.isEmpty || characterName.isEmpty) {
      setState(() {
        _manualPreview = null;
        _manualError = 'Indique un serveur et un personnage.';
      });
      return;
    }

    final token = await _tokenService.loadToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _manualPreview = null;
        _manualError = 'Reconnecte Battle.net avant de chercher un profil.';
      });
      return;
    }

    setState(() {
      _isManualLookupLoading = true;
      _manualError = null;
      _manualPreview = null;
    });

    try {
      final friend = await _repository.lookupCharacterProfile(
        token,
        region: _selectedRegion,
        realmSlug: realm,
        characterName: characterName,
      );

      if (!mounted) return;

      setState(() {
        _manualPreview = friend;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _manualError =
            'Profil introuvable. Verifie la region, le serveur et le nom.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isManualLookupLoading = false;
        });
      }
    }
  }

  Future<void> _loadGuildMembers() async {
    final mainCharacter = _mainCharacter;
    if (mainCharacter == null) {
      setState(() {
        _guildError = 'Choisis d abord ton personnage principal.';
      });
      return;
    }

    final token = await _tokenService.loadToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _guildError = 'Reconnecte Battle.net avant de charger la guilde.';
      });
      return;
    }

    setState(() {
      _isGuildLoading = true;
      _guildError = null;
      _guildMembers = [];
      _guildName = null;
    });

    try {
      final profile = await _repository.lookupCharacterProfile(
        token,
        region: 'EU',
        realmSlug: mainCharacter.realmSlug,
        characterName: mainCharacter.name,
      );
      final guildName = profile.guildName;
      final guildRealmSlug = profile.guildRealmSlug ?? profile.realmSlug;

      if (guildName == null || guildName.isEmpty || guildRealmSlug.isEmpty) {
        if (!mounted) return;

        setState(() {
          _guildError = '${mainCharacter.name} ne semble pas etre en guilde.';
        });
        return;
      }

      final members = await _repository.getGuildRoster(
        token,
        region: profile.region,
        realmSlug: guildRealmSlug,
        guildName: guildName,
      );

      if (!mounted) return;

      setState(() {
        _guildName = guildName;
        _guildMembers = members;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _guildError = 'Impossible de charger la guilde pour le moment.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGuildLoading = false;
        });
      }
    }
  }

  Future<void> _saveFriend(BattleNetFriend friend) async {
    await _friendService.saveFriend(friend);
    await _reloadFriends();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${friend.name} a ete ajoute a tes amis.')),
    );
  }

  Future<void> _removeFriend(BattleNetFriend friend) async {
    await _friendService.removeFriend(friend);
    await _reloadFriends();
  }

  bool _isSaved(BattleNetFriend friend) {
    return _friends.any((saved) => saved.storageKey == friend.storageKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes amis')),
      body: _isLoadingFriends
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 920;
                final topCards = [
                  _GuildLookupCard(
                    mainCharacter: _mainCharacter,
                    guildName: _guildName,
                    members: _guildMembers,
                    error: _guildError,
                    isLoading: _isGuildLoading,
                    isSaved: _isSaved,
                    onLoadGuild: _loadGuildMembers,
                    onSaveFriend: _saveFriend,
                  ),
                  _ManualLookupCard(
                    selectedRegion: _selectedRegion,
                    realmController: _realmController,
                    characterController: _characterController,
                    preview: _manualPreview,
                    error: _manualError,
                    isLoading: _isManualLookupLoading,
                    isSaved: _manualPreview == null
                        ? false
                        : _isSaved(_manualPreview!),
                    onRegionChanged: (region) {
                      if (region == null) return;
                      setState(() {
                        _selectedRegion = region;
                        _manualPreview = null;
                        _manualError = null;
                      });
                    },
                    onLookup: _lookupManualFriend,
                    onSaveFriend: _manualPreview == null
                        ? null
                        : () => _saveFriend(_manualPreview!),
                  ),
                ];

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          sliver: SliverToBoxAdapter(
                            child: isWide
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: topCards[0]),
                                      const SizedBox(width: 14),
                                      Expanded(child: topCards[1]),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      topCards[0],
                                      const SizedBox(height: 14),
                                      topCards[1],
                                    ],
                                  ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'Liste locale',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        if (_friends.isEmpty)
                          const SliverPadding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 18),
                            sliver: SliverToBoxAdapter(
                              child: _EmptyFriendsCard(),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                            sliver: SliverGrid.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isWide ? 2 : 1,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    mainAxisExtent: 116,
                                  ),
                              itemCount: _friends.length,
                              itemBuilder: (context, index) {
                                final friend = _friends[index];

                                return _FriendCard(
                                  friend: friend,
                                  trailing: IconButton(
                                    tooltip: 'Retirer',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _removeFriend(friend),
                                  ),
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
      bottomNavigationBar: const AppBannerAd(),
    );
  }
}

class _GuildLookupCard extends StatelessWidget {
  const _GuildLookupCard({
    required this.mainCharacter,
    required this.guildName,
    required this.members,
    required this.error,
    required this.isLoading,
    required this.isSaved,
    required this.onLoadGuild,
    required this.onSaveFriend,
  });

  final WowCharacter? mainCharacter;
  final String? guildName;
  final List<BattleNetFriend> members;
  final String? error;
  final bool isLoading;
  final bool Function(BattleNetFriend friend) isSaved;
  final VoidCallback onLoadGuild;
  final ValueChanged<BattleNetFriend> onSaveFriend;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.shield_outlined,
      title: 'Guilde',
      subtitle: mainCharacter == null
          ? 'Choisis un personnage principal pour charger sa guilde.'
          : 'Depuis ${mainCharacter!.name} - ${mainCharacter!.realm}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.background,
            ),
            onPressed: isLoading ? null : onLoadGuild,
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.groups),
            label: Text(isLoading ? 'Chargement...' : 'Charger ma guilde'),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            _InlineMessage(text: error!, isError: true),
          ],
          if (guildName != null) ...[
            const SizedBox(height: 12),
            Text(
              guildName!,
              style: const TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${members.length} membres trouves',
              style: const TextStyle(color: AppTheme.mutedText),
            ),
          ],
          if (members.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: members.length,
                separatorBuilder: (_, _) => Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final saved = isSaved(member);

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      member.name,
                      style: TextStyle(
                        color: _wowClassColor(member.characterClass),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${member.characterClass} ${member.level} - ${member.realm}',
                      style: const TextStyle(color: AppTheme.mutedText),
                    ),
                    trailing: IconButton(
                      tooltip: saved ? 'Deja ajoute' : 'Ajouter',
                      icon: Icon(
                        saved ? Icons.check_circle : Icons.person_add_alt,
                        color: saved ? AppTheme.gold : _battleNetBlue,
                      ),
                      onPressed: saved ? null : () => onSaveFriend(member),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ManualLookupCard extends StatelessWidget {
  const _ManualLookupCard({
    required this.selectedRegion,
    required this.realmController,
    required this.characterController,
    required this.preview,
    required this.error,
    required this.isLoading,
    required this.isSaved,
    required this.onRegionChanged,
    required this.onLookup,
    required this.onSaveFriend,
  });

  final String selectedRegion;
  final TextEditingController realmController;
  final TextEditingController characterController;
  final BattleNetFriend? preview;
  final String? error;
  final bool isLoading;
  final bool isSaved;
  final ValueChanged<String?> onRegionChanged;
  final VoidCallback onLookup;
  final VoidCallback? onSaveFriend;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.person_search,
      title: 'Ajout manuel',
      subtitle: 'Cherche un profil par region, serveur et personnage.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 104,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedRegion,
                  decoration: const InputDecoration(labelText: 'Region'),
                  items: [
                    for (final region in _regions)
                      DropdownMenuItem(value: region, child: Text(region)),
                  ],
                  onChanged: onRegionChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: realmController,
                  decoration: const InputDecoration(
                    labelText: 'Serveur',
                    hintText: 'ex: Hyjal',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: characterController,
            decoration: const InputDecoration(
              labelText: 'Personnage',
              hintText: 'Nom du personnage',
            ),
            onSubmitted: (_) => onLookup(),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _battleNetBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: isLoading ? null : onLookup,
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(isLoading ? 'Recherche...' : 'Lookup'),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            _InlineMessage(text: error!, isError: true),
          ],
          if (preview != null) ...[
            const SizedBox(height: 14),
            _FriendSummaryPanel(
              friend: preview!,
              trailing: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: isSaved ? AppTheme.card : _battleNetBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaved ? null : onSaveFriend,
                icon: Icon(isSaved ? Icons.check : Icons.person_add_alt),
                label: Text(isSaved ? 'Ajoute' : 'Ajouter'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FriendSummaryPanel extends StatelessWidget {
  const _FriendSummaryPanel({required this.friend, required this.trailing});

  final BattleNetFriend friend;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _FriendListTile(friend: friend, trailing: trailing),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _battleNetBlue.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _battleNetBlue.withValues(alpha: 0.38),
                    ),
                  ),
                  child: Icon(icon, color: _battleNetBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend, required this.trailing});

  final BattleNetFriend friend;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: _FriendListTile(friend: friend, trailing: trailing),
    );
  }
}

class _FriendListTile extends StatelessWidget {
  const _FriendListTile({required this.friend, required this.trailing});

  final BattleNetFriend friend;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final guildName = friend.guildName;
    final hasPortrait =
        friend.portraitUrl != null && friend.portraitUrl!.isNotEmpty;

    return ListTile(
      minVerticalPadding: 12,
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: _battleNetBlue.withValues(alpha: 0.16),
        foregroundImage: hasPortrait ? NetworkImage(friend.portraitUrl!) : null,
        child: hasPortrait ? null : const Icon(Icons.person),
      ),
      title: Text(
        friend.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _wowClassColor(friend.characterClass),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${friend.characterClass} ${friend.level} - ${friend.region} ${friend.realm}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.mutedText),
            ),
            if (guildName != null) ...[
              const SizedBox(height: 3),
              Text(
                '<$guildName>',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (friend.achievementPoints > 0) ...[
              const SizedBox(height: 3),
              Text(
                '${_formatNumber(friend.achievementPoints)} points de HF',
                style: const TextStyle(color: AppTheme.mutedText),
              ),
            ],
          ],
        ),
      ),
      trailing: trailing,
    );
  }
}

class _EmptyFriendsCard extends StatelessWidget {
  const _EmptyFriendsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: const [
            Icon(Icons.group_add_outlined, color: AppTheme.gold),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucun ami enregistre. Utilise la recherche ou ta guilde pour en ajouter.',
                style: TextStyle(color: AppTheme.mutedText, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFF87171) : AppTheme.gold;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
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
