import '../models/wow_expansion.dart';
import '../models/wow_expansion_info.dart';

class WowExpansionCatalog {
  static const List<WowExpansionInfo> all = [
    WowExpansionInfo(
      expansion: WowExpansion.total,
      name: 'Vue totale',
      order: 0,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.vanilla,
      name: 'Classic / Vanilla',
      order: 1,
      releaseYear: 2004,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.tbc,
      name: 'The Burning Crusade',
      order: 2,
      releaseYear: 2007,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.wrath,
      name: 'Wrath of the Lich King',
      order: 3,
      releaseYear: 2008,
    ),
    WowExpansionInfo(
      expansion: WowExpansion.midnight,
      name: 'Midnight',
      order: 12,
    ),
  ];

  static WowExpansionInfo infoOf(WowExpansion expansion) {
    return all.firstWhere((info) => info.expansion == expansion);
  }
}
