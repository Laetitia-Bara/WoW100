import 'package:shared_preferences/shared_preferences.dart';

class SoloPlannerService {
  static const _itemIdsKey = 'solo_planner_item_ids';

  Future<Set<String>> selectedItemIds() async {
    final prefs = await SharedPreferences.getInstance();

    return (prefs.getStringList(_itemIdsKey) ?? const <String>[]).toSet();
  }

  Future<bool> isSelected(String itemId) async {
    final itemIds = await selectedItemIds();

    return itemIds.contains(itemId);
  }

  Future<void> setSelected(String itemId, bool selected) async {
    final prefs = await SharedPreferences.getInstance();
    final itemIds = (prefs.getStringList(_itemIdsKey) ?? const <String>[])
        .toSet();

    if (selected) {
      itemIds.add(itemId);
    } else {
      itemIds.remove(itemId);
    }

    final sortedItemIds = itemIds.toList()..sort();
    await prefs.setStringList(_itemIdsKey, sortedItemIds);
  }

  Future<void> clearSelected(Iterable<String> itemIds) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedIds = (prefs.getStringList(_itemIdsKey) ?? const <String>[])
        .toSet()
      ..removeAll(itemIds);

    final sortedItemIds = selectedIds.toList()..sort();
    await prefs.setStringList(_itemIdsKey, sortedItemIds);
  }
}
