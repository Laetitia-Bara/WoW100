import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wow100/core/services/battle_net_auth_service.dart';
import 'package:wow100/core/services/battle_net_session_service.dart';
import 'package:wow100/core/services/battle_net_token_service.dart';

import '../../../../core/ads/app_ads.dart';
import '../../../../core/services/selected_character_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/journey_step_bar.dart';
import '../../../../core/widgets/web_sponsor_panel.dart';
import '../../../../data/models/expansion_progress.dart';
import '../../../../data/models/tracking_category.dart';
import '../../../../data/models/wow_character.dart';
import '../../../../data/models/wow_expansion.dart';
import '../../../../data/models/wow_region_filter.dart';
import '../../../../data/repositories/battle_net_repository.dart';
import '../../../../data/repositories/planner_repository.dart';
import '../../../../data/repositories/progress_repository.dart';
import '../../../../data/sources/wow_expansion_catalog.dart';
import '../../../auth/presentation/pages/auth_callback_page.dart';
import '../../../auth/presentation/pages/character_switch_page.dart';
import '../../../legal/presentation/pages/legal_page.dart';
import '../../../planner/presentation/pages/planner_page.dart';
import '../../../planner/presentation/widgets/region_selector_sheet.dart';
import '../../../social/presentation/pages/battle_net_friends_page.dart';

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
  final PlannerRepository _plannerRepository = JsonPlannerRepository();
  final BattleNetRepository _battleNetRepository = BattleNetRepository();
  final SelectedCharacterService _selectedCharacterService =
      SelectedCharacterService();
  final BattleNetTokenService _battleNetTokenService = BattleNetTokenService();
  final BattleNetSessionService _battleNetSessionService =
      BattleNetSessionService();

  bool _newestFirst = false;
  bool _isLoading = true;
  List<ExpansionProgress> _progresses = [];
  WowCharacter? _mainCharacter;

  @override
  void initState() {
    super.initState();
    _loadCharacter();
    _loadProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_preloadLargePlannerCatalogs());
    });
  }

  Future<void> _preloadLargePlannerCatalogs() async {
    try {
      await _plannerRepository.preloadItems(
        WowExpansion.allAchievements,
        category: TrackingCategory.achievements,
      );
    } catch (e, stack) {
      debugPrint('PRELOAD ALL ACHIEVEMENTS ERROR: $e');
      debugPrint('$stack');
    }
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
    final hasValidSession = await _battleNetSessionService.hasValidSession();
    if (!hasValidSession) {
      if (!mounted) return;

      setState(() {
        _mainCharacter = null;
      });
      return;
    }

    final character = await _loadSelectedCharacterWithPortrait();

    if (!mounted) return;

    setState(() {
      _mainCharacter = character;
    });
  }

  Future<WowCharacter?> _loadSelectedCharacterWithPortrait() async {
    final character = await _selectedCharacterService.loadCharacter();

    if (character == null || character.portraitUrl?.isNotEmpty == true) {
      return character;
    }

    try {
      final token = await _battleNetTokenService.loadToken();
      if (token == null || token.isEmpty) return character;

      final characters = await _battleNetRepository.getCharacters(token);
      final refreshedCharacter = characters
          .where(
            (candidate) =>
                candidate.name == character.name &&
                candidate.realmSlug == character.realmSlug,
          )
          .firstOrNull;

      if (refreshedCharacter == null) return character;

      await _selectedCharacterService.saveCharacter(refreshedCharacter);
      return refreshedCharacter;
    } catch (_) {
      return character;
    }
  }

  Future<void> _disconnectBattleNet() async {
    final didOpenBattleNetLogout = await _battleNetSessionService
        .clearSessionAndOpenBattleNetLogout();

    if (!mounted) return;

    setState(() {
      _mainCharacter = null;
      _isLoading = true;
    });

    await _loadProgress();

    if (!mounted || !didOpenBattleNetLogout) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Session locale effacée. Battle.net a été ouvert pour terminer la déconnexion.',
        ),
      ),
    );
  }

  Future<void> _openBattleNetLogin() async {
    await _battleNetSessionService.clearSession();

    final service = BattleNetAuthService();
    final callbackUri = await service.openAuthorization(forceLogin: true);

    if (callbackUri == null || !mounted) {
      return;
    }

    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => AuthCallbackPage(
          code: callbackUri.queryParameters['code'],
          error: callbackUri.queryParameters['error'],
        ),
      ),
      (_) => false,
    );
  }

  Future<void> _openCharacterSwitch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CharacterSwitchPage()),
    );

    await _loadCharacter();
    await _loadProgress();
  }

  void _openBattleNetFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BattleNetFriendsPage()),
    );
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

  Future<void> _openRegionSelector() async {
    final result = await showModalBottomSheet<WowRegionFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RegionSelectorSheet(
        repository: _plannerRepository,
        newestFirst: _newestFirst,
      ),
    );

    if (result == null || !mounted) return;

    await _openPlanner(result.expansion, regionFilter: result);
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
    WowRegionFilter? regionFilter,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlannerPage(
          extension: expansion,
          category: category,
          regionFilter: regionFilter,
          newestFirst: _newestFirst,
        ),
      ),
    );

    await _loadProgress();
  }

  Future<void> _openSoloPlanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SoloPlannerPage()),
    );
  }

  Future<void> _openRoutePlanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoutePlannerPage()),
    );
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
            _BattleNetFriendsAction(onPressed: _openBattleNetFriends),
            IconButton(
              tooltip: 'Déconnexion',
              icon: const Icon(Icons.logout),
              onPressed: _disconnectBattleNet,
            ),
          ],
        ],
        bottom: JourneyStepBar(
          currentStep: 1,
          onStep1: () {},
          onStep2: _openSoloPlanner,
          onStep3: _openRoutePlanner,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableContentWidth = constraints.maxWidth >= 1280
              ? constraints.maxWidth - 300
              : constraints.maxWidth;
          final isWide = availableContentWidth >= 1000;

          return WebSponsorPageBody(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroCard(
                  character: _mainCharacter,
                  totalProgress: totalProgress,
                  visibleCategories: _visibleCategories,
                ),
                const SizedBox(height: 22),
                _DashboardSection(
                  title: 'Rechercher par catégorie',
                  child: _CategorySearchButtons(
                    onAchievementsTap: () => _openPlanner(
                      WowExpansion.allAchievements,
                      category: TrackingCategory.achievements,
                    ),
                    onMountsTap: () => _openPlanner(WowExpansion.allMounts),
                    onPetsTap: () => _openPlanner(
                      WowExpansion.allPets,
                      category: TrackingCategory.pets,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _DashboardSection(
                  title: 'Rechercher par zone',
                  child: _RegionSearchButton(onTap: _openRegionSelector),
                ),
                const SizedBox(height: 18),
                _ExtensionSearchHeader(
                  newestFirst: _newestFirst,
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
                          mainAxisExtent: 348,
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
          );
        },
      ),
      bottomNavigationBar: const AppBannerAd(),
    );
  }
}

