import '../models/wow_character.dart';

class MockCharacterSource {
  Future<WowCharacter> loadCharacter() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const WowCharacter(
      name: 'Orcante',
      realm: 'Khaz Modan',
      faction: 'Horde',
      level: 80,
      characterClass: 'Démoniste',
      race: 'Elfe de sang',
      realmSlug: '',
    );
  }
}
