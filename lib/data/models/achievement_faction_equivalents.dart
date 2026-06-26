class AchievementFactionEquivalents {
  static const List<Set<int>> _groups = [
    {4925, 4976},
    {4929, 4978},
    {4932, 4979},
    {4937, 4981},
    {6300, 6534},
    {6535, 6536},
    {6537, 6538},
    {7448, 7449},
    {8030, 8031},
    {8927, 8928},
    {9132, 9210},
    {9477, 9478},
    {9508, 9738},
    {10349, 10350},
    {10749, 11173},
    {12867, 12896},
    {12869, 12898},
    {12870, 12899},
    {13761, 13762},
    {14149, 14150},
    {18858, 18859},
  ];

  static final Map<int, Set<int>> _equivalentsById = {
    for (final group in _groups)
      for (final id in group) id: group,
  };

  static Set<int> expand(Iterable<int> achievementIds) {
    final expanded = <int>{};

    for (final id in achievementIds) {
      expanded.addAll(_equivalentsById[id] ?? {id});
    }

    return expanded;
  }

  static bool containsEquivalent(Set<int> achievementIds, int? achievementId) {
    if (achievementId == null) return false;

    return expand(achievementIds).contains(achievementId);
  }

  static bool areEquivalent(int? left, int? right) {
    if (left == null || right == null) return false;
    if (left == right) return true;

    return _equivalentsById[left]?.contains(right) ?? false;
  }
}
