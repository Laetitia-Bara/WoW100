import 'package:wow100/data/models/tracking_item.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/battle_net_token_service.dart';
import '../../core/services/local_check_service.dart';
import '../models/expansion_progress.dart';
import '../models/tracking_category.dart';
import '../models/wow_expansion.dart';
import '../repositories/battle_net_repository.dart';
import '../sources/json_planner_source.dart';

abstract class ProgressRepository {
  Future<List<ExpansionProgress>> getProgress();
}

class JsonProgressRepository implements ProgressRepository {
  final JsonPlannerSource _source = JsonPlannerSource();
  final LocalCheckService _localCheckService = LocalCheckService();
  final BattleNetTokenService _tokenService = BattleNetTokenService();
  final BattleNetRepository _battleNetRepository = BattleNetRepository();

  @override
  Future<List<ExpansionProgress>> getProgress() async {
    final expansions = [
      WowExpansion.vanilla,
      WowExpansion.tbc,
      WowExpansion.wrath,
      WowExpansion.cataclysm,
      WowExpansion.mop,
      WowExpansion.wod,
      WowExpansion.legion,
      WowExpansion.bfa,
      WowExpansion.shadowlands,
      WowExpansion.dragonflight,
      WowExpansion.warWithin,
      WowExpansion.midnight,
    ];

    final allMountItems = await _source.loadMountItems(WowExpansion.allMounts);

    final token = await _tokenService.loadToken();

    final ownedMountIds = <int>{};

    if (token != null) {
      try {
        final mounts = await _battleNetRepository.getMounts(token);
        ownedMountIds.addAll(mounts.map((mount) => mount.id));
      } catch (e, stack) {
        debugPrint('BATTLE.NET MOUNTS ERROR: $e');
        debugPrint('$stack');
      }
    }

    final progresses = <ExpansionProgress>[];

    for (final expansion in expansions) {
      final expansionItems = allMountItems
          .where((item) => item.expansion == expansion)
          .toList();

      progresses.add(
        await _buildProgress(expansion, expansionItems, ownedMountIds),
      );
    }

    return [
      await _buildProgress(WowExpansion.total, allMountItems, ownedMountIds),
      ...progresses,
    ];
  }

  Future<ExpansionProgress> _buildProgress(
    WowExpansion expansion,
    List<TrackingItem> items,
    Set<int> ownedMountIds,
  ) async {
    var completedMounts = 0;

    for (final item in items) {
      final checked = await _localCheckService.isChecked(item.id);
      final owned =
          item.blizzardId != null && ownedMountIds.contains(item.blizzardId);

      if (checked || owned) {
        completedMounts += 1;
      }
    }

    return ExpansionProgress(
      expansion: expansion,
      completed: {TrackingCategory.mounts: completedMounts},
      total: {TrackingCategory.mounts: items.length},
    );
  }
}
