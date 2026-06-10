import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/auth/presentation/pages/auth_callback_page.dart';

void main() {
  runApp(const WoW100App());
}

class WoW100App extends StatelessWidget {
  const WoW100App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WoW100%',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
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

    if (_isCallbackUri(Uri.base)) {
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

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const DashboardPage(),
    );
  }

  bool _isCallbackRoute(String routeName) {
    final uri = Uri.tryParse(routeName);
    return uri != null && _isCallbackUri(uri);
  }

  bool _isCallbackUri(Uri uri) {
    return uri.path == '/callback' ||
        (uri.scheme == 'wow100' && uri.host == 'callback');
  }
}