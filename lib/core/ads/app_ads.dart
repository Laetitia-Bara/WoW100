import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../theme/app_theme.dart';

class AppAds {
  const AppAds._();

  static const _disabled = bool.fromEnvironment('DISABLE_ADS');
  static Future<void>? _initialization;

  static const androidAppId = 'ca-app-pub-5057499390168934~3930177735';
  static const iosAppId = 'ca-app-pub-5057499390168934~4880059647';
  static const _androidProductionBannerAdUnitId =
      'ca-app-pub-5057499390168934/4065909101';
  static const _androidProductionNativeAdUnitId =
      'ca-app-pub-5057499390168934/8663629665';
  static const _iosProductionBannerAdUnitId =
      'ca-app-pub-5057499390168934/7175050497';
  static const _iosProductionNativeAdUnitId =
      'ca-app-pub-5057499390168934/2062324614';
  static const _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  static String get bannerAdUnitId {
    if (!kReleaseMode) {
      return _testBannerAdUnitId;
    }

    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosProductionBannerAdUnitId
        : _androidProductionBannerAdUnitId;
  }

  static String get nativeAdUnitId {
    if (!kReleaseMode) {
      return _testNativeAdUnitId;
    }

    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosProductionNativeAdUnitId
        : _androidProductionNativeAdUnitId;
  }

  static bool get isSupported {
    return !_disabled &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  static Future<void> initialize() {
    if (!isSupported) {
      return Future<void>.value();
    }

    return _initialization ??= _initialize();
  }

  static Future<void> _initialize() async {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.t,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
      ),
    );
    await MobileAds.instance.initialize();
  }
}

class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _ad;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!AppAds.isSupported) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    try {
      await AppAds.initialize().timeout(const Duration(seconds: 8));
    } on Object {
      return;
    }

    if (!mounted) {
      return;
    }

    _ad = BannerAd(
      adUnitId: AppAds.bannerAdUnitId,
      request: const AdRequest(nonPersonalizedAds: true),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;

    if (!_isLoaded || ad == null) {
      return const SizedBox.shrink();
    }

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final verticalPadding = 12.0;
    final adHeight = ad.size.height.toDouble();

    return SizedBox(
      width: double.infinity,
      height: adHeight + verticalPadding + bottomInset,
      child: ColoredBox(
        color: AppTheme.background.withAlpha(242),
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 6, 0, 6 + bottomInset),
          child: Center(
            child: SizedBox(
              width: ad.size.width.toDouble(),
              height: adHeight,
              child: AdWidget(ad: ad),
            ),
          ),
        ),
      ),
    );
  }
}

class AppNativeAd extends StatefulWidget {
  const AppNativeAd({super.key});

  @override
  State<AppNativeAd> createState() => _AppNativeAdState();
}

class _AppNativeAdState extends State<AppNativeAd> {
  NativeAd? _ad;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!AppAds.isSupported) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    try {
      await AppAds.initialize().timeout(const Duration(seconds: 8));
    } on Object {
      return;
    }

    if (!mounted) {
      return;
    }

    _ad = NativeAd(
      adUnitId: AppAds.nativeAdUnitId,
      request: const AdRequest(nonPersonalizedAds: true),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: AppTheme.card,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: AppTheme.background,
          backgroundColor: AppTheme.gold,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppTheme.text,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 16,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppTheme.mutedText,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppTheme.mutedText,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;

    if (!_isLoaded || ad == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SizedBox(
        height: 320,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
