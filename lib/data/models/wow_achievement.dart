class WowAchievement {
  final int id;
  final String name;

  const WowAchievement({required this.id, required this.name});

  factory WowAchievement.fromJson(Map<String, dynamic> json) {
    return WowAchievement(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}
