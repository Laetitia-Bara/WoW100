enum AppWallpaperPreference {
  factions,
  horde,
  alliance;

  static AppWallpaperPreference fromFirestoreValue(Object? value) {
    return switch (value) {
      'horde' => AppWallpaperPreference.horde,
      'alliance' => AppWallpaperPreference.alliance,
      _ => AppWallpaperPreference.factions,
    };
  }

  String get firestoreValue {
    return switch (this) {
      AppWallpaperPreference.factions => 'default',
      AppWallpaperPreference.horde => 'horde',
      AppWallpaperPreference.alliance => 'alliance',
    };
  }

  String get label {
    return switch (this) {
      AppWallpaperPreference.factions => 'Horde + Alliance',
      AppWallpaperPreference.horde => 'Horde',
      AppWallpaperPreference.alliance => 'Alliance',
    };
  }

  String get assetPath {
    return switch (this) {
      AppWallpaperPreference.factions =>
        'assets/images/icones/wallpaper_app.jpg',
      AppWallpaperPreference.horde =>
        'assets/images/icones/wallpaper_horde.png',
      AppWallpaperPreference.alliance =>
        'assets/images/icones/wallpaper_alliance.png',
    };
  }
}
