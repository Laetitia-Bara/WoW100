import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_textured_background.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/auth/presentation/pages/auth_callback_page.dart';
import 'features/legal/presentation/pages/legal_page.dart';

void main() {
  runApp(const WoW100App());
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
    if (!_handledDeepLinks.add(link)) {
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
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
}
