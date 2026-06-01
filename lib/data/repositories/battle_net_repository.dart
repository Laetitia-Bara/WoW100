import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/wow_character.dart';

class BattleNetRepository {
  static const _functionsBaseUrl =
      'http://127.0.0.1:5001/wow100-106c3/us-central1';

  Future<String> exchangeCodeForToken(String code) async {
    final uri = Uri.parse(
      '$_functionsBaseUrl/exchangeBattleNetCode?code=$code',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final data = jsonDecode(response.body);
    return data['access_token'];
  }

  Future<List<WowCharacter>> getCharacters(String token) async {
    final uri = Uri.parse('$_functionsBaseUrl/getWowCharacters?token=$token');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data.map((item) => WowCharacter.fromJson(item)).toList();
  }
}
