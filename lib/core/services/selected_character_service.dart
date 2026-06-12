import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/wow_character.dart';

class SelectedCharacterService {
  static const _key = 'selected_character';

  Future<void> saveCharacter(WowCharacter character) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _key,
      jsonEncode({
        'name': character.name,
        'level': character.level,
        'realm': character.realm,
        'race': character.race,
        'characterClass': character.characterClass,
        'faction': character.faction,
        'realmSlug': character.realmSlug,
        'professions': character.professions,
        'achievementPoints': character.achievementPoints,
      }),
    );
  }

  Future<WowCharacter?> loadCharacter() async {
    final prefs = await SharedPreferences.getInstance();

    final json = prefs.getString(_key);

    if (json == null) {
      return null;
    }

    return WowCharacter.fromJson(jsonDecode(json));
  }

  Future<void> clearCharacter() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }
}
