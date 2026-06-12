class WowCharacter {
  final String name;
  final int level;
  final String realm;
  final String race;
  final String characterClass;
  final String faction;
  final String realmSlug;
  final List<String> professions;

  const WowCharacter({
    required this.name,
    required this.level,
    required this.realm,
    required this.race,
    required this.characterClass,
    required this.faction,
    required this.realmSlug,
    this.professions = const [],
  });

  factory WowCharacter.fromJson(Map<String, dynamic> json) {
    return WowCharacter(
      name: json['name'] ?? '',
      level: json['level'] ?? 0,
      realm: json['realm'] ?? '',
      race: json['race'] ?? '',
      characterClass: json['characterClass'] ?? '',
      faction: json['faction'] ?? '',
      realmSlug: json['realmSlug'] ?? '',
      professions:
          (json['professions'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }
}
