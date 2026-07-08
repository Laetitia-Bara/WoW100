import 'wow_expansion.dart';

class WowExpansionInfo {
  final WowExpansion expansion;
  final String name;
  final int order;
  final int? releaseYear;
  final String bannerAsset;

  const WowExpansionInfo({
    required this.expansion,
    required this.name,
    required this.order,
    this.releaseYear,
    required this.bannerAsset,
  });
}
