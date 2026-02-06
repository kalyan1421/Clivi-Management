import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/machinery_model.dart';
import '../models/machinery_log_model.dart';

class MachineryRepository {
  final SupabaseClient _client;

  MachineryRepository(this._client);

  /// Get machinery logs for a specific project
  Future<List<MachineryLog>> getMachineryLogsByProject(String projectId) async {
    final response = await _client
        .from('machinery_logs')
        .select('''
          *,
          machinery:machinery!machinery_logs_machinery_id_fkey(id, name, type, registration_no)
        ''')
        .eq('project_id', projectId)  // 👈 FILTER BY PROJECT
        .order('logged_at', ascending: false);
    
    return (response as List).map((json) => MachineryLog.fromJson(json)).toList();
  }

  /// Get ALL machinery (to select for logging)
  Future<List<MachineryModel>> getAllMachinery() async {
    final response = await _client
        .from('machinery')
        .select('*')
        .order('name');
    
    return (response as List).map((json) => MachineryModel.fromJson(json)).toList();
  }

  /// Create new machinery (Master)
  Future<void> createMachinery({
    required String name,
    required String type,
    String? registrationNo,
    required String ownershipType, // 'Own' or 'Rental'
    String status = 'active',
  }) async {
    await _client.from('machinery').insert({
      'name': name,
      'type': type,
      'registration_no': registrationNo,
      'ownership_type': ownershipType,
      'created_by': _client.auth.currentUser?.id,
    });
  }

  /// Log machinery usage (Time Based)
  Future<void> logMachineryUsageTimeBased({
    required String projectId,
    required String machineryId,
    required String workActivity,
    required DateTime logDate,
    required String startTime, // HH:mm
    required String endTime, // HH:mm
    required double totalHours,
    String? notes,
  }) async {
    await _client.from('machinery_logs').insert({
      'project_id': projectId,
      'machinery_id': machineryId,
      'log_type': 'usage',
      'work_activity': workActivity,
      'log_date': logDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'hours_used': totalHours,
      'notes': notes,
      'logged_by': _client.auth.currentUser?.id,
      'logged_at': DateTime.now().toIso8601String(),
    });

    // Update machinery total hours
    await _client.rpc('increment_machinery_hours', params: {
      'p_machinery_id': machineryId,
      'p_hours': totalHours,
    });
  }

  /// Log machinery usage (Legacy / Reading Based)
  Future<void> logMachineryUsage({
    required String projectId,
    required String machineryId,
    required String workActivity,
    required double startReading,
    required double endReading,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final executionHours = endReading - startReading;

    // Insert log
    await _client.from('machinery_logs').insert({
      'project_id': projectId,
      'machinery_id': machineryId,
      'work_activity': workActivity,
      'start_reading': startReading,
      'end_reading': endReading,
      'notes': notes, // execution_hours is generated always stored
      'logged_by': userId,
      'logged_at': DateTime.now().toIso8601String(),
    });

    // Update machinery total hours
    await _client
        .from('machinery')
        .update({
          'current_reading': endReading,
          'total_hours': (await _client.rpc('increment_machinery_hours', params: {
            'p_machinery_id': machineryId,
            'p_hours': executionHours,
          }) as num),
        })
        .eq('id', machineryId);
  }

  Stream<List<MachineryLog>> streamMachineryLogsByProject(String projectId) {
    return _client
        .from('machinery_logs')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('logged_at', ascending: false)
        .map((data) => data.map((json) => MachineryLog.fromJson(json)).toList());
  }
}
