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

  static final Uri _amazonUri = Uri.https('www.amazon.fr', '/s', {
    'k': 'World of Warcraft',
    'tag': 'cosmoslty-21',
  });

  final bool compact;

  Future<void> _openAmazon() async {
    await launchUrl(_amazonUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final highlights = [
      (Icons.public_rounded, 'WoW100% + BoB'),
      (Icons.handshake_rounded, 'Sponsoring commun'),
      (Icons.hourglass_top_rounded, 'En attendant nos sponsors'),
    ];

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
                'En attendant les accords avec nos vrais sponsors, cet espace relaie un sponsoring commun pour soutenir WoW100% et BoB.',
                style: TextStyle(color: AppTheme.mutedText, height: 1.4),
              ),
              const SizedBox(height: 16),
              if (compact)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final highlight in highlights)
                      _SponsorHighlight(
                        icon: highlight.$1,
                        label: highlight.$2,
                      ),
                  ],
                )
              else
                for (final highlight in highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SponsorHighlight(
                      icon: highlight.$1,
                      label: highlight.$2,
                    ),
                  ),
              const SizedBox(height: 6),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 10),
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

class _SponsorHighlight extends StatelessWidget {
  const _SponsorHighlight({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.gold, size: 18),
          const SizedBox(width: 9),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
