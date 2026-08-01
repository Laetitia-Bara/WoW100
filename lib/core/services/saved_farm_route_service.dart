import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../data/models/battle_net_friend.dart';
import '../../data/models/saved_farm_route.dart';
import '../../data/models/wow_character.dart';

class SavedFarmRouteService {
  SavedFarmRouteService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static const _routesCollection = 'farmRoutes';
  static const _defaultRegion = 'EU';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<List<SavedFarmRoute>> loadMyRoutes() async {
    final user = _currentUser;
    if (user == null) return const [];

    final snapshot = await _routesRef
        .where('ownerUid', isEqualTo: user.uid)
        .get();
    final routes = snapshot.docs.map(SavedFarmRoute.fromFirestore).toList();

    _sortRoutes(routes);
    return routes;
  }

  Future<List<SavedFarmRoute>> loadPublicRoutesForFriend(
    BattleNetFriend friend,
  ) async {
    final user = _currentUser;
    if (user == null) return const [];

    final snapshot = await _routesRef
        .where('ownerStorageKey', isEqualTo: friend.storageKey)
        .where(
          'visibility',
          isEqualTo: SavedFarmRouteVisibility.public.firestoreValue,
        )
        .get();
    final routes = snapshot.docs.map(SavedFarmRoute.fromFirestore).toList();

    _sortRoutes(routes);
    return routes;
  }

  Future<SavedFarmRoute> saveRoute({
    required String name,
    required SavedFarmRouteVisibility visibility,
    required Iterable<String> itemIds,
    required WowCharacter? character,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No Firebase account is signed in.',
      );
    }

    final routeRef = _routesRef.doc();
    final uniqueItemIds =
        itemIds.where((itemId) => itemId.trim().isNotEmpty).toSet().toList()
          ..sort();
    final ownerRegion = _defaultRegion;
    final ownerStorageKey = _ownerStorageKey(
      uid: user.uid,
      character: character,
      region: ownerRegion,
    );
    final routeData = <String, Object?>{
      'ownerUid': user.uid,
      'ownerStorageKey': ownerStorageKey,
      'ownerCharacterName': character?.name ?? user.displayName ?? 'Joueur',
      'ownerRealm': character?.realm ?? '',
      'ownerRealmSlug': character?.realmSlug ?? '',
      'ownerRegion': ownerRegion,
      'name': name.trim(),
      'visibility': visibility.firestoreValue,
      'itemIds': uniqueItemIds,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await routeRef.set(routeData);
    final snapshot = await routeRef.get();

    return SavedFarmRoute.fromFirestore(snapshot);
  }

  User? get _currentUser {
    if (Firebase.apps.isEmpty) {
      return null;
    }

    return _auth.currentUser;
  }

  CollectionReference<Map<String, dynamic>> get _routesRef {
    return _firestore.collection(_routesCollection);
  }

  String _ownerStorageKey({
    required String uid,
    required WowCharacter? character,
    required String region,
  }) {
    final realmSlug = character?.realmSlug.trim().toLowerCase() ?? '';
    final name = character?.name.trim().toLowerCase() ?? '';

    if (realmSlug.isEmpty || name.isEmpty) {
      return 'uid|$uid';
    }

    return '${region.toLowerCase()}|$realmSlug|$name';
  }

  void _sortRoutes(List<SavedFarmRoute> routes) {
    routes.sort((left, right) {
      final leftDate = left.updatedAt ?? left.createdAt ?? DateTime(1970);
      final rightDate = right.updatedAt ?? right.createdAt ?? DateTime(1970);
      final dateCompare = rightDate.compareTo(leftDate);
      if (dateCompare != 0) return dateCompare;

      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
  }
}
