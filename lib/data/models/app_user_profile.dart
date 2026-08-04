import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_wallpaper_preference.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.isPremium,
    required this.premiumSource,
    required this.premiumExpirationAt,
    required this.revenueCatAppUserId,
    required this.wallpaperPreference,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isPremium;
  final String? premiumSource;
  final DateTime? premiumExpirationAt;
  final String? revenueCatAppUserId;
  final AppWallpaperPreference wallpaperPreference;

  factory AppUserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return AppUserProfile(
      uid: data['uid'] as String? ?? doc.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      isPremium: data['isPremium'] as bool? ?? false,
      premiumSource: data['premiumSource'] as String?,
      premiumExpirationAt: (data['premiumExpirationAt'] as Timestamp?)
          ?.toDate(),
      revenueCatAppUserId: data['revenueCatAppUserId'] as String?,
      wallpaperPreference: AppWallpaperPreference.fromFirestoreValue(
        data['wallpaperPreference'],
      ),
    );
  }
}
