class WowPet {
  final int id;
  final String name;

  const WowPet({required this.id, required this.name});

  factory WowPet.fromJson(Map<String, dynamic> json) {
    return WowPet(id: json['id'] as int, name: json['name'] as String);
  }
}
