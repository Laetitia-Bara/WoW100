import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/wow_character.dart';

class SelectedCharacterService {
  static const _legacyKey = 'selected_character';
  static const _settingsCollection = 'settings';
  static const _mainCharacterDocument = 'mainCharacter';

  Future<void> saveCharacter(WowCharacter character) async {
    final user = _currentUser;
    if (user == null) {
      await _saveLegacyCharacter(character);
      return;
    }

    await _mainCharacterRef(user.uid).set({
      ..._characterToFirestore(character),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _clearLegacyCharacter();
  }

  Future<WowCharacter?> loadCharacter() async {
    final user = _currentUser;
    if (user == null) {
      return _loadLegacyCharacter();
    }

    try {
      final snapshot = await _mainCharacterRef(user.uid).get();
      if (snapshot.exists) {
        return WowCharacter.fromJson(snapshot.data() ?? {});
      }

      final legacyCharacter = await _loadLegacyCharacter();
      if (legacyCharacter != null) {
        await saveCharacter(legacyCharacter);
      }

      return legacyCharacter;
    } on FirebaseException {
      return _loadLegacyCharacter();
    }
  }

  Future<void> clearCharacter() async {
    final user = _currentUser;
    if (user != null) {
      await _mainCharacterRef(user.uid).delete();
    }

    await _clearLegacyCharacter();
  }

  User? get _currentUser {
    if (Firebase.apps.isEmpty) {
      return null;
    }

    return FirebaseAuth.instance.currentUser;
  }

  DocumentReference<Map<String, dynamic>> _mainCharacterRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(_settingsCollection)
        .doc(_mainCharacterDocument);
  }

  Map<String, Object?> _characterToFirestore(WowCharacter character) {
    return {
      'name': character.name,
      'level': character.level,
      'realm': character.realm,
      'race': character.race,
      'characterClass': character.characterClass,
      'faction': character.faction,
      'realmSlug': character.realmSlug,
      'achievementPoints': character.achievementPoints,
      'portraitUrl': character.portraitUrl,
    };
  }

  Future<void> _saveLegacyCharacter(WowCharacter character) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _legacyKey,
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
        'portraitUrl': character.portraitUrl,
      }),
    );
  }

  Future<WowCharacter?> _loadLegacyCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_legacyKey);

    if (json == null) {
      return null;
    }

    return WowCharacter.fromJson(jsonDecode(json));
  }

  Future<void> _clearLegacyCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKey);
  }
}
