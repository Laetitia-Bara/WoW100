import 'package:shared_preferences/shared_preferences.dart';

class LocalCheckService {
  static const _prefix = 'planner_check_';

  Future<bool> isChecked(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$itemId') ?? false;
  }

  Future<Set<String>> checkedItemIds(Iterable<String> itemIds) async {
    final prefs = await SharedPreferences.getInstance();
    return itemIds
        .where((itemId) => prefs.getBool('$_prefix$itemId') ?? false)
        .toSet();
  }

  Future<void> setChecked(String itemId, bool checked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$itemId', checked);
  }

  Future<void> clearChecked(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$itemId');
  }

  Future<void> clearCheckedItems(Iterable<String> itemIds) async {
    final prefs = await SharedPreferences.getInstance();

    for (final itemId in itemIds) {
      await prefs.remove('$_prefix$itemId');
    }
  }
}
