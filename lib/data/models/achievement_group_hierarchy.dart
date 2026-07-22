import 'tracking_category.dart';
import 'tracking_item.dart';

class AchievementGroupHierarchy {
  static const separator = ' > ';

  static const rootOrder = [
    'Personnages',
    'Quêtes',
    'Exploration',
    'Logis',
    'Gouffres',
    'Joueur contre Joueur',
    'Donjons et raids',
    'Métiers',
    'Réputation',
    'Événements mondiaux',
    'Combats de mascottes',
    'Collections',
    'Contenu d’extension',
  ];

  static const leafOrderByRoot = {
    'Quêtes': [
      "Royaumes de l'Est",
      'Kalimdor',
      'Outreterre',
      'Norfendre',
      'Cataclysm',
      'Pandarie',
      'Draenor',
      'Legion',
      'Battle for Azeroth',
      'Ombreterre',
      'Dragonflight',
      'War Within',
      'Midnight',
    ],
    'Exploration': [
      "Royaumes de l'Est",
      'Kalimdor',
      'Outreterre',
      'Norfendre',
      'Cataclysm',
      'Pandarie',
      'Draenor',
      'Legion',
      'Battle for Azeroth',
      'Ombreterre',
      'Îles aux Dragons',
      'War Within',
      'Midnight',
    ],
    'Gouffres': ['The War Within', 'Midnight'],
    'Joueur contre Joueur': [
      'Honneur',
      'Goulet des Chanteguerres',
      'Bassin Arathi',
      'Œil du cyclone',
      "Vallée d'Alterac",
      "A’shran",
      "L’île des Conquérants",
      "Joug-d’hiver",
      'Bataille de Gilnéas',
      'Pics-Jumeaux',
      "Mines d’Éclargent",
      'Temple de Kotmogu',
      'Rivage Bouillonnant',
      'Gorge de Vent-Caverneux',
      "Ravin d’Abondabîme",
      'Colline Meurtrière',
      'Champs de bataille',
      'Arène',
      "Terrain d’entraînement",
      'En extérieur',
    ],
    'Donjons et raids': [
      'Donjons',
      'Raids',
      'Classique',
      'The Burning Crusade',
      'Donjons de Lich King',
      'Raids de Lich King',
      'Donjons de Cataclysm',
      'Raids de Cataclysm',
      'Donjons de Mists of Pandaria',
      'Raids de Mists of Pandaria',
      'Donjons de Warlords of Draenor',
      'Raids de Warlords of Draenor',
      'Donjons de Legion',
      'Raids de Legion',
      'Donjons de Battle for Azeroth',
      'Raids de Battle for Azeroth',
      'Donjons de Shadowlands',
      'Raids de Shadowlands',
      'Donjons de Dragonflight',
      'Raids de Dragonflight',
      'Donjons de The War Within',
      'Raids de The War Within',
      'Donjons de Midnight',
      'Raids de Midnight',
    ],
    'Métiers': [
      'Alchimie',
      'Forge',
      'Enchantement',
      'Ingénierie',
      'Calligraphie',
      'Joaillerie',
      'Travail du cuir',
      'Couture',
      'Herboristerie',
      'Minage',
      'Dépeçage',
      'Cuisine',
      'Pêche',
      'Archéologie',
    ],
    'Réputation': [
      'Classique',
      'The Burning Crusade',
      'Wrath of the Lich King',
      'Cataclysm',
      'Pandarie',
      'Draenor',
      'Legion',
      'Battle for Azeroth',
      'Shadowlands',
      'Dragonflight',
      'War Within',
      'Midnight',
    ],
    'Événements mondiaux': [
      'Fête lunaire',
      "De l’amour dans l’air",
      'Jardin des nobles',
      'Semaine des enfants',
      "Solstice d'été",
      'Fête des Brasseurs',
      'Sanssaint',
      'Bienfaits du pèlerin',
      "Voile d'hiver",
      'Foire de Sombrelune',
      'Marcheurs du temps',
      "Célébration d’anniversaire",
      'Duos infâmes',
      'Les Bastonneurs',
      'Duel de décoration',
    ],
    'Combats de mascottes': ['Collections', 'Bataille', 'Niveau'],
    'Collections': [
      'Coffre à jouets',
      'Montures',
      'Apparences',
      'Drake des îles aux Dragons (cosmétique)',
    ],
    'Contenu d’extension': [
      "Tournoi d'Argent",
      'Tol Barad',
      'Scénarios de Mists of Pandaria',
      'Ordalie',
      'Fief de Draenor',
      'Domaines de classe de Legion',
      'Exploration des îles',
      'Effort de guerre',
      "Cœur d’Azeroth",
      "Visions de N’Zoth",
      'Tourment',
      'Sanctums des congrégations',
      'Vol dynamique',
      "Visions de N’Zoth redécouvertes",
      'Chroniques',
      'Traque',
      'Sites rituels',
      'Assauts du Vide',
    ],
  };

