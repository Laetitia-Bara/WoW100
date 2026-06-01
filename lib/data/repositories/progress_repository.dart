import '../models/expansion_progress.dart';
import '../models/tracking_category.dart';
import '../models/wow_expansion.dart';
import '../sources/json_planner_source.dart';
import '../../core/services/local_check_service.dart';

abstract class ProgressRepository {
  Future<List<ExpansionProgress>> getProgress();
}

class JsonProgressRepository implements ProgressRepository {
  final JsonPlannerSource _source = JsonPlannerSource();
  final LocalCheckService _localCheckService = LocalCheckService();

  @override
  Future<List<ExpansionProgress>> getProgress() async {
    final wrathItems = [
      ...await _source.loadItemsFromAsset(
        'assets/data/mounts/wrath_mounts.json',
      ),
      ...await _source.loadItemsFromAsset('assets/data/pets/wrath_pets.json'),
    ];

    final completed = <TrackingCategory, int>{};
    final total = <TrackingCategory, int>{};

    for (final item in wrathItems) {
      total[item.category] = (total[item.category] ?? 0) + 1;

      final checked = await _localCheckService.isChecked(item.id);
      if (checked) {
        completed[item.category] = (completed[item.category] ?? 0) + 1;
      }
    }

    return [
      ExpansionProgress(
        expansion: WowExpansion.total,
        completed: completed,
        total: total,
      ),
      ExpansionProgress(
        expansion: WowExpansion.wrath,
        completed: completed,
        total: total,
      ),
    ];
  }
}
