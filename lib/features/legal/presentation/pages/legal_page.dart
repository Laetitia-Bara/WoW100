import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, this.title = 'Informations légales'})
    : isPrivacyPolicy = false;

  const LegalPage.privacy({super.key})
    : title = 'Politique de confidentialité',
      isPrivacyPolicy = true;

  static const String owner = 'cosmos-lty';
  static const String contactEmail = 'contact@cosmos-lty.fr';

  final String title;
  final bool isPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    final sections = isPrivacyPolicy ? _privacySections : _legalSections;

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
                children: [
                  _LegalHero(isPrivacyPolicy: isPrivacyPolicy),
                  const SizedBox(height: 14),
                  for (final section in sections)
                    _LegalSection(
                      title: section.title,
                      children: section.paragraphs,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static const List<_LegalContentSection> _legalSections = [
    _LegalContentSection(
      title: 'Éditeur',
      paragraphs: [
        'WoW100% est édité par cosmos-lty.',
        'Contact : contact@cosmos-lty.fr',
      ],
    ),
    _LegalContentSection(
      title: 'Propriété intellectuelle',
      paragraphs: [
        'Le code, la structure de l’application, les choix d’organisation, les algorithmes, les traitements de données, les interfaces et les contenus originaux de WoW100% sont protégés.',
        'Toute reproduction, copie, extraction, redistribution, modification, publication ou utilisation non autorisée, totale ou partielle, est interdite.',
        'Merci de respecter le travail réalisé autour de ce projet.',
      ],
    ),
    _LegalContentSection(
      title: 'World of Warcraft',
      paragraphs: [
        'WoW100% est un projet indépendant et non officiel.',
        'World of Warcraft, Battle.net, Blizzard Entertainment et les éléments associés appartiennent à leurs propriétaires respectifs.',
        'L’application peut afficher ou référencer des données publiques liées au jeu afin d’aider au suivi de collection.',
      ],
    ),
    _LegalContentSection(
      title: 'Sources externes',
      paragraphs: [
        'Certaines informations de progression, d’objets, de hauts faits, de montures ou de mascottes peuvent provenir ou être croisées avec des sources externes comme Blizzard, Wowhead ou Mamytwink.',
        'Ces sources restent la propriété de leurs éditeurs respectifs. WoW100% les utilise comme références pour aider au classement et à la navigation.',
      ],
    ),
  ];

  static const List<_LegalContentSection> _privacySections = [
    _LegalContentSection(
      title: 'Responsable et contact',
      paragraphs: [
        'La présente politique de confidentialité concerne l’application WoW100%, éditée par cosmos-lty.',
        'Pour toute question liée à la confidentialité ou aux données personnelles, vous pouvez écrire à : contact@cosmos-lty.fr.',
      ],
    ),
    _LegalContentSection(
      title: 'Données utilisées par l’application',
      paragraphs: [
        'WoW100% utilise uniquement les données nécessaires au fonctionnement du companion de collection World of Warcraft.',
        'Lorsque vous connectez votre compte Battle.net, l’application peut traiter les informations liées à votre profil World of Warcraft : personnages, royaume, race, classe, faction, niveau, professions, points de hauts faits, hauts faits, montures et mascottes possédés.',
        'L’application peut également enregistrer localement le personnage sélectionné et les éléments cochés manuellement dans votre suivi de progression.',
      ],
    ),
    _LegalContentSection(
      title: 'Connexion Battle.net',
      paragraphs: [
        'La connexion Battle.net sert uniquement à récupérer les données nécessaires au suivi de collection.',
        'WoW100% ne demande jamais votre mot de passe Battle.net. L’authentification est effectuée via la page officielle Battle.net.',
        'Après connexion, un jeton d’accès Battle.net peut être conservé sur l’appareil afin de maintenir la session et d’actualiser les données de progression.',
      ],
    ),
    _LegalContentSection(
      title: 'Utilisation des données',
      paragraphs: [
        'Les données sont utilisées pour afficher votre progression, choisir un personnage principal, calculer les statistiques de collection et comparer les éléments possédés avec les listes de suivi de l’application.',
        'WoW100% n’utilise pas ces données pour vendre des profils, établir un profilage commercial personnalisé ou revendre des informations à des tiers.',
      ],
    ),
    _LegalContentSection(
      title: 'Stockage et conservation',
      paragraphs: [
        'Certaines données sont stockées localement sur votre appareil, notamment le jeton Battle.net, le personnage sélectionné et les éléments cochés manuellement.',
        'Ces données sont conservées tant que vous utilisez l’application ou jusqu’à leur suppression depuis l’application, par déconnexion, suppression des données de l’application ou désinstallation.',
        'Les fonctions serveur utilisées pour communiquer avec Battle.net traitent les requêtes nécessaires au fonctionnement du service. Elles ne sont pas destinées à créer une base de profils utilisateurs WoW100%.',
      ],
    ),
    _LegalContentSection(
      title: 'Partage et prestataires',
      paragraphs: [
        'Les données nécessaires à la connexion et à la récupération de progression peuvent être transmises aux services Battle.net et Blizzard Entertainment afin d’obtenir les informations demandées par l’utilisateur.',
        'L’application et son site peuvent s’appuyer sur des prestataires techniques d’hébergement ou d’exécution, notamment Cloudflare et Firebase/Google, pour fournir le service.',
      ],
    ),
    _LegalContentSection(
      title: 'Sécurité',
      paragraphs: [
        'Les échanges avec les services distants sont effectués au moyen de connexions sécurisées lorsque ces services sont appelés.',
        'Les données stockées localement restent liées à l’appareil et peuvent être supprimées par les mécanismes de l’application ou du système.',
      ],
    ),
    _LegalContentSection(
      title: 'Vos droits et suppression',
      paragraphs: [
        'Vous pouvez déconnecter votre compte Battle.net depuis l’application afin de supprimer le jeton de connexion et le personnage sélectionné de l’espace local de l’application.',
        'Vous pouvez également supprimer les données locales de WoW100% depuis les paramètres Android ou en désinstallant l’application.',
        'Pour toute demande d’accès, de rectification, d’opposition ou de suppression liée aux données personnelles, vous pouvez écrire à contact@cosmos-lty.fr.',
      ],
    ),
    _LegalContentSection(
      title: 'Mise à jour de la politique',
      paragraphs: [
        'Cette politique peut être mise à jour pour refléter les évolutions de l’application, des services utilisés ou des exigences légales et plateformes.',
        'Dernière mise à jour : 12 juin 2026.',
      ],
    ),
  ];
}

class _LegalContentSection {
  const _LegalContentSection({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;
}

class _LegalHero extends StatelessWidget {
  const _LegalHero({required this.isPrivacyPolicy});

  final bool isPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPrivacyPolicy ? 'Politique de confidentialité' : 'WoW100%',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              isPrivacyPolicy
                  ? 'Informations sur les données utilisées par WoW100% et la connexion Battle.net.'
                  : 'Companion de collection World of Warcraft créé et maintenu par cosmos-lty.',
              style: const TextStyle(color: AppTheme.mutedText),
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
