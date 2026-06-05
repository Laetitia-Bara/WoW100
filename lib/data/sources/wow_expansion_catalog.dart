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
      name: 'Vanilla',
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
      expansion: WowExpansion.cataclysm,
      bannerAsset: 'assets/images/expansions/cataclysm.jpg',
      name: 'Cataclysm',
      order: 4,
      releaseYear: 2010,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.mop,
      bannerAsset: 'assets/images/expansions/mop.jpg',
      name: 'Mists of Pandaria',
      order: 5,
      releaseYear: 2012,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.wod,
      bannerAsset: 'assets/images/expansions/bann_dreanor.jpg',
      name: 'Warlords of Draenor',
      order: 6,
      releaseYear: 2014,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.legion,
      bannerAsset: 'assets/images/expansions/legion.jpg',
      name: 'Legion',
      order: 7,
      releaseYear: 2016,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.bfa,
      bannerAsset: 'assets/images/expansions/bann_bfa.jpg',
      name: 'Battle for Azeroth',
      order: 8,
      releaseYear: 2018,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.shadowlands,
      bannerAsset: 'assets/images/expansions/shadow.jpg',
      name: 'Shadowlands',
      order: 9,
      releaseYear: 2020,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.dragonflight,
      bannerAsset: 'assets/images/expansions/dragonflight.jpg',
      name: 'Dragonflight',
      order: 10,
      releaseYear: 2022,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.warWithin,
      bannerAsset: 'assets/images/expansions/tww.jpg',
      name: 'The War Within',
      order: 11,
      releaseYear: 2024,
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
