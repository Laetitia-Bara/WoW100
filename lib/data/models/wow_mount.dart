class WowMount {
  final int id;
  final String name;

  const WowMount({required this.id, required this.name});

  factory WowMount.fromJson(Map<String, dynamic> json) {
    return WowMount(id: json['id'], name: json['name']);
  }
}
