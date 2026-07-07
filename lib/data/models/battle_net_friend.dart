class BattleNetFriend {
  const BattleNetFriend({
    required this.region,
    required this.name,
    required this.realm,
    required this.realmSlug,
    required this.level,
    required this.race,
    required this.characterClass,
    required this.faction,
    this.guildName,
    this.guildRealm,
    this.guildRealmSlug,
    this.achievementPoints = 0,
    this.portraitUrl,
  });

  final String region;
  final String name;
  final String realm;
  final String realmSlug;
  final int level;
  final String race;
  final String characterClass;
  final String faction;
  final String? guildName;
  final String? guildRealm;
  final String? guildRealmSlug;
  final int achievementPoints;
  final String? portraitUrl;

  String get storageKey =>
      '${region.toLowerCase()}|${realmSlug.toLowerCase()}|${name.toLowerCase()}';

  factory BattleNetFriend.fromJson(Map<String, dynamic> json) {
    return BattleNetFriend(
      region: _stringFromJson(json['region']).toUpperCase(),
      name: _stringFromJson(json['name']),
      realm: _stringFromJson(json['realm']),
      realmSlug: _stringFromJson(json['realmSlug']),
      level: _intFromJson(json['level']),
      race: _stringFromJson(json['race']),
      characterClass: _stringFromJson(json['characterClass']),
      faction: _stringFromJson(json['faction']),
      guildName: _nullableStringFromJson(json['guildName']),
      guildRealm: _nullableStringFromJson(json['guildRealm']),
      guildRealmSlug: _nullableStringFromJson(json['guildRealmSlug']),
      achievementPoints: _intFromJson(json['achievementPoints']),
      portraitUrl: _nullableStringFromJson(json['portraitUrl']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'region': region,
      'name': name,
      'realm': realm,
      'realmSlug': realmSlug,
      'level': level,
      'race': race,
      'characterClass': characterClass,
      'faction': faction,
      'guildName': guildName,
      'guildRealm': guildRealm,
      'guildRealmSlug': guildRealmSlug,
      'achievementPoints': achievementPoints,
      'portraitUrl': portraitUrl,
    };
  }

  static String _stringFromJson(Object? value) {
    return value is String ? value : '';
  }

  static String? _nullableStringFromJson(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return value;
  }

  static int _intFromJson(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();

    return 0;
  }
}
