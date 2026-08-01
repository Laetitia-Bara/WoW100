import 'package:flutter/material.dart';

import '../../../../core/services/battle_net_auth_service.dart';
import '../../../../core/services/battle_net_session_service.dart';
import '../../../../core/services/firebase_account_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'auth_page.dart';
import 'auth_callback_page.dart';

class BattleNetAuthPage extends StatefulWidget {
  const BattleNetAuthPage({super.key});

  @override
  State<BattleNetAuthPage> createState() => _BattleNetAuthPageState();
}

class _BattleNetAuthPageState extends State<BattleNetAuthPage> {
  final FirebaseAccountService _accountService = FirebaseAccountService();

  Future<void> _openBattleNetLogin() async {
    if (_accountService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connecte-toi a ton compte WoW100% avant Battle.net.'),
        ),
      );
      return;
    }

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
      body: StreamBuilder(
        stream: _accountService.authStateChanges,
        builder: (context, snapshot) {
          final hasAppSession =
              snapshot.data != null ||
              (snapshot.connectionState == ConnectionState.waiting &&
                  _accountService.currentUser != null);

          return Padding(
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cette connexion sert uniquement a recuperer tes personnages et ta progression Battle.net.',
                      style: TextStyle(color: AppTheme.mutedText, height: 1.4),
                    ),
                    if (!hasAppSession) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Connecte-toi d abord a ton compte WoW100%.',
                        style: TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: hasAppSession ? _openBattleNetLogin : null,
                      icon: const Icon(Icons.login),
                      label: const Text('Se connecter avec Battle.net'),
                    ),
                    if (!hasAppSession) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthPage()),
                          );
                        },
                        icon: const Icon(Icons.account_circle_outlined),
                        label: const Text('Connexion WoW100%'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
