import '../models/wow_expansion.dart';
import '../models/wow_expansion_info.dart';

class WowExpansionCatalog {
  static const List<WowExpansionInfo> all = [
    WowExpansionInfo(
      expansion: WowExpansion.total,
      bannerAsset: 'assets/images/expansions/vanilla.jpg',
      name: 'Vue totale',
      order: 0,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.vanilla,
      bannerAsset: 'assets/images/expansions/vanilla.jpg',
      name: 'Classic / Vanilla',
      order: 1,
      releaseYear: 2004,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.tbc,
      bannerAsset: 'assets/images/expansions/tbc.jpg',
      name: 'The Burning Crusade',
      order: 2,
      releaseYear: 2007,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.wrath,
      bannerAsset: 'assets/images/expansions/wrath.jpg',
      name: 'Wrath of the Lich King',
      order: 3,
      releaseYear: 2008,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.midnight,
      bannerAsset: 'assets/images/expansions/midnight.jpg',
      name: 'Midnight',
      order: 12,
    ),
  ];

  static WowExpansionInfo infoOf(WowExpansion expansion) {
    return all.firstWhere((info) => info.expansion == expansion);
  }
}
