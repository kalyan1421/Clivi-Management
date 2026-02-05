class MachineryLog {
  final String id;
  final String projectId;
  final String machineryId;
  final String workActivity;
  final double startReading;
  final double endReading;
  final double executionHours;
  final String? notes;
  final String? loggedBy;
  final DateTime loggedAt;
  
  // Joined
  final String? machineryName;
  final String? machineryType;
  final String? registrationNo;

  const MachineryLog({
    required this.id,
    required this.projectId,
    required this.machineryId,
    required this.workActivity,
    required this.startReading,
    required this.endReading,
    required this.executionHours,
    this.notes,
    this.loggedBy,
    required this.loggedAt,
    this.machineryName,
    this.machineryType,
    this.registrationNo,
  });

  factory MachineryLog.fromJson(Map<String, dynamic> json) {
    return MachineryLog(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      machineryId: json['machinery_id'] as String,
      workActivity: json['work_activity'] as String,
      startReading: (json['start_reading'] as num).toDouble(),
      endReading: (json['end_reading'] as num).toDouble(),
      executionHours: (json['execution_hours'] as num).toDouble(),
      notes: json['notes'] as String?,
      loggedBy: json['logged_by'] as String?,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      
      machineryName: json['machinery'] != null ? json['machinery']['name'] as String? : null,
      machineryType: json['machinery'] != null ? json['machinery']['type'] as String? : null,
      registrationNo: json['machinery'] != null ? json['machinery']['registration_no'] as String? : null,
    );
  }
}