class _BattleNetFriendsAction extends StatelessWidget {
  const _BattleNetFriendsAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 720;
    const battleNetBlue = Color(0xFF00AEFF);

    if (isCompact) {
      return IconButton(
        tooltip: 'Mes amis',
        icon: const Icon(Icons.group, color: battleNetBlue),
        onPressed: onPressed,
      );
    }

    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: battleNetBlue),
      onPressed: onPressed,
      icon: const Icon(Icons.group),
      label: const Text('Mes amis'),
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
    final portraitUrl = character?.portraitUrl;
    final hasPortrait = portraitUrl != null && portraitUrl.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showInlinePortrait = hasPortrait && constraints.maxWidth >= 560;
          final showInlineAchievementBadge =
              hasCharacter && constraints.maxWidth >= 430;

          return Stack(
            children: [
              if (hasCharacter)
                _CharacterIdentityBackdrop(character: character!),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
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
                            ],
                          ),
                        ),
                        if (showInlineAchievementBadge) ...[
                          const SizedBox(width: 14),
                          _AchievementPointsBadge(
                            points: character!.achievementPoints,
                          ),
                        ],
                        if (showInlinePortrait) ...[
                          const SizedBox(width: 16),
                          _CharacterPortraitFrame(imageUrl: portraitUrl),
                        ],
                      ],
                    ),
                    if (hasCharacter && !showInlineAchievementBadge) ...[
                      const SizedBox(height: 14),
                      _AchievementPointsBadge(
                        points: character!.achievementPoints,
                      ),
                    ],
                    if (hasPortrait && !showInlinePortrait) ...[
                      const SizedBox(height: 14),
                      _CharacterPortraitFrame(imageUrl: portraitUrl),
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
          );
        },
      ),
    );
  }
}

