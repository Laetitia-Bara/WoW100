import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, this.title = 'Informations légales'});

  static const String owner = 'cosmos-lty';
  static const String contactEmail = 'contact@cosmos-lty.fr';
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final contentWidth = isWide ? 900.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _LegalHero(),
                  SizedBox(height: 14),
                  _LegalSection(
                    title: 'Éditeur',
                    children: [
                      'WoW100% est édité par cosmos-lty.',
                      'Contact : contact@cosmos-lty.fr',
                    ],
                  ),
                  _LegalSection(
                    title: 'Propriété intellectuelle',
                    children: [
                      'Le code, la structure de l’application, les choix d’organisation, les algorithmes, les traitements de données, les interfaces et les contenus originaux de WoW100% sont protégés.',
                      'Toute reproduction, copie, extraction, redistribution, modification, publication ou réutilisation non autorisée, totale ou partielle, est interdite.',
                      'Merci de respecter le travail réalisé autour de ce projet. Il y a beaucoup d’heures, de tests et de soin derrière WoW100%, et ça compte.',
                    ],
                  ),
                  _LegalSection(
                    title: 'World of Warcraft',
                    children: [
                      'WoW100% est un projet indépendant et non officiel.',
                      'World of Warcraft, Battle.net, Blizzard Entertainment et les éléments associés appartiennent à leurs propriétaires respectifs.',
                      'L’application peut afficher ou référencer des données publiques liées au jeu afin d’aider au suivi de collection.',
                    ],
                  ),
                  _LegalSection(
                    title: 'Données et compte Battle.net',
                    children: [
                      'La connexion Battle.net sert à récupérer les informations nécessaires au suivi de progression, comme le personnage choisi et les montures possédées.',
                      'WoW100% ne demande pas ton mot de passe Battle.net. L’authentification passe par la page officielle Battle.net.',
                      'Les données utilisées dans l’application sont limitées au fonctionnement du companion de collection.',
                    ],
                  ),
                  _LegalSection(
                    title: 'RGPD et contact',
                    children: [
                      'Pour toute question liée aux données personnelles, à la confidentialité, à une demande d’accès, de rectification ou de suppression, tu peux écrire à contact@cosmos-lty.fr.',
                      'Les demandes seront traitées avec attention, dans un délai raisonnable.',
                    ],
                  ),
                  _LegalSection(
                    title: 'Sources externes',
                    children: [
                      'Certaines informations de progression, d’objets ou de montures peuvent provenir ou être croisées avec des sources externes comme Blizzard, Wowhead ou Mamytwink.',
                      'Ces sources restent la propriété de leurs éditeurs respectifs. WoW100% les utilise comme références pour aider au classement et à la navigation.',
                    ],
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

class _LegalHero extends StatelessWidget {
  const _LegalHero();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WoW100%',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Companion de collection World of Warcraft créé et maintenu par cosmos-lty.',
              style: TextStyle(color: AppTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.children});

  final String title;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(height: 10),
            for (final paragraph in children) ...[
              Text(paragraph),
              if (paragraph != children.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
