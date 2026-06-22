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

class WebSponsorPanel extends StatelessWidget {
  const WebSponsorPanel({super.key, this.compact = false});

  static final Uri _contactUri = Uri(
    scheme: 'mailto',
    path: 'contact@cosmos-lty.fr',
    queryParameters: {
      'subject': 'Partenariat sponsor WoW100%',
      'body': 'Bonjour,\n\nJe souhaite proposer un partenariat pour WoW100%.',
    },
  );

  final bool compact;

  Future<void> _openContact() async {
    await launchUrl(_contactUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final opportunities = [
      (Icons.groups_rounded, 'Guilde recrutant'),
      (Icons.videocam_rounded, 'Streamer WoW'),
      (Icons.auto_awesome_rounded, 'Créateur de contenu'),
      (Icons.sports_esports_rounded, 'Boutique gaming'),
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
                      Icons.handshake_outlined,
                      color: AppTheme.gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'PARTENAIRES',
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
                'Soutenez WoW100%',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Présentez votre projet à une communauté de collectionneurs et joueuses et joueurs de WoW.',
                style: TextStyle(color: AppTheme.mutedText, height: 1.4),
              ),
              const SizedBox(height: 16),
              if (compact)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final opportunity in opportunities)
                      _SponsorOpportunity(
                        icon: opportunity.$1,
                        label: opportunity.$2,
                      ),
                  ],
                )
              else
                for (final opportunity in opportunities)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SponsorOpportunity(
                      icon: opportunity.$1,
                      label: opportunity.$2,
                    ),
                  ),
              const SizedBox(height: 6),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.campaign_outlined, color: AppTheme.gold, size: 20),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Emplacement sponsor disponible',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openContact,
                  icon: const Icon(Icons.mail_outline_rounded, size: 19),
                  label: const Text('Proposer un partenariat'),
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

class _SponsorOpportunity extends StatelessWidget {
  const _SponsorOpportunity({required this.icon, required this.label});

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
