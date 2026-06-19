import 'tracking_item.dart';
import 'wow_expansion.dart';

class WowRegionFilter {
  final WowExpansion expansion;
  final String region;
  final String zone;

  const WowRegionFilter({
    required this.expansion,
    required this.region,
    required this.zone,
  });

  String get key => '${expansion.name}|${normalize(region)}|${normalize(zone)}';

  String get label => zone;

  String get fullLabel => '$zone - $region';

  bool matches(TrackingItem item) {
    return item.expansion == expansion &&
        normalize(item.region) == normalize(region) &&
        normalize(item.zone) == normalize(zone);
  }

  static WowRegionFilter? fromItem(TrackingItem item) {
    final region = item.region.trim();
    final zone = item.zone.trim();

    if (region.isEmpty || zone.isEmpty) return null;
    if (_genericZones.contains(normalize(zone)) &&
        normalize(zone) != normalize(region)) {
      return null;
    }

    return WowRegionFilter(
      expansion: item.expansion,
      region: region,
      zone: zone,
    );
  }

  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r"['’´`\-/]"), ' ')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const Set<String> _genericZones = {
    'apparences',
    'bataille',
    'butin',
    'cataclysm',
    'collections',
    'donjons',
    'evenements mondiaux',
    'exploration',
    'general',
    'haut fait',
    'hauts faits',
    'metiers',
    'promotion blizzard',
    'pvp',
    'quetes',
    'raid',
    'raids',
    'reputation',
    'source a verifier',
  };
}
