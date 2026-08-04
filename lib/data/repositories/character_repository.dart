import '../models/wow_character.dart';

abstract class CharacterRepository {
  Future<WowCharacter?> getMainCharacter();
}
