import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wow100/core/config/app_config.dart';
import '../models/battle_net_auth_result.dart';
import '../models/wow_character.dart';
import '../models/wow_mount.dart';
import '../models/wow_pet.dart';
import '../models/wow_achievement.dart';

class BattleNetRepository {
  Future<BattleNetAuthResult> exchangeCodeForToken(String code) async {
    final uri = _apiUri('exchangeBattleNetCode', {
      'code': code,
      'redirectUri': AppConfig.battleNetRedirectUri,
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      _throwApiException(response);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return BattleNetAuthResult.fromJson(data);
  }

  Future<List<WowCharacter>> getCharacters(String token) async {
    final uri = _apiUri('getWowCharacters');

    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data.map((item) => WowCharacter.fromJson(item)).toList();
  }

  Future<List<WowMount>> getMounts(String token) async {
    final uri = _apiUri('getWowMounts');

    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final data = jsonDecode(response.body);
    final mounts = data['mounts'] as List;

    return mounts.map((entry) {
      return WowMount.fromJson({
        'id': entry['mount']['id'],
        'name': entry['mount']['name'],
      });
    }).toList();
  }

  Future<List<WowPet>> getPets(String token) async {
    final uri = _apiUri('getWowPets');

    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final data = jsonDecode(response.body);

    final pets = data['pets'] as List;

    return pets.map((entry) {
      return WowPet.fromJson({
        'id': entry['species']['id'],
        'name': entry['species']['name'],
      });
    }).toList();
  }

  Future<List<WowAchievement>> getAchievements(
    String token,
    String realmSlug,
    String characterName,
  ) async {
    final uri = _apiUri('getCharacterAchievements', {
      'realmSlug': realmSlug,
      'characterName': characterName,
    });

    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final data = jsonDecode(response.body);

    final achievements = data['achievements'] as List;

    return achievements.map((entry) {
      final achievement = entry['achievement'] as Map<String, dynamic>? ?? {};

      return WowAchievement.fromJson({
        'id': entry['id'] ?? achievement['id'],
        'name': achievement['name'],
      });
    }).toList();
  }

  Future<List<WowAchievement>> getAccountAchievements(String token) async {
    final uri = _apiUri('getWowAchievements');

    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final data = jsonDecode(response.body);
    final achievements = data['achievements'] as List? ?? [];

    return achievements.map((entry) {
      final achievement = entry['achievement'] as Map<String, dynamic>? ?? {};

      return WowAchievement.fromJson({
        'id': entry['id'] ?? achievement['id'],
        'name': entry['name'] ?? achievement['name'],
      });
    }).toList();
  }

  Uri _apiUri(String path, [Map<String, String>? queryParameters]) {
    final baseUrl = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;

    return Uri.parse(
      '$baseUrl/$path',
    ).replace(queryParameters: queryParameters);
  }

  Map<String, String> _authHeaders(String token) {
    return {'Authorization': 'Bearer $token'};
  }

  Never _throwApiException(http.Response response) {
    final message = _friendlyApiError(response);
    throw Exception(message);
  }

  String _friendlyApiError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final responseData = data is Map<String, dynamic> ? data['data'] : null;
      final error = responseData is Map<String, dynamic>
          ? responseData['error']
          : null;

      if (error == 'invalid_redirect_uri') {
        return 'Redirect URI non autorisée côté Cloudflare. '
            'Ajoute ${AppConfig.battleNetRedirectUri} dans '
            'BATTLENET_ALLOWED_REDIRECT_URIS, et aussi dans les redirect URLs '
            'Battle.net si nécessaire.';
      }
    } catch (_) {
      // Keep the raw body below if the server did not return JSON.
    }

    return response.body;
  }
}