class _AchievementPointsBadge extends StatelessWidget {
  const _AchievementPointsBadge({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final formattedPoints = _formatNumber(points);

    return Semantics(
      label: 'Points de hauts faits $formattedPoints',
      child: Container(
        width: 166,
        height: 76,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFE7A3).withAlpha(230),
              AppTheme.gold.withAlpha(210),
              const Color(0xFF6D4110).withAlpha(220),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(130),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.gold.withAlpha(38),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF33100B).withAlpha(235),
                const Color(0xFF150713).withAlpha(235),
                const Color(0xFF4E170A).withAlpha(225),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.35, -0.35),
                      radius: 0.9,
                      colors: [
                        Color(0xFFFFF4BD),
                        Color(0xFFE6B64D),
                        Color(0xFF8D5611),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFE7A3).withAlpha(210),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withAlpha(70),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Color(0xFF3D2307),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Points de HF',
                        maxLines: 1,
                        style: TextStyle(
                          color: Color(0xFFEED58A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formattedPoints,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Color(0xFFFFE7A3),
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterPortraitFrame extends StatelessWidget {
  const _CharacterPortraitFrame({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 112,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.background.withAlpha(190),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.gold.withAlpha(145)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.black.withAlpha(95)),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              return const SizedBox.shrink();
            },
          ),
        ),
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

class _RegionSearchButton extends StatelessWidget {
  const _RegionSearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = constraints.maxWidth < 364
            ? constraints.maxWidth
            : 364.0;

        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: buttonWidth,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.travel_explore),
              label: const Text('Recherche par zone (En cours de travaux 🛠️)'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _CategorySearchButtons extends StatelessWidget {
  const _CategorySearchButtons({
    required this.onAchievementsTap,
    required this.onMountsTap,
    required this.onPetsTap,
  });

  final VoidCallback onAchievementsTap;
  final VoidCallback onMountsTap;
  final VoidCallback onPetsTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
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
      ],
    );
  }
}

class _ExtensionSearchHeader extends StatelessWidget {
  const _ExtensionSearchHeader({
    required this.newestFirst,
    required this.onFilterTap,
    required this.onSortTap,
  });

  final bool newestFirst;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Rechercher par extension',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Tooltip(
          message: 'Filtres',
          child: IconButton.outlined(
            onPressed: onFilterTap,
            icon: const Icon(Icons.filter_alt_outlined),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: newestFirst
              ? 'Ordre historique'
              : 'Extensions récentes en premier',
          child: IconButton.outlined(
            onPressed: onSortTap,
            icon: Icon(
              newestFirst
                  ? Icons.vertical_align_bottom
                  : Icons.vertical_align_top,
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _DashboardActionBar extends StatelessWidget {
  const _DashboardActionBar({
    required this.newestFirst,
    required this.onAchievementsTap,
    required this.onMountsTap,
    required this.onPetsTap,
    required this.onSoloPlannerTap,
    required this.onFilterTap,
    required this.onSortTap,
  });

  final bool newestFirst;
  final VoidCallback onAchievementsTap;
  final VoidCallback onMountsTap;
  final VoidCallback onPetsTap;
  final VoidCallback onSoloPlannerTap;
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

    final adventureButtons = [
      _AdventurePlannerButton(
        icon: Icons.explore_outlined,
        label: 'Solo',
        onPressed: onSoloPlannerTap,
      ),
      _AdventurePlannerButton(
        icon: Icons.groups_2_outlined,
        label: 'Avec des amis',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...collectableButtons,
              _AdventurePlannerButtonGroup(children: adventureButtons),
              ...toolButtons,
            ],
          );
        }

        return Row(
          children: [
            Wrap(spacing: 10, runSpacing: 10, children: collectableButtons),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: _AdventurePlannerButtonGroup(children: adventureButtons),
              ),
            ),
            const SizedBox(width: 16),
            Wrap(spacing: 8, children: toolButtons),
          ],
        );
      },
    );
  }
}

