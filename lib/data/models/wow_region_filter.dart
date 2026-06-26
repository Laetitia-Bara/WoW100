import 'tracking_item.dart';
import 'wow_expansion.dart';

class WowRegionFilter {
  final WowExpansion expansion;
  final String region;
  final String zone;
  final String subzone;

  const WowRegionFilter({
    required this.expansion,
    required this.region,
    required this.zone,
    this.subzone = '',
  });

  String get key =>
      '${expansion.name}|${normalize(region)}|${normalize(zone)}|${normalize(subzone)}';

  String get label => subzone.isEmpty ? zone : subzone;

  String get fullLabel =>
      subzone.isEmpty ? '$zone - $region' : '$subzone - $zone - $region';

  bool matches(TrackingItem item) {
    return item.expansion == expansion &&
        normalize(item.region) == normalize(region) &&
        normalize(item.zone) == normalize(zone) &&
        (subzone.isEmpty || normalize(item.subzone) == normalize(subzone));
  }

  static WowRegionFilter? fromItem(TrackingItem item) {
    final region = item.region.trim();
    final zone = TrackingItem.canonicalWorldZone(item.zone);
    final canonicalRegion = TrackingItem.canonicalRegionForZone(zone);
    final effectiveRegion = zone == TrackingItem.unknownZone
        ? TrackingItem.unknownZone
        : canonicalRegion ?? region;
    final normalizedRegion = normalize(region);
    final normalizedZone = normalize(zone);

    if (effectiveRegion.isEmpty || zone.isEmpty) return null;
    if (_genericZones.contains(normalizedZone) &&
        normalizedZone != normalizedRegion) {
      return null;
    }
    if (TrackingItem.isWorldRegion(zone) &&
        normalizedZone == normalizedRegion) {
      return null;
    }

    return WowRegionFilter(
      expansion: item.expansion,
      region: effectiveRegion,
      zone: zone,
    );
  }

  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r"['`\-/\u00b4\u2018\u2019]"), ' ')
        .replaceAll(RegExp(r'[\u00e0\u00e2\u00e4]'), 'a')
        .replaceAll(RegExp(r'[\u00e9\u00e8\u00ea\u00eb]'), 'e')
        .replaceAll(RegExp(r'[\u00ee\u00ef]'), 'i')
        .replaceAll(RegExp(r'[\u00f4\u00f6]'), 'o')
        .replaceAll(RegExp(r'[\u00f9\u00fb\u00fc]'), 'u')
        .replaceAll('\u00e7', 'c')
        .replaceAll('\u0153', 'oe')
        .replaceAll('Ã ', 'a')
        .replaceAll('Ã¢', 'a')
        .replaceAll('Ã¤', 'a')
        .replaceAll('Ã©', 'e')
        .replaceAll('Ã¨', 'e')
        .replaceAll('Ãª', 'e')
        .replaceAll('Ã«', 'e')
        .replaceAll('Ã®', 'i')
        .replaceAll('Ã¯', 'i')
        .replaceAll('Ã´', 'o')
        .replaceAll('Ã¶', 'o')
        .replaceAll('Ã¹', 'u')
        .replaceAll('Ã»', 'u')
        .replaceAll('Ã¼', 'u')
        .replaceAll('Ã§', 'c')
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
    'the burning crusade',
    'vanilla',
    'wrath of the lich king',
    'mists of pandaria',
    'warlords of draenor',
    'legion',
    'battle for azeroth',
    'shadowlands',
    'dragonflight',
    'the war within',
    'midnight',
  };
}
