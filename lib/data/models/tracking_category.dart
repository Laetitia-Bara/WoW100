enum TrackingCategory {
  achievements,
  mounts,
  pets,
  professions,
  quests,
  reputations,
  exploration,
  dungeonsRaids,
  worldEvents,
  pvp,
  collections,
  expansionFeatures,
  delves,
  housing,
}

extension TrackingCategoryLabel on TrackingCategory {
  String get label {
    switch (this) {
      case TrackingCategory.achievements:
        return 'Hauts faits';
      case TrackingCategory.mounts:
        return 'Montures';
      case TrackingCategory.pets:
        return 'Mascottes';
      case TrackingCategory.professions:
        return 'Métiers';
      case TrackingCategory.quests:
        return 'Quêtes';
      case TrackingCategory.reputations:
        return 'Réputations';
      case TrackingCategory.exploration:
        return 'Exploration';
      case TrackingCategory.dungeonsRaids:
        return 'Donjons et raids';
      case TrackingCategory.worldEvents:
        return 'Événements mondiaux';
      case TrackingCategory.pvp:
        return 'Joueur contre joueur';
      case TrackingCategory.collections:
        return 'Collections';
      case TrackingCategory.expansionFeatures:
        return 'Contenu d’extension';
      case TrackingCategory.delves:
        return 'Gouffres';
      case TrackingCategory.housing:
        return 'Logis';
    }
  }

  String get shortLabel {
    switch (this) {
      case TrackingCategory.achievements:
        return 'HF';
      case TrackingCategory.mounts:
        return 'Montures';
      case TrackingCategory.pets:
        return 'Mascottes';
      case TrackingCategory.professions:
        return 'Métiers';
      case TrackingCategory.quests:
        return 'Quêtes';
      case TrackingCategory.reputations:
        return 'Réput.';
      case TrackingCategory.exploration:
        return 'Expl.';
      case TrackingCategory.dungeonsRaids:
        return 'Raids';
      case TrackingCategory.worldEvents:
        return 'Events';
      case TrackingCategory.pvp:
        return 'PvP';
      case TrackingCategory.collections:
        return 'Coll.';
      case TrackingCategory.expansionFeatures:
        return 'Features';
      case TrackingCategory.delves:
        return 'Gouffres';
      case TrackingCategory.housing:
        return 'Logis';
    }
  }
}

extension TrackingCategoryParser on TrackingCategory {
  static TrackingCategory fromJson(String value) {
    return TrackingCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => TrackingCategory.collections,
    );
  }
}
