import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/premium_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../legal/presentation/pages/legal_page.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  final PremiumService _premiumService = PremiumService();

  late Future<PremiumPurchaseState> _stateFuture = _premiumService.loadState();
  CustomerInfo? _customerInfoOverride;
  bool _isBusy = false;
  String? _message;

  Future<void> _reload() async {
    setState(() {
      _customerInfoOverride = null;
      _message = null;
      _stateFuture = _premiumService.loadState();
    });
  }

  Future<void> _purchase(Package package) async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final customerInfo = await _premiumService.purchase(package);
      if (!mounted) return;

      setState(() {
        _customerInfoOverride = customerInfo;
        _message = PremiumService.isPremium(customerInfo)
            ? 'Premium est actif. Les pubs et sponsors vont disparaitre.'
            : 'Achat termine, synchronisation Premium en cours.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _message = PremiumService.friendlyPurchaseError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _restore() async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final customerInfo = await _premiumService.restorePurchases();
      if (!mounted) return;

      setState(() {
        _customerInfoOverride = customerInfo;
        _message = PremiumService.isPremium(customerInfo)
            ? 'Achat restaure. Premium est actif.'
            : 'Aucun abonnement Premium actif trouve.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _message = PremiumService.friendlyPurchaseError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _openManagementUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openLegalPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LegalPage()));
  }

  void _openPrivacyPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LegalPage.privacy()));
  }

  Future<void> _openAppleEula() {
    return launchUrl(
      LegalPage.appleStandardEulaUri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: SafeArea(
        child: FutureBuilder<PremiumPurchaseState>(
          future: _stateFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final state = snapshot.data;
            if (snapshot.hasError || state == null) {
              return _PremiumErrorState(onRetry: _reload);
            }

            final customerInfo = _customerInfoOverride ?? state.customerInfo;
            final isPremium =
                customerInfo != null && PremiumService.isPremium(customerInfo);
            final managementUrl = customerInfo?.managementURL;

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 760
                    ? 680.0
                    : double.infinity;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PremiumHero(isPremium: isPremium),
                          const SizedBox(height: 18),
                          if (!state.isConfigured)
                            _PremiumUnavailablePanel(message: state.message)
                          else if (isPremium)
                            _PremiumActivePanel(
                              managementUrl: managementUrl,
                              onManage: managementUrl == null
                                  ? null
                                  : () => _openManagementUrl(managementUrl),
                              onRestore: _isBusy ? null : _restore,
                            )
                          else
                            _PremiumPackagesPanel(
                              packages: state.packages,
                              isBusy: _isBusy,
                              onPurchase: _purchase,
                              onRestore: _restore,
                            ),
                          if (!isPremium) ...[
                            const SizedBox(height: 14),
                            _SubscriptionDisclosure(
                              packages: state.packages,
                              onOpenLegal: _openLegalPage,
                              onOpenPrivacy: _openPrivacyPage,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _openAppleEula,
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text('EULA Apple'),
                              ),
                            ),
                          ],
                          if (_isBusy) ...[
                            const SizedBox(height: 18),
                            const Center(child: CircularProgressIndicator()),
                          ],
                          if (_message != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _message!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          const _PremiumFinePrint(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class PremiumAccountCard extends StatelessWidget {
  const PremiumAccountCard({
    super.key,
    required this.isPremium,
    required this.onTap,
  });

  final bool isPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isPremium ? const Color(0xFF34D399) : AppTheme.gold;

    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.38)),
          ),
          child: Row(
            children: [
              Icon(
                isPremium ? Icons.verified_rounded : Icons.block_flipped,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'Premium actif' : 'Devenir Premium',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isPremium
                          ? 'Ton experience reste sans pub ni sponsor.'
                          : 'Supprime les pubs et les sponsors de WoW100%.',
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/icones/wallpaper_app.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.22),
                    AppTheme.background.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppTheme.gold.withValues(alpha: 0.42),
                    ),
                  ),
                  child: Text(
                    isPremium ? 'PREMIUM ACTIF' : 'STOP PUB',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                const Text(
                  'WoW100% Premium',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Une app plus calme, sans bannieres publicitaires ni blocs sponsorises.',
                  style: TextStyle(
                    color: AppTheme.text,
                    height: 1.35,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPackagesPanel extends StatelessWidget {
  const _PremiumPackagesPanel({
    required this.packages,
    required this.isBusy,
    required this.onPurchase,
    required this.onRestore,
  });

  final List<Package> packages;
  final bool isBusy;
  final ValueChanged<Package> onPurchase;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) {
      return _EmptyOfferingPanel(onRestore: isBusy ? null : onRestore);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final package in packages)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PackageTile(
              package: package,
              isBusy: isBusy,
              onPurchase: () => onPurchase(package),
            ),
          ),
        OutlinedButton.icon(
          onPressed: isBusy ? null : onRestore,
          icon: const Icon(Icons.restore_rounded),
          label: const Text('Restaurer mon achat'),
        ),
      ],
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.isBusy,
    required this.onPurchase,
  });

  final Package package;
  final bool isBusy;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final period = _periodLabel(
      product.subscriptionPeriod,
      package.packageType,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _packageTitle(package),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    period,
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: isBusy ? null : onPurchase,
              child: Text(product.priceString),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumActivePanel extends StatelessWidget {
  const _PremiumActivePanel({
    required this.managementUrl,
    required this.onManage,
    required this.onRestore,
  });

  final String? managementUrl;
  final VoidCallback? onManage;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF34D399)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Premium est actif',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Merci pour ton soutien. Les pubs mobiles et sponsors web sont masques sur ton compte.',
              style: TextStyle(color: AppTheme.mutedText, height: 1.4),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (managementUrl != null)
                  FilledButton.icon(
                    onPressed: onManage,
                    icon: const Icon(Icons.settings_rounded),
                    label: const Text('Gerer'),
                  ),
                OutlinedButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Restaurer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumUnavailablePanel extends StatelessWidget {
  const _PremiumUnavailablePanel({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final displayMessage =
        message ??
        'Premium sera disponible des que les abonnements seront ouverts sur cette plateforme.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_clock_rounded, color: AppTheme.gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                displayMessage,
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOfferingPanel extends StatelessWidget {
  const _EmptyOfferingPanel({required this.onRestore});

  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Aucune offre Premium disponible pour le moment.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu peux restaurer un achat existant si tu as deja Premium sur une autre plateforme.',
              style: TextStyle(color: AppTheme.mutedText, height: 1.4),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRestore,
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Restaurer mon achat'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionDisclosure extends StatelessWidget {
  const _SubscriptionDisclosure({
    required this.packages,
    required this.onOpenLegal,
    required this.onOpenPrivacy,
  });

  final List<Package> packages;
  final VoidCallback onOpenLegal;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final monthlyPackage = _monthlyPackage();
    final price = monthlyPackage?.storeProduct.priceString.trim();
    final hasPrice = price != null && price.isNotEmpty;
    final renewalText = hasPrice
        ? 'Après l’essai, $price est facturé chaque mois par le Store, sauf annulation avant la fin de l’essai.'
        : 'Après l’essai, le prix mensuel affiché par le Store est facturé chaque mois, sauf annulation avant la fin de l’essai.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.gold),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Conditions de l’abonnement',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _DisclosureLine(
              text:
                  'WoW100% Premium est un abonnement mensuel à reconduction automatique.',
            ),
            const _DisclosureLine(
              text:
                  'La première semaine est offerte pour le premier abonnement des nouveaux abonnés éligibles.',
            ),
            _DisclosureLine(text: renewalText),
            const _DisclosureLine(
              text:
                  'Tu peux annuler à tout moment depuis les réglages d’abonnement de ton appareil. Pour éviter une facturation après un essai, annule au moins 24 h avant sa fin.',
            ),
            const _DisclosureLine(
              text:
                  'Après annulation, l’accès Premium reste disponible jusqu’à la fin de la période déjà payée, selon les règles du Store.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                TextButton.icon(
                  onPressed: onOpenLegal,
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('Informations légales'),
                ),
                TextButton.icon(
                  onPressed: onOpenPrivacy,
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Confidentialité'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Package? _monthlyPackage() {
    for (final package in packages) {
      if (package.packageType == PackageType.monthly) {
        return package;
      }
    }

    return packages.isEmpty ? null : packages.first;
  }
}

class _DisclosureLine extends StatelessWidget {
  const _DisclosureLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 8, right: 9),
            decoration: const BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.mutedText,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumFinePrint extends StatelessWidget {
  const _PremiumFinePrint();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Abonnement gere par la plateforme de paiement utilisee. Les droits Premium sont synchronises avec ton compte WoW100%.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppTheme.mutedText, fontSize: 12, height: 1.35),
    );
  }
}

class _PremiumErrorState extends StatelessWidget {
  const _PremiumErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.gold, size: 34),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger Premium pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

String _packageTitle(Package package) {
  final title = package.storeProduct.title.trim();
  if (title.isNotEmpty) return title;

  return switch (package.packageType) {
    PackageType.annual => 'Premium annuel',
    PackageType.sixMonth => 'Premium 6 mois',
    PackageType.threeMonth => 'Premium 3 mois',
    PackageType.twoMonth => 'Premium 2 mois',
    PackageType.monthly => 'Premium mensuel',
    PackageType.weekly => 'Premium hebdo',
    PackageType.lifetime => 'Premium a vie',
    _ => 'Premium',
  };
}

String _periodLabel(String? period, PackageType packageType) {
  return switch (period) {
    'P1W' => 'Renouvellement hebdomadaire',
    'P1M' => 'Renouvellement mensuel',
    'P2M' => 'Renouvellement tous les 2 mois',
    'P3M' => 'Renouvellement trimestriel',
    'P6M' => 'Renouvellement semestriel',
    'P1Y' => 'Renouvellement annuel',
    _ => switch (packageType) {
      PackageType.annual => 'Renouvellement annuel',
      PackageType.monthly => 'Renouvellement mensuel',
      PackageType.weekly => 'Renouvellement hebdomadaire',
      PackageType.lifetime => 'Paiement unique',
      _ => 'Abonnement Premium',
    },
  };
}
