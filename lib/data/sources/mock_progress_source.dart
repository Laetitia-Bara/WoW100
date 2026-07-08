import '../models/expansion_progress.dart';
import '../models/tracking_category.dart';
import '../models/wow_expansion.dart';

class MockProgressSource {
  static List<ExpansionProgress> getProgress() {
    return [
      _progress(WowExpansion.total, 2344, 5814),
      _progress(WowExpansion.vanilla, 225, 523),
      _progress(WowExpansion.tbc, 180, 480),
      _progress(WowExpansion.wrath, 210, 520),
      _progress(WowExpansion.cataclysm, 190, 450),
      _progress(WowExpansion.mop, 260, 500),
      _progress(WowExpansion.wod, 170, 430),
      _progress(WowExpansion.legion, 310, 560),
      _progress(WowExpansion.bfa, 280, 610),
      _progress(WowExpansion.shadowlands, 220, 540),
      _progress(WowExpansion.dragonflight, 350, 680),
      _progress(WowExpansion.warWithin, 120, 380),
      _progress(WowExpansion.midnight, 0, 0),
    ];
  }

  static ExpansionProgress _progress(
    WowExpansion expansion,
    int completedTotal,
    int totalTotal,
  ) {
    return ExpansionProgress(
      expansion: expansion,
      completed: {
        TrackingCategory.achievements: completedTotal ~/ 4,
        TrackingCategory.mounts: completedTotal ~/ 8,
        TrackingCategory.pets: completedTotal ~/ 6,
        TrackingCategory.professions: completedTotal ~/ 20,
      },
      total: {
        TrackingCategory.achievements: totalTotal ~/ 4,
        TrackingCategory.mounts: totalTotal ~/ 8,
        TrackingCategory.pets: totalTotal ~/ 6,
        TrackingCategory.professions: totalTotal ~/ 20,
      },
    );
  }
}
