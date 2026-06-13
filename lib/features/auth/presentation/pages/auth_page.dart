import 'package:flutter/material.dart';

import '../../../../core/services/battle_net_auth_service.dart';
import '../../../../core/services/battle_net_session_service.dart';
import '../../../../core/theme/app_theme.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  Future<void> _openBattleNetLogin() async {
    await BattleNetSessionService().clearSession();

    final service = BattleNetAuthService();
    await service.openAuthorization(forceLogin: true);
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
                  'Cette première version ouvre simplement la page OAuth Battle.net pour vérifier notre Client ID, Redirect URL et scope.',
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
