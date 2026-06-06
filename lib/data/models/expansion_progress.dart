import 'tracking_category.dart';
import 'wow_expansion.dart';

class ExpansionProgress {
  final WowExpansion expansion;

  final Map<TrackingCategory, int> completed;

  final Map<TrackingCategory, int> total;

  const ExpansionProgress({
    required this.expansion,
    required this.completed,
    required this.total,
  });

  double get completionRate {
    final completedSum = completed.values.fold(0, (a, b) => a + b);

    final totalSum = total.values.fold(0, (a, b) => a + b);

    if (totalSum == 0) return 0;

    return completedSum / totalSum;
  }

  double completionRateFor(Set<TrackingCategory> categories) {
    final completedSum = categories.fold(
      0,
      (sum, category) => sum + (completed[category] ?? 0),
    );
    final totalSum = categories.fold(
      0,
      (sum, category) => sum + (total[category] ?? 0),
    );

    if (totalSum == 0) return 0;

    return completedSum / totalSum;
  }
}
