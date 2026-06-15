import 'package:flutter/foundation.dart';

import 'battle_net_auth_service.dart';
import 'battle_net_token_service.dart';
import 'selected_character_service.dart';

class BattleNetSessionService {
  BattleNetSessionService({
    BattleNetTokenService? tokenService,
    SelectedCharacterService? selectedCharacterService,
    BattleNetAuthService? authService,
  }) : _tokenService = tokenService ?? BattleNetTokenService(),
       _selectedCharacterService =
           selectedCharacterService ?? SelectedCharacterService(),
       _authService = authService ?? BattleNetAuthService();

  final BattleNetTokenService _tokenService;
  final SelectedCharacterService _selectedCharacterService;
  final BattleNetAuthService _authService;

  Future<bool> hasValidSession() async {
    final token = await _tokenService.loadToken();

    if (token == null) {
      await _selectedCharacterService.clearCharacter();
      return false;
    }

    return true;
  }

  Future<void> clearSession() async {
    await _tokenService.clearToken();
    await _selectedCharacterService.clearCharacter();
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
