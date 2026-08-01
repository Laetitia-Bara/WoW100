import 'package:flutter/material.dart';

import '../../../../core/services/battle_net_session_service.dart';
import '../../../../core/services/firebase_account_service.dart';
import '../../../../core/services/selected_character_service.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import 'auth_page.dart';
import 'character_switch_page.dart';

class SessionGatePage extends StatelessWidget {
  const SessionGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAccountService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return const AuthPage();
        }

        return const _AuthenticatedLandingPage();
      },
    );
  }
}

class _AuthenticatedLandingPage extends StatefulWidget {
  const _AuthenticatedLandingPage();

  @override
  State<_AuthenticatedLandingPage> createState() =>
      _AuthenticatedLandingPageState();
}

class _AuthenticatedLandingPageState extends State<_AuthenticatedLandingPage> {
  late final Future<_LandingState> _landingState = _loadLandingState();

  Future<_LandingState> _loadLandingState() async {
    final hasBattleNetSession = await BattleNetSessionService()
        .hasValidSession();
    if (!hasBattleNetSession) {
      return _LandingState.dashboard;
    }

    final selectedCharacter = await SelectedCharacterService().loadCharacter();
    return selectedCharacter == null
        ? _LandingState.characterSelection
        : _LandingState.dashboard;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LandingState>(
      future: _landingState,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return switch (snapshot.data!) {
          _LandingState.dashboard => const DashboardPage(),
          _LandingState.characterSelection => const CharacterSwitchPage(),
        };
      },
    );
  }
}

enum _LandingState { dashboard, characterSelection }
