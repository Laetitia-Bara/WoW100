import 'wow_expansion.dart';

class WowExpansionInfo {
  final WowExpansion expansion;
  final String name;
  final int order;
  final int? releaseYear;

  const WowExpansionInfo({
    required this.expansion,
    required this.name,
    required this.order,
    this.releaseYear,
  });
}