class _AdventurePlannerButtonGroup extends StatelessWidget {
  const _AdventurePlannerButtonGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppTheme.gold,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Partir en balade', style: labelStyle),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        ),
      ],
    );
  }
}

class _AdventurePlannerButton extends StatelessWidget {
  const _AdventurePlannerButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: onPressed == null ? 'Planner en construction' : label,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return AppTheme.gold.withValues(alpha: 0.20);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return AppTheme.gold;
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.resolveWith((states) {
            return BorderSide(
              color: AppTheme.gold.withValues(alpha: 0.75),
              width: 1.2,
            );
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ),
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
                      obtainableLabel: 'Obtenables',
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
                    const SizedBox(height: 12),
                    _MissingObtainableSummary(
                      progress: progress,
                      visibleCategories: visibleCategories,
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

class _MissingObtainableSummary extends StatelessWidget {
  const _MissingObtainableSummary({
    required this.progress,
    required this.visibleCategories,
  });

  final ExpansionProgress progress;
  final Set<TrackingCategory> visibleCategories;

  @override
  Widget build(BuildContext context) {
    if (visibleCategories.isEmpty) return const SizedBox.shrink();

    final missingEntries = visibleCategories
        .map((category) {
          final completed = progress.completedObtainable[category] ?? 0;
          final total = progress.obtainableTotal[category] ?? 0;
          final missing = (total - completed).clamp(0, total);

          return MapEntry(category, missing);
        })
        .where((entry) => entry.value > 0)
        .toList();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Tu peux encore aller farmer :',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (missingEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                "Plus rien ! tu as déjà tout ce qui est possible d'obtenir dans cette extension ! GG à toi ;)",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            )
          else
            Text(
              missingEntries
                  .map((entry) {
                    final missing = entry.value;

                    return '$missing ${_missingCategoryLabel(entry.key, missing)}';
                  })
                  .join('  -  '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF34D399),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
        ],
      ),
    );
  }
}

String _missingCategoryLabel(TrackingCategory category, int count) {
  final plural = count != 1;

  switch (category) {
    case TrackingCategory.achievements:
      return 'HF';
    case TrackingCategory.mounts:
      return plural ? 'Montures' : 'Monture';
    case TrackingCategory.pets:
      return plural ? 'Mascottes' : 'Mascotte';
    default:
      return category.shortLabel;
  }
}

class _DualProgressBars extends StatelessWidget {
  const _DualProgressBars({
    required this.completionRate,
    required this.obtainableCompletionRate,
    required this.obtainablePercent,
    this.obtainableLabel = 'Obtenables : Hors items indisponibles',
  });

  final double completionRate;
  final double obtainableCompletionRate;
  final int obtainablePercent;
  final String obtainableLabel;

  @override
  Widget build(BuildContext context) {
    final safeCompletionRate = completionRate.clamp(0.0, 1.0).toDouble();
    final safeObtainableRate = obtainableCompletionRate
        .clamp(0.0, 1.0)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 4),
        Text(
          obtainableLabel,
          style: const TextStyle(color: Color(0xFF34D399), fontSize: 11),
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
