import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class WebSponsorPageBody extends StatelessWidget {
  const WebSponsorPageBody({
    super.key,
    required this.content,
    this.contentMaxWidth = 1180,
  });

  static const double _sidebarWidth = 280;
  static const double _sidebarGap = 20;
  static const double _sidebarBreakpoint = 1280;

  final Widget content;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar =
            kIsWeb && constraints.maxWidth >= _sidebarBreakpoint;
        final maxWidth = showSidebar
            ? contentMaxWidth + _sidebarGap + _sidebarWidth
            : contentMaxWidth;

        if (showSidebar) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: SingleChildScrollView(child: content)),
                    const SizedBox(width: _sidebarGap),
                    const SizedBox(
                      width: _sidebarWidth,
                      child: WebSponsorPanel(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (kIsWeb) ...[
                    const WebSponsorPanel(compact: true),
                    const SizedBox(height: 20),
                  ],
                  content,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class WebSponsorSliverPageBody extends StatelessWidget {
  const WebSponsorSliverPageBody({
    super.key,
    required this.slivers,
    this.contentMaxWidth = 1180,
  });

  static const double _sidebarWidth = WebSponsorPageBody._sidebarWidth;
  static const double _sidebarGap = WebSponsorPageBody._sidebarGap;
  static const double _sidebarBreakpoint =
      WebSponsorPageBody._sidebarBreakpoint;

  final List<Widget> slivers;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar =
            kIsWeb && constraints.maxWidth >= _sidebarBreakpoint;
        final maxWidth = showSidebar
            ? contentMaxWidth + _sidebarGap + _sidebarWidth
            : contentMaxWidth;

        if (showSidebar) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: CustomScrollView(slivers: slivers)),
                    const SizedBox(width: _sidebarGap),
                    const SizedBox(
                      width: _sidebarWidth,
                      child: WebSponsorPanel(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final horizontalPadding = math.max(
          16.0,
          (constraints.maxWidth - contentMaxWidth) / 2,
        );

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                16,
              ),
              sliver: SliverMainAxisGroup(
                slivers: [
                  if (kIsWeb) ...[
                    const SliverToBoxAdapter(
                      child: WebSponsorPanel(compact: true),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                  ...slivers,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class WebSponsorPanel extends StatelessWidget {
  const WebSponsorPanel({super.key, this.compact = false});

  static const String _amazonPartnerTag = 'cosmoslty-21';

  static final Uri _amazonUri = _amazonSearchUri('World of Warcraft');

  static Uri _amazonSearchUri(String keywords) {
    return Uri.https('www.amazon.fr', '/s', {
      'k': keywords,
      'tag': _amazonPartnerTag,
    });
  }

  static final _carousels = [
    _SponsorCarouselData(
      title: 'Goodies WoW',
      picks: [
        _SponsorPick(
          title: 'Figurines',
          imageAsset: 'assets/images/expansions/vanilla.jpg',
          uri: _amazonSearchUri('World of Warcraft figurine'),
        ),
        _SponsorPick(
          title: 'Mugs',
          imageAsset: 'assets/images/expansions/tbc.jpg',
          uri: _amazonSearchUri('World of Warcraft mug'),
        ),
        _SponsorPick(
          title: 'Déco',
          imageAsset: 'assets/images/expansions/wrath.jpg',
          uri: _amazonSearchUri('World of Warcraft decoration'),
        ),
      ],
    ),
    _SponsorCarouselData(
      title: 'Livres Warcraft',
      picks: [
        _SponsorPick(
          title: 'Romans',
          imageAsset: 'assets/images/expansions/mop.jpg',
          uri: _amazonSearchUri('World of Warcraft roman'),
        ),
        _SponsorPick(
          title: 'Artbooks',
          imageAsset: 'assets/images/expansions/legion.jpg',
          uri: _amazonSearchUri('World of Warcraft artbook'),
        ),
        _SponsorPick(
          title: 'Lore',
          imageAsset: 'assets/images/expansions/dragonflight.jpg',
          uri: _amazonSearchUri('Warcraft chroniques'),
        ),
      ],
    ),
    _SponsorCarouselData(
      title: 'Setup gaming',
      picks: [
        _SponsorPick(
          title: 'Claviers',
          imageAsset: 'assets/images/icones/wallpaper_app.jpg',
          uri: _amazonSearchUri('clavier gaming PC'),
        ),
        _SponsorPick(
          title: 'Souris',
          imageAsset: 'assets/images/expansions/tww.jpg',
          uri: _amazonSearchUri('souris gaming PC'),
        ),
        _SponsorPick(
          title: 'Casques',
          imageAsset: 'assets/images/expansions/midnight.jpg',
          uri: _amazonSearchUri('casque gaming PC'),
        ),
      ],
    ),
  ];

  final bool compact;

  Future<void> _openAmazon() async {
    await launchUrl(_amazonUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openPick(_SponsorPick pick) async {
    await launchUrl(pick.uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.gold.withValues(alpha: 0.16),
              AppTheme.card,
              const Color(0xFF25112A),
            ],
          ),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.34)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppTheme.gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'SPONSORING COMMUN',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Amazon Partenaires',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'En attendant les accords avec nos sponsors spécifiques, cet espace relaie un sponsoring commun pour soutenir WoW100%.',
                style: TextStyle(color: AppTheme.mutedText, height: 1.4),
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 12),
              for (final carousel in _carousels)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SponsorCarousel(data: carousel, onPickTap: _openPick),
                ),
              const SizedBox(height: 1),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.18),
                  ),
                ),
                child: const Text(
                  'En tant que Partenaire Amazon, Cosmos LTY réalise un bénéfice sur les achats remplissant les conditions requises, sans frais supplémentaire pour vous.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'amazon.fr',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Liens partenaires temporaires',
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openAmazon,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 19),
                  label: const Text('Voir la sélection Amazon'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SponsorCarouselData {
  const _SponsorCarouselData({required this.title, required this.picks});

  final String title;
  final List<_SponsorPick> picks;
}

class _SponsorPick {
  const _SponsorPick({
    required this.title,
    required this.imageAsset,
    required this.uri,
  });

  final String title;
  final String imageAsset;
  final Uri uri;
}

class _SponsorCarousel extends StatelessWidget {
  const _SponsorCarousel({required this.data, required this.onPickTap});

  final _SponsorCarouselData data;
  final ValueChanged<_SponsorPick> onPickTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: data.picks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final pick = data.picks[index];

              return _SponsorPhotoTile(
                pick: pick,
                onTap: () => onPickTap(pick),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SponsorPhotoTile extends StatelessWidget {
  const _SponsorPhotoTile({required this.pick, required this.onTap});

  final _SponsorPick pick;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 128,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
            image: DecorationImage(
              image: AssetImage(pick.imageAsset),
              fit: BoxFit.cover,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 9,
                  right: 9,
                  bottom: 8,
                  child: Text(
                    pick.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.open_in_new_rounded,
                    color: AppTheme.gold,
                    size: 16,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 2,
                    color: AppTheme.gold.withValues(alpha: 0.72),
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
