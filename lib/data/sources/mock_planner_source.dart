import '../models/tracking_item.dart';
import '../models/tracking_category.dart';
import '../models/wow_expansion.dart';

class MockPlannerSource {
  static List<TrackingItem> getItems(WowExpansion expansion) {
    final items = [
      TrackingItem(
        id: 'invincible',
        name: 'Rênes d’Invincible',
        category: TrackingCategory.mounts,
        expansion: WowExpansion.wrath,
        zone: 'Norfendre',
        instance: 'Citadelle de la Couronne de glace',
        source: 'Le Roi-Liche',
        wowheadItemId: 50818,
        groupRequired: false,
        weeklyLockout: true,
        obtained: false,
      ),

      TrackingItem(
        id: 'mimiron',
        name: 'Tête de Mimiron',
        category: TrackingCategory.mounts,
        expansion: WowExpansion.wrath,
        zone: 'Norfendre',
        instance: 'Ulduar',
        source: 'Yogg-Saron',
        wowheadItemId: 45693,
        groupRequired: false,
        weeklyLockout: true,
        obtained: false,
      ),

      TrackingItem(
        id: 'blue_proto',
        name: 'Proto-drake bleu',
        category: TrackingCategory.mounts,
        expansion: WowExpansion.wrath,
        zone: 'Norfendre',
        instance: 'Cime d’Utgarde',
        source: 'Skadi',
        wowheadItemId: 44151,
        groupRequired: false,
        weeklyLockout: false,
        obtained: false,
      ),
    ];

    return items.where((item) => item.expansion == expansion).toList();
  }
}
