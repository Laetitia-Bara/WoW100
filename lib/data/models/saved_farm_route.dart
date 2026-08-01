import 'package:cloud_firestore/cloud_firestore.dart';

enum SavedFarmRouteVisibility { private, public }

extension SavedFarmRouteVisibilityLabel on SavedFarmRouteVisibility {
  String get firestoreValue {
    return switch (this) {
      SavedFarmRouteVisibility.private => 'private',
      SavedFarmRouteVisibility.public => 'public',
    };
  }

  String get label {
    return switch (this) {
      SavedFarmRouteVisibility.private => 'Privee',
      SavedFarmRouteVisibility.public => 'Publique',
    };
  }
}

class SavedFarmRoute {
  const SavedFarmRoute({
    required this.id,
    required this.ownerUid,
    required this.ownerStorageKey,
    required this.ownerCharacterName,
    required this.ownerRealm,
    required this.ownerRealmSlug,
    required this.ownerRegion,
    required this.name,
    required this.visibility,
    required this.itemIds,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String ownerStorageKey;
  final String ownerCharacterName;
  final String ownerRealm;
  final String ownerRealmSlug;
  final String ownerRegion;
  final String name;
  final SavedFarmRouteVisibility visibility;
  final List<String> itemIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPublic => visibility == SavedFarmRouteVisibility.public;

  factory SavedFarmRoute.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return SavedFarmRoute(
      id: snapshot.id,
      ownerUid: _stringFromJson(data['ownerUid']),
      ownerStorageKey: _stringFromJson(data['ownerStorageKey']),
      ownerCharacterName: _stringFromJson(data['ownerCharacterName']),
      ownerRealm: _stringFromJson(data['ownerRealm']),
      ownerRealmSlug: _stringFromJson(data['ownerRealmSlug']),
      ownerRegion: _stringFromJson(data['ownerRegion']),
      name: _stringFromJson(data['name']),
      visibility: _visibilityFromJson(data['visibility']),
      itemIds: _stringListFromJson(data['itemIds']),
      createdAt: _dateFromJson(data['createdAt']),
      updatedAt: _dateFromJson(data['updatedAt']),
    );
  }

  static SavedFarmRouteVisibility _visibilityFromJson(Object? value) {
    return value == SavedFarmRouteVisibility.public.firestoreValue
        ? SavedFarmRouteVisibility.public
        : SavedFarmRouteVisibility.private;
  }

  static String _stringFromJson(Object? value) {
    return value is String ? value : '';
  }

  static List<String> _stringListFromJson(Object? value) {
    if (value is! List) return const [];

    return value
        .whereType<String>()
        .where((itemId) {
          return itemId.trim().isNotEmpty;
        })
        .toList(growable: false);
  }

  static DateTime? _dateFromJson(Object? value) {
    if (value is Timestamp) return value.toDate();

    return null;
  }
}