  static const _rootOnlyCategoryIds = {
    92,
    95,
    96,
    97,
    155,
    168,
    169,
    201,
    15077,
    15078,
    15079,
    15080,
    15089,
    15117,
    15246,
    15270,
    15279,
    15301,
    15411,
    15531,
    15606,
  };

  static const _rootByCategoryId = {
    92: 'Personnages',
    95: 'Joueur contre Joueur',
    96: 'Quêtes',
    97: 'Exploration',
    155: 'Événements mondiaux',
    156: 'Événements mondiaux',
    158: 'Événements mondiaux',
    159: 'Événements mondiaux',
    160: 'Événements mondiaux',
    161: 'Événements mondiaux',
    162: 'Événements mondiaux',
    163: 'Événements mondiaux',
    165: 'Joueur contre Joueur',
    168: 'Donjons et raids',
    169: 'Métiers',
    170: 'Métiers',
    171: 'Métiers',
    172: 'Métiers',
    187: 'Événements mondiaux',
    201: 'Réputation',
    14777: 'Exploration',
    14778: 'Exploration',
    14779: 'Exploration',
    14780: 'Exploration',
    14801: 'Joueur contre Joueur',
    14802: 'Joueur contre Joueur',
    14803: 'Joueur contre Joueur',
    14804: 'Joueur contre Joueur',
    14805: 'Donjons et raids',
    14806: 'Donjons et raids',
    14808: 'Donjons et raids',
    14861: 'Quêtes',
    14862: 'Quêtes',
    14863: 'Quêtes',
    14864: 'Réputation',
    14865: 'Réputation',
    14866: 'Réputation',
    14901: 'Joueur contre Joueur',
    14922: 'Donjons et raids',
    14941: 'Contenu d’extension',
    14981: 'Événements mondiaux',
    15003: 'Joueur contre Joueur',
    15067: 'Donjons et raids',
    15068: 'Donjons et raids',
    15069: 'Exploration',
    15070: 'Quêtes',
    15071: 'Métiers',
    15072: 'Réputation',
    15073: 'Joueur contre Joueur',
    15074: 'Joueur contre Joueur',
    15075: 'Contenu d’extension',
    15077: 'Quêtes',
    15078: 'Joueur contre Joueur',
    15079: 'Donjons et raids',
    15080: 'Métiers',
    15081: 'Quêtes',
    15082: 'Donjons et raids',
    15083: 'Donjons et raids',
    15084: 'Donjons et raids',
    15085: 'Donjons et raids',
    15086: 'Donjons et raids',
    15087: 'Donjons et raids',
    15089: 'Réputation',
    15090: 'Joueur contre Joueur',
    15091: 'Joueur contre Joueur',
    15092: 'Joueur contre Joueur',
    15101: 'Événements mondiaux',
    15106: 'Donjons et raids',
    15107: 'Donjons et raids',
    15110: 'Quêtes',
    15113: 'Exploration',
    15114: 'Réputation',
    15117: 'Combats de mascottes',
    15118: 'Combats de mascottes',
    15119: 'Combats de mascottes',
    15120: 'Combats de mascottes',
    15153: 'Donjons et raids',
    15154: 'Donjons et raids',
    15162: 'Joueur contre Joueur',
    15163: 'Joueur contre Joueur',
    15218: 'Joueur contre Joueur',
    15220: 'Quêtes',
    15222: 'Contenu d’extension',
    15228: 'Donjons et raids',
    15231: 'Donjons et raids',
    15232: 'Réputation',
    15235: 'Exploration',
    15243: 'Donjons et raids',
    15244: 'Donjons et raids',
    15246: 'Collections',
    15247: 'Collections',
    15248: 'Collections',
    15252: 'Quêtes',
    15254: 'Donjons et raids',
    15255: 'Donjons et raids',
    15257: 'Exploration',
    15258: 'Réputation',
    15259: 'Collections',
    15262: 'Donjons et raids',
    15263: 'Donjons et raids',
    15266: 'Joueur contre Joueur',
    15270: 'Joueur contre Joueur',
    15271: 'Donjons et raids',
    15272: 'Donjons et raids',
    15277: 'Donjons et raids',
    15278: 'Donjons et raids',
    15279: 'Joueur contre Joueur',
    15283: 'Joueur contre Joueur',
    15284: 'Quêtes',
    15285: 'Donjons et raids',
    15286: 'Donjons et raids',
    15292: 'Joueur contre Joueur',
    15298: 'Exploration',
    15299: 'Donjons et raids',
    15300: 'Donjons et raids',
    15301: 'Contenu d’extension',
    15302: 'Contenu d’extension',
    15303: 'Contenu d’extension',
    15304: 'Contenu d’extension',
    15305: 'Réputation',
    15307: 'Contenu d’extension',
    15308: 'Contenu d’extension',
    15411: 'Contenu d’extension',
    15414: 'Joueur contre Joueur',
    15416: 'Événements mondiaux',
    15417: 'Contenu d’extension',
    15422: 'Quêtes',
    15426: 'Contenu d’extension',
    15428: 'Donjons et raids',
    15429: 'Donjons et raids',
    15436: 'Exploration',
    15438: 'Donjons et raids',
    15439: 'Réputation',
    15440: 'Contenu d’extension',
    15441: 'Contenu d’extension',
    15442: 'Donjons et raids',
    15454: 'Événements mondiaux',
    15455: 'Quêtes',
    15462: 'Contenu d’extension',
    15465: 'Exploration',
    15466: 'Quêtes',
    15467: 'Donjons et raids',
    15468: 'Donjons et raids',
    15470: 'Donjons et raids',
    15471: 'Donjons et raids',
    15478: 'Collections',
    15489: 'Métiers',
    15490: 'Métiers',
    15491: 'Métiers',
    15492: 'Métiers',
    15493: 'Métiers',
    15494: 'Métiers',
    15495: 'Métiers',
    15496: 'Métiers',
    15497: 'Métiers',
    15498: 'Métiers',
    15499: 'Métiers',
    15506: 'Réputation',
    15521: 'Quêtes',
    15522: 'Gouffres',
    15523: 'Exploration',
    15524: 'Donjons et raids',
    15525: 'Joueur contre Joueur',
    15526: 'Donjons et raids',
    15528: 'Donjons et raids',
    15529: 'Donjons et raids',
    15530: 'Exploration',
    15531: 'Gouffres',
    15532: 'Événements mondiaux',
    15541: 'Donjons et raids',
    15545: 'Événements mondiaux',
    15546: 'Contenu d’extension',
    15547: 'Réputation',
    15552: 'Contenu d’extension',
    15553: 'Quêtes',
    15566: 'Donjons et raids',
    15567: 'Événements mondiaux',
    15569: 'Donjons et raids',
    15570: 'Donjons et raids',
    15571: 'Gouffres',
    15574: 'Événements mondiaux',
    15575: 'Joueur contre Joueur',
    15600: 'Exploration',
    15605: 'Contenu d’extension',
    15606: 'Logis',
    15608: 'Contenu d’extension',
    15609: 'Joueur contre Joueur',
    15610: 'Contenu d’extension',
  };

