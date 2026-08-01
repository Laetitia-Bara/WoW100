import 'package:flutter/foundation.dart';

import 'battle_net_auth_service.dart';
import 'battle_net_token_service.dart';

class BattleNetSessionService {
  BattleNetSessionService({
    BattleNetTokenService? tokenService,
    BattleNetAuthService? authService,
  }) : _tokenService = tokenService ?? BattleNetTokenService(),
       _authService = authService ?? BattleNetAuthService();

  final BattleNetTokenService _tokenService;
  final BattleNetAuthService _authService;

  Future<bool> hasValidSession() async {
    final token = await _tokenService.loadToken();
    return token != null;
  }

  Future<void> clearSession() async {
    await _tokenService.clearToken();
  }

  Future<bool> clearSessionAndOpenBattleNetLogout() async {
    await clearSession();

    if (kIsWeb) {
      return false;
    }

    try {
      return await _authService.openLogout();
    } catch (_) {
      return false;
    }
  }
}
