class StockItem {
  final String id;
  final String projectId;
  final String name;
  final String unit;
  final double quantity;
  final DateTime createdAt;

  const StockItem({
    required this.id,
    required this.projectId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.createdAt,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
