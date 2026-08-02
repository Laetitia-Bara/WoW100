import 'package:cloud_firestore/cloud_firestore.dart';

class FarmProfile {
  const FarmProfile({
    required this.ownerUid,
    required this.ownerStorageKey,
    required this.ownerCharacterName,
    required this.ownerRealm,
    required this.ownerRealmSlug,
    required this.ownerRegion,
    required this.itemIds,
    this.portraitUrl,
    this.updatedAt,
  });

  final String ownerUid;
  final String ownerStorageKey;
  final String ownerCharacterName;
  final String ownerRealm;
  final String ownerRealmSlug;
  final String ownerRegion;
  final List<String> itemIds;
  final String? portraitUrl;
  final DateTime? updatedAt;

  factory FarmProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return FarmProfile(
      ownerUid: _stringFromJson(data['ownerUid']),
      ownerStorageKey: _stringFromJson(data['ownerStorageKey']),
      ownerCharacterName: _stringFromJson(data['ownerCharacterName']),
      ownerRealm: _stringFromJson(data['ownerRealm']),
      ownerRealmSlug: _stringFromJson(data['ownerRealmSlug']),
      ownerRegion: _stringFromJson(data['ownerRegion']),
      itemIds: _stringListFromJson(data['itemIds']),
      portraitUrl: _nullableStringFromJson(data['portraitUrl']),
      updatedAt: _dateFromJson(data['updatedAt']),
    );
  }

  static String _stringFromJson(Object? value) {
    return value is String ? value : '';
  }

  static String? _nullableStringFromJson(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;

    return value;
  }

  static List<String> _stringListFromJson(Object? value) {
    if (value is! List) return const [];

    return value
        .whereType<String>()
        .where((itemId) => itemId.trim().isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
  }

  static DateTime? _dateFromJson(Object? value) {
    if (value is Timestamp) return value.toDate();

    return null;
  }
}
