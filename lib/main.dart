import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/ads/app_ads.dart';
import 'core/diagnostics/startup_logger.dart';
import 'core/theme/app_textured_background.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/auth/presentation/pages/auth_callback_page.dart';
import 'features/legal/presentation/pages/legal_page.dart';

void main() {
  runZonedGuarded(
    () async {
      StartupLogger.mark('app started');
      WidgetsFlutterBinding.ensureInitialized();
      StartupLogger.mark('Flutter initialized');
      _configureStartupErrorLogging();
      unawaited(StartupLogger.initializePersistence());
      StartupLogger.mark('runApp called');
      runApp(const WoW100App());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        StartupLogger.mark('first screen rendered');
        unawaited(_initializeAdsAfterFirstFrame());
      });
    },
    (error, stackTrace) {
      StartupLogger.recordError('uncaught startup error', error, stackTrace);
    },
  );
}

void _configureStartupErrorLogging() {
  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    StartupLogger.recordFlutterError(details);
    if (previousFlutterErrorHandler != null) {
      previousFlutterErrorHandler(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  final previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    StartupLogger.recordError('uncaught platform error', error, stackTrace);
    return previousPlatformErrorHandler?.call(error, stackTrace) ?? true;
  };
}

Future<void> _initializeAdsAfterFirstFrame() async {
  if (!AppAds.isSupported) {
    StartupLogger.mark('ads init skipped');
    return;
  }

  StartupLogger.mark('ads init started');
  try {
    await AppAds.initialize().timeout(const Duration(seconds: 8));
    StartupLogger.mark('ads init finished');
  } on TimeoutException catch (error, stackTrace) {
    StartupLogger.recordError('ads init timed out', error, stackTrace);
  } on Object catch (error, stackTrace) {
    StartupLogger.recordError('ads init failed', error, stackTrace);
  }
}

class WoW100App extends StatelessWidget {
  const WoW100App({super.key});

  @override
  Widget build(BuildContext context) {
    return const _WoW100AppShell();
  }
}

class _WoW100AppShell extends StatefulWidget {
  const _WoW100AppShell();

  @override
  State<_WoW100AppShell> createState() => _WoW100AppShellState();
}

class _WoW100AppShellState extends State<_WoW100AppShell> {
  static const _deepLinkChannel = MethodChannel(
    'fr.cosmoslty.wow100/deep_links',
  );

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final Set<String> _handledDeepLinks = {};

  @override
  void initState() {
    super.initState();
    _markInitialDeepLinksAsHandled();
    _deepLinkChannel.setMethodCallHandler(_handleDeepLinkMethodCall);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialDeepLink();
    });
  }

  Future<dynamic> _handleDeepLinkMethodCall(MethodCall call) async {
    if (call.method != 'onLink') {
      return null;
    }

    final link = call.arguments as String?;
    if (link != null) {
      _openDeepLink(link);
    }

    return null;
  }

  Future<void> _loadInitialDeepLink() async {
    try {
      final link = await _deepLinkChannel.invokeMethod<String>(
        'getInitialLink',
      );

      if (link != null) {
        _openDeepLink(link);
      }
    } on MissingPluginException {
      // Web and desktop builds do not provide this native channel.
    }
  }

  void _openDeepLink(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) {
      return;
    }

    if (!_markDeepLinkAsHandled(uri)) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    if (_isCallbackUri(uri)) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: link),
          builder: (_) => AuthCallbackPage(
            code: uri.queryParameters['code'],
            error: uri.queryParameters['error'],
          ),
        ),
        (_) => false,
      );
      return;
    }

    if (_isPrivacyUri(uri)) {
      navigator.push(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: link),
          builder: (_) => const LegalPage.privacy(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WoW100%',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: _navigatorKey,
      builder: (context, child) {
        return AppTexturedBackground(child: child ?? const SizedBox.shrink());
      },
      initialRoute: _initialRouteName(),
      onGenerateRoute: _buildRoute,
    );
  }

  String _initialRouteName() {
    final platformRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;

    if (_isCallbackRoute(platformRoute)) {
      return platformRoute;
    }

    if (_isPrivacyRoute(platformRoute)) {
      return platformRoute;
    }

    if (_isCallbackUri(Uri.base)) {
      return Uri.base.toString();
    }

    if (_isPrivacyUri(Uri.base)) {
      return Uri.base.toString();
    }

    return '/';
  }

  Route<void> _buildRoute(RouteSettings settings) {
    final routeName = settings.name ?? '/';
    final uri = Uri.tryParse(routeName);

    if (uri != null && _isCallbackUri(uri)) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AuthCallbackPage(
          code: uri.queryParameters['code'],
          error: uri.queryParameters['error'],
        ),
      );
    }

    if (uri != null && _isPrivacyUri(uri)) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const LegalPage.privacy(),
      );
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const DashboardPage(),
    );
  }

  bool _isCallbackRoute(String routeName) {
    final uri = Uri.tryParse(routeName);
    return uri != null && _isCallbackUri(uri);
  }

  bool _isPrivacyRoute(String routeName) {
    final uri = Uri.tryParse(routeName);
    return uri != null && _isPrivacyUri(uri);
  }

  bool _isCallbackUri(Uri uri) {
    return uri.path == '/callback' ||
        (uri.scheme == 'wow100' && uri.host == 'callback');
  }

  bool _isPrivacyUri(Uri uri) {
    return uri.path == '/privacy' || uri.path == '/legal';
  }

  void _markInitialDeepLinksAsHandled() {
    final platformRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;

    _markDeepLinkStringAsHandled(platformRoute);

    if (_isCallbackUri(Uri.base) || _isPrivacyUri(Uri.base)) {
      _markDeepLinkAsHandled(Uri.base);
    }
  }

  bool _markDeepLinkStringAsHandled(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) {
      return false;
    }

    return _markDeepLinkAsHandled(uri);
  }

  bool _markDeepLinkAsHandled(Uri uri) {
    if (!_isCallbackUri(uri) && !_isPrivacyUri(uri)) {
      return true;
    }

    return _handledDeepLinks.add(_deepLinkKey(uri));
  }

  String _deepLinkKey(Uri uri) {
    if (_isCallbackUri(uri)) {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        return 'callback-code:$code';
      }

      final error = uri.queryParameters['error'];
      if (error != null && error.isNotEmpty) {
        return 'callback-error:$error';
      }
    }

    if (_isPrivacyUri(uri)) {
      return 'privacy:${uri.path}';
    }

    return uri.toString();
  }
}
