import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/data/models/achievement_faction_equivalents.dart';

void main() {
  test('expands Horde and Alliance quest achievement equivalents', () {
    expect(
      AchievementFactionEquivalents.expand({4976}),
      containsAll([4925, 4976]),
    );
    expect(
      AchievementFactionEquivalents.expand({4925}),
      containsAll([4925, 4976]),
    );
    expect(
      AchievementFactionEquivalents.expand({4980}),
      containsAll([4936, 4980]),
    );
  });

  test('does not change unrelated achievement ids', () {
    expect(AchievementFactionEquivalents.expand({845}), {845});
  });

  test('detects equivalent faction achievements', () {
    expect(AchievementFactionEquivalents.areEquivalent(4925, 4976), isTrue);
    expect(AchievementFactionEquivalents.areEquivalent(4936, 4980), isTrue);
    expect(AchievementFactionEquivalents.areEquivalent(4925, 845), isFalse);
  });
}
