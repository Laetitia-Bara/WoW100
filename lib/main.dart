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
    final uri = Uri.base;
    final isCallback = uri.path == '/callback';

    return MaterialApp(
      title: 'WoW100%',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isCallback
          ? AuthCallbackPage(
              code: uri.queryParameters['code'],
              error: uri.queryParameters['error'],
            )
          : const DashboardPage(),
    );
  }
}
