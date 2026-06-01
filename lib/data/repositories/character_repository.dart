import '../models/wow_character.dart';
import '../sources/mock_character_source.dart';

abstract class CharacterRepository {
  Future<WowCharacter?> getMainCharacter();
}

class MockCharacterRepository implements CharacterRepository {
  final MockCharacterSource _source = MockCharacterSource();

  @override
  Future<WowCharacter?> getMainCharacter() {
    return _source.loadCharacter();
  }
}
