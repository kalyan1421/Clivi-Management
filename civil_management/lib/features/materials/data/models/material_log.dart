class MaterialLog {
  final String id;
  final String projectId;
  final String itemId;
  final String logType; // 'inward', 'outward'
  final double quantity;
  final String? activity;
  final String? notes;
  final String? loggedBy;
  final DateTime loggedAt;
  
  // Joined
  final String? itemName;
  final String? itemUnit;
  final double? billAmount;
  final String? paymentType;

  const MaterialLog({
    required this.id,
    required this.projectId,
    required this.itemId,
    required this.logType,
    required this.quantity,
    this.activity,
    this.notes,
    this.loggedBy,
    required this.loggedAt,
    this.itemName,
    this.itemUnit,
    this.billAmount,
    this.paymentType,
  });

  factory MaterialLog.fromJson(Map<String, dynamic> json) {
    return MaterialLog(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      itemId: json['item_id'] as String,
      logType: json['log_type'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      activity: json['activity'] as String?,
      notes: json['notes'] as String?,
      loggedBy: json['logged_by'] as String?,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      
      itemName: json['stock_item'] != null ? json['stock_item']['name'] as String? : null,
      itemUnit: json['stock_item'] != null ? json['stock_item']['unit'] as String? : null,
      
      billAmount: (json['bill_amount'] as num?)?.toDouble(),
      paymentType: json['payment_type'] as String?,
    );
  }
}
