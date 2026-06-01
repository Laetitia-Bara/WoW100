class WowCharacter {
  final String name;
  final String realm;
  final String region;
  final int level;
  final String characterClass;
  final String race;
  final String realmSlug;
  final int classId;
  final int raceId;
  final String? avatarUrl;

  const WowCharacter({
    required this.name,
    required this.realm,
    required this.region,
    required this.level,
    required this.characterClass,
    required this.race,
    required this.realmSlug,
    required this.classId,
    required this.raceId,
    this.avatarUrl,
  });
}
