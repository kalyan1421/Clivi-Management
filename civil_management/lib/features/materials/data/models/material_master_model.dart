
class MaterialMaster {
  final String id;
  final String name;

  MaterialMaster({required this.id, required this.name});

  factory MaterialMaster.fromJson(Map<String, dynamic> json) {
    return MaterialMaster(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
