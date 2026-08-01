class WowCharacter {
  final String name;
  final int level;
  final String realm;
  final String race;
  final String characterClass;
  final String faction;
  final String realmSlug;
  final List<String> professions;
  final int achievementPoints;
  final int? mythicKeystoneRating;
  final String? portraitUrl;

  const WowCharacter({
    required this.name,
    required this.level,
    required this.realm,
    required this.race,
    required this.characterClass,
    required this.faction,
    required this.realmSlug,
    this.professions = const [],
    this.achievementPoints = 0,
    this.mythicKeystoneRating,
    this.portraitUrl,
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
      professions: _professionsFromJson(json['professions']),
      achievementPoints: json['achievementPoints'] ?? 0,
      mythicKeystoneRating: _nullableIntFromJson(json['mythicKeystoneRating']),
      portraitUrl: json['portraitUrl'],
    );
  }

  static int? _nullableIntFromJson(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);

    return null;
  }

  static List<String> _professionsFromJson(Object? value) {
    if (value is! List) {
      return const [];
    }

    final professions = <String>[];

    for (final entry in value) {
      final profession = _professionNameFromJson(entry);

      if (profession != null && !professions.contains(profession)) {
        professions.add(profession);
      }
    }

    return professions;
  }

  static String? _professionNameFromJson(Object? value) {
    if (value is String) {
      return value.trim().isEmpty ? null : value.trim();
    }

    if (value is Map<String, dynamic>) {
      return _professionNameFromJson(value['profession']) ??
          _professionNameFromJson(value['name']);
    }

    if (value is Map) {
      return _professionNameFromJson(value['profession']) ??
          _professionNameFromJson(value['name']);
    }

    return null;
  }
}
