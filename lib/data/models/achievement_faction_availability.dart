import 'tracking_category.dart';
import 'tracking_item.dart';

class AchievementFactionAvailability {
  static const String alliance = 'alliance';
  static const String horde = 'horde';

  static const Map<int, String> _requiredFactionByAchievementId = {
    1271: horde,
    1272: horde,
    1273: horde,
    1356: horde,
    1358: horde,
    1359: horde,
    4894: horde,
    4895: horde,
    4899: alliance,
    4902: alliance,
    4903: alliance,
    4908: horde,
    4925: alliance,
    4926: alliance,
    4927: horde,
    4928: alliance,
    4929: alliance,
    4932: alliance,
    4933: horde,
    4936: alliance,
    4937: alliance,
    4976: horde,
    4978: horde,
    4979: horde,
    4980: horde,
    4981: horde,
    6300: alliance,
    6534: horde,
    6535: alliance,
    6536: horde,
    6537: alliance,
    6538: horde,
    7928: alliance,
    7929: horde,
    8008: horde,
    8306: alliance,
    8307: horde,
    8926: horde,
    8927: alliance,
    8928: horde,
    9132: horde,
    9210: alliance,
    9528: alliance,
    9529: horde,
    9602: alliance,
    10749: alliance,
    11173: horde,
    11210: alliance,
    11211: horde,
    12429: alliance,
    12430: alliance,
    13286: alliance,
    13287: alliance,
    14149: horde,
    14150: alliance,
  };

  static const Map<String, String> _requiredFactionByLocationRef = {
    'wowhead-zone:3524': alliance,
    'wowhead-zone:3525': alliance,
  };

  static bool isUnavailableForFaction(
    TrackingItem item,
    String? characterFaction,
  ) {
    final requiredFaction = requiredFactionFor(item);
    if (requiredFaction == null) return false;

    final selectedFaction = normalizeFaction(characterFaction);
    if (selectedFaction == null) return false;

    return selectedFaction != requiredFaction;
  }

  static String? requiredFactionFor(TrackingItem item) {
    if (item.category != TrackingCategory.achievements) return null;

    final achievementId = item.blizzardId;
    if (achievementId != null) {
      final requiredFaction = _requiredFactionByAchievementId[achievementId];
      if (requiredFaction != null) return requiredFaction;
    }

    return _requiredFactionByLocationRef[item.locationRef];
  }

  static String? normalizeFaction(String? faction) {
    final normalized = faction?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;

    if (normalized == alliance) return alliance;
    if (normalized == horde) return horde;

    return null;
  }
}
