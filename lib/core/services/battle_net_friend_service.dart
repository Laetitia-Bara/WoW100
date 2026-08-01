import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/battle_net_friend.dart';

class BattleNetFriendService {
  BattleNetFriendService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static const _legacyKey = 'battle_net_manual_friends';
  static const _friendsCollection = 'friends';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<List<BattleNetFriend>> loadFriends() async {
    final user = _currentUser;
    if (user == null) {
      return _loadLegacyFriends();
    }

    try {
      await _migrateLegacyFriends(user.uid);

      final snapshot = await _friendsRef(user.uid).get();
      final friends = snapshot.docs.map((doc) {
        return BattleNetFriend.fromJson(doc.data());
      }).toList();

      _sortFriends(friends);
      return friends;
    } on FirebaseException {
      return _loadLegacyFriends();
    }
  }

  Future<void> saveFriend(BattleNetFriend friend) async {
    final user = _currentUser;
    if (user == null) {
      await _saveLegacyFriend(friend);
      return;
    }

    await _migrateLegacyFriends(user.uid);
    await _friendRef(user.uid, friend).set(_friendToFirestore(friend));
    await _clearLegacyFriends();
  }

  Future<void> removeFriend(BattleNetFriend friend) async {
    final user = _currentUser;
    if (user == null) {
      await _removeLegacyFriend(friend);
      return;
    }

    await _friendRef(user.uid, friend).delete();
  }

  User? get _currentUser {
    if (Firebase.apps.isEmpty) {
      return null;
    }

    return _auth.currentUser;
  }

  CollectionReference<Map<String, dynamic>> _friendsRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection(_friendsCollection);
  }

  DocumentReference<Map<String, dynamic>> _friendRef(
    String uid,
    BattleNetFriend friend,
  ) {
    return _friendsRef(uid).doc(friend.storageKey);
  }

  Map<String, Object?> _friendToFirestore(BattleNetFriend friend) {
    return {
      ...friend.toJson(),
      'storageKey': friend.storageKey,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _migrateLegacyFriends(String uid) async {
    final legacyFriends = await _loadLegacyFriends();
    if (legacyFriends.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final friend in legacyFriends) {
      batch.set(_friendRef(uid, friend), _friendToFirestore(friend));
    }

    await batch.commit();
    await _clearLegacyFriends();
  }

  Future<List<BattleNetFriend>> _loadLegacyFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final rawFriends = prefs.getStringList(_legacyKey) ?? const [];
    final friends = <BattleNetFriend>[];

    for (final rawFriend in rawFriends) {
      try {
        final data = jsonDecode(rawFriend) as Map<String, dynamic>;
        friends.add(BattleNetFriend.fromJson(data));
      } catch (_) {
        // Ignore old or corrupted entries instead of blocking the page.
      }
    }

    _sortFriends(friends);
    return friends;
  }

  Future<void> _saveLegacyFriend(BattleNetFriend friend) async {
    final friends = await _loadLegacyFriends();
    final updatedFriends = [
      for (final existing in friends)
        if (existing.storageKey != friend.storageKey) existing,
      friend,
    ];

    await _saveLegacyFriends(updatedFriends);
  }

  Future<void> _removeLegacyFriend(BattleNetFriend friend) async {
    final friends = await _loadLegacyFriends();

    await _saveLegacyFriends(
      friends
          .where((existing) => existing.storageKey != friend.storageKey)
          .toList(),
    );
  }

  Future<void> _saveLegacyFriends(List<BattleNetFriend> friends) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _legacyKey,
      friends.map((friend) => jsonEncode(friend.toJson())).toList(),
    );
  }

  Future<void> _clearLegacyFriends() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKey);
  }

  void _sortFriends(List<BattleNetFriend> friends) {
    friends.sort((a, b) {
      final realmCompare = a.realm.toLowerCase().compareTo(
        b.realm.toLowerCase(),
      );
      if (realmCompare != 0) return realmCompare;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }
}
