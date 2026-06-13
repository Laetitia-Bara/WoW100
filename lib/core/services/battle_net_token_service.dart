import 'package:shared_preferences/shared_preferences.dart';
import 'package:wow100/data/models/battle_net_auth_result.dart';

class BattleNetTokenService {
  static const _key = 'battle_net_token';
  static const _expiresAtKey = 'battle_net_token_expires_at';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<void> saveAuthResult(BattleNetAuthResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = DateTime.now()
        .add(Duration(seconds: result.expiresIn))
        .millisecondsSinceEpoch;

    await prefs.setString(_key, result.accessToken);
    await prefs.setInt(_expiresAtKey, expiresAt);
  }

  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getInt(_expiresAtKey);

    if (expiresAt != null &&
        DateTime.now().millisecondsSinceEpoch >= expiresAt) {
      await clearToken();
      return null;
    }

    return prefs.getString(_key);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_expiresAtKey);
  }
}
