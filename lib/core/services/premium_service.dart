import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/app_config.dart';
import 'firebase_account_service.dart';

class PremiumService {
  PremiumService({FirebaseAccountService? accountService})
    : _accountService = accountService ?? FirebaseAccountService();

  final FirebaseAccountService _accountService;

  static Future<void>? _configurationFuture;
  static String? _configuredUserId;

  static String get entitlementId => AppConfig.revenueCatPremiumEntitlementId;

  bool get isAvailable => _apiKeyForPlatform.isNotEmpty;

  bool get canOpenPurchases => isAvailable;

  Future<PremiumPurchaseState> loadState() async {
    if (!canOpenPurchases) {
      return const PremiumPurchaseState.unavailable();
    }

    await _configureForCurrentUser();
    final results = await Future.wait([
      Purchases.getCustomerInfo(),
      Purchases.getOfferings(),
    ]);
    final customerInfo = results[0] as CustomerInfo;
    final offerings = results[1] as Offerings;

    return PremiumPurchaseState.available(
      customerInfo: customerInfo,
      offering: _selectOffering(offerings),
    );
  }

  Future<CustomerInfo> purchase(Package package) async {
    await _configureForCurrentUser();
    final userEmail = _accountService.currentUser?.email?.trim();
    final result = await Purchases.purchase(
      PurchaseParams.package(
        package,
        customerEmail: userEmail?.isEmpty == true ? null : userEmail,
      ),
    );
    return result.customerInfo;
  }

  Future<CustomerInfo> restorePurchases() async {
    await _configureForCurrentUser();
    return Purchases.restorePurchases();
  }

  Future<CustomerInfo> customerInfo() async {
    await _configureForCurrentUser();
    return Purchases.getCustomerInfo();
  }

  Future<void> _configureForCurrentUser() {
    final user = _accountService.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No Firebase account is signed in.',
      );
    }

    final apiKey = _apiKeyForPlatform;
    if (apiKey.isEmpty) {
      throw StateError('RevenueCat is not configured for this platform.');
    }

    if (_configurationFuture != null && _configuredUserId == user.uid) {
      return _configurationFuture!;
    }

    _configuredUserId = user.uid;
    _configurationFuture = _configure(apiKey: apiKey, user: user).catchError((
      Object error,
    ) {
      if (_configuredUserId == user.uid) {
        _configuredUserId = null;
        _configurationFuture = null;
      }

      throw error;
    });
    return _configurationFuture!;
  }

  Future<void> _configure({required String apiKey, required User user}) async {
    final isConfigured = await Purchases.isConfigured;

    if (isConfigured) {
      await Purchases.logIn(user.uid);
    } else {
      final configuration = PurchasesConfiguration(apiKey)
        ..appUserID = user.uid
        ..preferredUILocaleOverride = 'fr-FR';
      await Purchases.configure(configuration);
    }

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      await Purchases.setEmail(email);
    }

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      await Purchases.setDisplayName(displayName);
    }
  }

  Offering? _selectOffering(Offerings offerings) {
    final configuredOfferingId = AppConfig.revenueCatOfferingId.trim();
    if (configuredOfferingId.isNotEmpty) {
      return offerings.getOffering(configuredOfferingId) ?? offerings.current;
    }

    return offerings.current;
  }

  String get _apiKeyForPlatform {
    if (kIsWeb) {
      return AppConfig.revenueCatWebApiKey.trim();
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AppConfig.revenueCatAndroidApiKey.trim(),
      TargetPlatform.iOS => AppConfig.revenueCatIosApiKey.trim(),
      _ => '',
    };
  }

  static bool isPremium(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.containsKey(entitlementId);
  }

  static String friendlyPurchaseError(Object error) {
    if (error is PlatformException) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return 'Achat annule.';
      }

      if (code == PurchasesErrorCode.purchaseNotAllowedError) {
        return 'Achat indisponible sur cet appareil.';
      }

      return error.message ?? 'Achat impossible pour le moment.';
    }

    return 'Achat impossible pour le moment.';
  }
}

class PremiumPurchaseState {
  const PremiumPurchaseState._({
    required this.isConfigured,
    this.customerInfo,
    this.offering,
  });

  const PremiumPurchaseState.unavailable() : this._(isConfigured: false);

  const PremiumPurchaseState.available({
    required CustomerInfo customerInfo,
    required Offering? offering,
  }) : this._(
         isConfigured: true,
         customerInfo: customerInfo,
         offering: offering,
       );

  final bool isConfigured;
  final CustomerInfo? customerInfo;
  final Offering? offering;

  bool get isPremium {
    final info = customerInfo;
    return info != null && PremiumService.isPremium(info);
  }

  List<Package> get packages => offering?.availablePackages ?? const [];
}
