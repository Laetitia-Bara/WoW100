import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GroupRoutePlayer {
  const GroupRoutePlayer({
    required this.id,
    required this.name,
    required this.itemIds,
    this.realm = '',
    this.portraitUrl,
  });

  final String id;
  final String name;
  final String realm;
  final String? portraitUrl;
  final Set<String> itemIds;

  String get displayName {
    if (realm.trim().isEmpty) return name;

    return '$name - $realm';
  }

  factory GroupRoutePlayer.fromJson(Map<String, dynamic> json) {
    return GroupRoutePlayer(
      id: _stringFromJson(json['id']),
      name: _stringFromJson(json['name']),
      realm: _stringFromJson(json['realm']),
      portraitUrl: _nullableStringFromJson(json['portraitUrl']),
      itemIds: _stringSetFromJson(json['itemIds']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'realm': realm,
      'portraitUrl': portraitUrl,
      'itemIds': itemIds.toList()..sort(),
    };
  }

  static String _stringFromJson(Object? value) {
    return value is String ? value : '';
  }

  static String? _nullableStringFromJson(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;

    return value;
  }

  static Set<String> _stringSetFromJson(Object? value) {
    if (value is! List) return const {};

    return value
        .whereType<String>()
        .where((itemId) => itemId.trim().isNotEmpty)
        .toSet();
  }
}

class GroupRouteSession {
  const GroupRouteSession({required this.players});

  final List<GroupRoutePlayer> players;

  bool get isActive => players.length >= 2;

  Set<String> get allItemIds {
    return {for (final player in players) ...player.itemIds};
  }

  Set<String> get commonItemIds {
    if (players.isEmpty) return const {};

    final common = players.first.itemIds.toSet();
    for (final player in players.skip(1)) {
      common.removeWhere((itemId) => !player.itemIds.contains(itemId));
    }

    return common;
  }

  List<GroupRoutePlayer> playersForItem(String itemId) {
    return players.where((player) => player.itemIds.contains(itemId)).toList();
  }

  factory GroupRouteSession.fromJson(Map<String, dynamic> json) {
    final rawPlayers = json['players'];

    return GroupRouteSession(
      players: rawPlayers is List
          ? [
              for (final rawPlayer in rawPlayers)
                if (rawPlayer is Map<String, dynamic>)
                  GroupRoutePlayer.fromJson(rawPlayer)
                else if (rawPlayer is Map)
                  GroupRoutePlayer.fromJson(
                    Map<String, dynamic>.from(rawPlayer),
                  ),
            ]
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'players': players.map((player) => player.toJson()).toList()};
  }
}

class GroupRouteSessionService {
  static const _sessionKey = 'group_route_session';

  Future<GroupRouteSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSession = prefs.getString(_sessionKey);
    if (rawSession == null) return null;

    try {
      final data = jsonDecode(rawSession) as Map<String, dynamic>;
      final session = GroupRouteSession.fromJson(data);

      return session.isActive ? session : null;
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> saveSession(GroupRouteSession session) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_sessionKey);
  }
}
