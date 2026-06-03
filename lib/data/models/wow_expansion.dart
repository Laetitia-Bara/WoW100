enum WowExpansion {
  total,
  allMounts,
  vanilla,
  tbc,
  wrath,
  cataclysm,
  mop,
  wod,
  legion,
  bfa,
  shadowlands,
  dragonflight,
  warWithin,
  midnight,
}

extension WowExpansionLabel on WowExpansion {
  String get label {
    switch (this) {
      case WowExpansion.total:
        return 'Vue totale';
      case WowExpansion.allMounts:
        return 'Toutes les montures';
      case WowExpansion.vanilla:
        return 'Vanilla';
      case WowExpansion.tbc:
        return 'The Burning Crusade';
      case WowExpansion.wrath:
        return 'Wrath of the Lich King';
      case WowExpansion.cataclysm:
        return 'Cataclysm';
      case WowExpansion.mop:
        return 'Mists of Pandaria';
      case WowExpansion.wod:
        return 'Warlords of Draenor';
      case WowExpansion.legion:
        return 'Legion';
      case WowExpansion.bfa:
        return 'Battle for Azeroth';
      case WowExpansion.shadowlands:
        return 'Shadowlands';
      case WowExpansion.dragonflight:
        return 'Dragonflight';
      case WowExpansion.warWithin:
        return 'The War Within';
      case WowExpansion.midnight:
        return 'Midnight';
    }
  }
}

extension WowExpansionParser on WowExpansion {
  static WowExpansion fromJson(String value) {
    return WowExpansion.values.firstWhere(
      (expansion) => expansion.name == value,
      orElse: () => WowExpansion.total,
    );
  }
}
