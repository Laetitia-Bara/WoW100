import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/battle_net_friend.dart';

class BattleNetFriendService {
  static const _key = 'battle_net_manual_friends';

  Future<List<BattleNetFriend>> loadFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final rawFriends = prefs.getStringList(_key) ?? const [];
    final friends = <BattleNetFriend>[];

    for (final rawFriend in rawFriends) {
      try {
        final data = jsonDecode(rawFriend) as Map<String, dynamic>;
        friends.add(BattleNetFriend.fromJson(data));
      } catch (_) {
        // Ignore old or corrupted entries instead of blocking the page.
      }
    }

    friends.sort((a, b) {
      final realmCompare = a.realm.toLowerCase().compareTo(
        b.realm.toLowerCase(),
      );
      if (realmCompare != 0) return realmCompare;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return friends;
  }

  Future<void> saveFriend(BattleNetFriend friend) async {
    final friends = await loadFriends();
    final updatedFriends = [
      for (final existing in friends)
        if (existing.storageKey != friend.storageKey) existing,
      friend,
    ];

    await _saveFriends(updatedFriends);
  }

  Future<void> removeFriend(BattleNetFriend friend) async {
    final friends = await loadFriends();

    await _saveFriends(
      friends
          .where((existing) => existing.storageKey != friend.storageKey)
          .toList(),
    );
  }

  Future<void> _saveFriends(List<BattleNetFriend> friends) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _key,
      friends.map((friend) => jsonEncode(friend.toJson())).toList(),
    );
  }
}