  static String? labelFor(TrackingItem item) {
    if (item.category != TrackingCategory.achievements) return null;

    final leaf = item.blizzardCategoryName.trim();
    if (leaf == 'Guilde') return leaf;

    final categoryId = item.blizzardCategoryId;
    if (categoryId == null) return null;

    final root = _rootByCategoryId[categoryId];
    if (root == null) return null;

    if (_rootOnlyCategoryIds.contains(categoryId) ||
        leaf.isEmpty ||
        leaf == root) {
      return root;
    }

    return '$root$separator$leaf';
  }

  static String rootLabel(String label) {
    final parts = _split(label);
    return parts.root;
  }

  static int? compare(String left, String right) {
    final leftParts = _split(left);
    final rightParts = _split(right);
    final leftRootIndex = rootOrder.indexOf(leftParts.root);
    final rightRootIndex = rootOrder.indexOf(rightParts.root);

    if (leftRootIndex == -1 && rightRootIndex == -1) return null;
    if (leftRootIndex == -1) return 1;
    if (rightRootIndex == -1) return -1;

    if (leftRootIndex != rightRootIndex) {
      return leftRootIndex.compareTo(rightRootIndex);
    }

    if (leftParts.leaf == null && rightParts.leaf == null) return 0;
    if (leftParts.leaf == null) return -1;
    if (rightParts.leaf == null) return 1;

    final leafOrder = leafOrderByRoot[leftParts.root] ?? const [];
    final leftLeafIndex = leafOrder.indexOf(leftParts.leaf!);
    final rightLeafIndex = leafOrder.indexOf(rightParts.leaf!);

    if (leftLeafIndex != -1 && rightLeafIndex != -1) {
      return leftLeafIndex.compareTo(rightLeafIndex);
    }

    if (leftLeafIndex != -1) return -1;
    if (rightLeafIndex != -1) return 1;

    return leftParts.leaf!.compareTo(rightParts.leaf!);
  }

  static ({String root, String? leaf}) _split(String label) {
    final parts = label.split(separator);
    if (parts.length < 2) return (root: label, leaf: null);

    return (root: parts.first, leaf: parts.sublist(1).join(separator));
  }
}
