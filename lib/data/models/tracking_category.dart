enum TrackingCategory { achievements, mounts, pets, professions }

extension TrackingCategoryLabel on TrackingCategory {
  String get label {
    switch (this) {
      case TrackingCategory.achievements:
        return 'HF';
      case TrackingCategory.mounts:
        return 'Montures';
      case TrackingCategory.pets:
        return 'Mascottes';
      case TrackingCategory.professions:
        return 'Métiers';
    }
  }
}
