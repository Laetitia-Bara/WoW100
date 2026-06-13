import 'battle_net_token_service.dart';
import 'selected_character_service.dart';

class BattleNetSessionService {
  BattleNetSessionService({
    BattleNetTokenService? tokenService,
    SelectedCharacterService? selectedCharacterService,
  }) : _tokenService = tokenService ?? BattleNetTokenService(),
       _selectedCharacterService =
           selectedCharacterService ?? SelectedCharacterService();

  final BattleNetTokenService _tokenService;
  final SelectedCharacterService _selectedCharacterService;

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
}
