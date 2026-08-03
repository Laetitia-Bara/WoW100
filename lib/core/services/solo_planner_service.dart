import 'package:shared_preferences/shared_preferences.dart';

class SoloPlannerService {
  static const _itemIdsKey = 'solo_planner_item_ids';
  static const _todayItemIdsKey = 'solo_planner_today_item_ids';
  static const _loadedRouteNameKey = 'solo_planner_loaded_route_name';
  static const _routeCompletedStepIdsKey = 'solo_route_completed_step_ids';

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

  Future<void> addSelected(Iterable<String> itemIds) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedIds =
        (prefs.getStringList(_itemIdsKey) ?? const <String>[]).toSet()
          ..addAll(itemIds.where((itemId) => itemId.trim().isNotEmpty));

    final sortedItemIds = selectedIds.toList()..sort();
    await prefs.setStringList(_itemIdsKey, sortedItemIds);
  }

  Future<void> clearSelected(Iterable<String> itemIds) async {
    final prefs = await SharedPreferences.getInstance();
    final removedItemIds = itemIds.toSet();
    final selectedIds =
        (prefs.getStringList(_itemIdsKey) ?? const <String>[]).toSet()
          ..removeAll(removedItemIds);
    final todayItemIds =
        (prefs.getStringList(_todayItemIdsKey) ?? const <String>[]).toSet()
          ..removeAll(removedItemIds);

    final sortedItemIds = selectedIds.toList()..sort();
    final sortedTodayItemIds = todayItemIds.toList()..sort();
    await prefs.setStringList(_itemIdsKey, sortedItemIds);
    await prefs.setStringList(_todayItemIdsKey, sortedTodayItemIds);
    await prefs.remove(_loadedRouteNameKey);
  }

  Future<Set<String>> selectedTodayItemIds(Set<String> wishlistItemIds) async {
    final prefs = await SharedPreferences.getInstance();
    final savedItemIds = prefs.getStringList(_todayItemIdsKey);

    if (savedItemIds == null) {
      return {...wishlistItemIds};
    }

    return savedItemIds.where(wishlistItemIds.contains).toSet();
  }

  Future<String?> loadedRouteName() async {
    final prefs = await SharedPreferences.getInstance();
    final routeName = prefs.getString(_loadedRouteNameKey)?.trim();

    return routeName == null || routeName.isEmpty ? null : routeName;
  }

  Future<void> setTodaySelected(String itemId, bool selected) async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistItemIds = await selectedItemIds();
    final itemIds = await selectedTodayItemIds(wishlistItemIds);

    if (selected && wishlistItemIds.contains(itemId)) {
      itemIds.add(itemId);
    } else {
      itemIds.remove(itemId);
    }

    final sortedItemIds = itemIds.toList()..sort();
    await prefs.setStringList(_todayItemIdsKey, sortedItemIds);
    await prefs.remove(_loadedRouteNameKey);
  }

  Future<void> setAllTodaySelected(
    Iterable<String> itemIds, {
    String? loadedRouteName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final sortedItemIds = itemIds.toSet().toList()..sort();
    await prefs.setStringList(_todayItemIdsKey, sortedItemIds);

    final routeName = loadedRouteName?.trim();
    if (routeName == null || routeName.isEmpty) {
      await prefs.remove(_loadedRouteNameKey);
    } else {
      await prefs.setString(_loadedRouteNameKey, routeName);
    }
  }

  Future<void> clearTodaySelected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_todayItemIdsKey, const <String>[]);
    await prefs.remove(_loadedRouteNameKey);
  }

  Future<Set<String>> routeCompletedStepIds([Set<String>? validStepIds]) async {
    final prefs = await SharedPreferences.getInstance();
    final stepIds =
        (prefs.getStringList(_routeCompletedStepIdsKey) ?? const <String>[])
            .toSet();

    if (validStepIds == null) return stepIds;

    return stepIds.where(validStepIds.contains).toSet();
  }

  Future<void> setRouteStepCompleted(String stepId, bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    final stepIds =
        (prefs.getStringList(_routeCompletedStepIdsKey) ?? const <String>[])
            .toSet();

    if (completed) {
      stepIds.add(stepId);
    } else {
      stepIds.remove(stepId);
    }

    final sortedStepIds = stepIds.toList()..sort();
    await prefs.setStringList(_routeCompletedStepIdsKey, sortedStepIds);
  }

  Future<void> clearRouteCompletedSteps([Iterable<String>? stepIds]) async {
    final prefs = await SharedPreferences.getInstance();

    if (stepIds == null) {
      await prefs.setStringList(_routeCompletedStepIdsKey, const <String>[]);
      return;
    }

    final completedStepIds =
        (prefs.getStringList(_routeCompletedStepIdsKey) ?? const <String>[])
            .toSet()
          ..removeAll(stepIds);
    final sortedStepIds = completedStepIds.toList()..sort();

    await prefs.setStringList(_routeCompletedStepIdsKey, sortedStepIds);
  }
}
