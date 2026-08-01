import 'package:flutter/material.dart';

import '../../../../core/services/battle_net_auth_service.dart';
import '../../../../core/services/battle_net_session_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'auth_callback_page.dart';

class BattleNetAuthPage extends StatefulWidget {
  const BattleNetAuthPage({super.key});

  @override
  State<BattleNetAuthPage> createState() => _BattleNetAuthPageState();
}

class _BattleNetAuthPageState extends State<BattleNetAuthPage> {
  Future<void> _openBattleNetLogin() async {
    await BattleNetSessionService().clearSession();

    final service = BattleNetAuthService();
    final callbackUri = await service.openAuthorization(forceLogin: true);

    if (callbackUri == null || !mounted) {
      return;
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AuthCallbackPage(
          code: callbackUri.queryParameters['code'],
          error: callbackUri.queryParameters['error'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion Battle.net')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Connecter ton compte World of Warcraft',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cette connexion sert uniquement a recuperer tes personnages et ta progression Battle.net.',
                  style: TextStyle(color: AppTheme.mutedText, height: 1.4),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _openBattleNetLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('Se connecter avec Battle.net'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
