import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/labour_model.dart';
import '../models/labour_attendance_model.dart';

class LabourRepository {
  final SupabaseClient _client;

  LabourRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  // ==================== LABOUR CRUD ====================

  /// Get all labour for a project
  Future<List<LabourModel>> getLabourByProject(String projectId) async {
    final response = await _client
        .from('labour')
        .select('*, projects(name)')
        .eq('project_id', projectId)
        .order('name');

    return (response as List)
        .map((json) => LabourModel.fromJson(json))
        .toList();
  }

  /// Get active labour for a project
  Future<List<LabourModel>> getActiveLabourByProject(String projectId) async {
    final response = await _client
        .from('labour')
        .select('*, projects(name)')
        .eq('project_id', projectId)
        .eq('status', 'active')
        .order('name');

    return (response as List)
        .map((json) => LabourModel.fromJson(json))
        .toList();
  }

  /// Add new labour
  Future<LabourModel> addLabour(LabourModel labour) async {
    final response = await _client
        .from('labour')
        .insert(labour.toInsertJson())
        .select('*, projects(name)')
        .single();

    return LabourModel.fromJson(response);
  }

  /// Update labour
  Future<LabourModel> updateLabour(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('labour')
        .update(data)
        .eq('id', id)
        .select('*, projects(name)')
        .single();

    return LabourModel.fromJson(response);
  }

  /// Toggle labour status (active/inactive)
  Future<void> toggleLabourStatus(String id, LabourStatus newStatus) async {
    await _client
        .from('labour')
        .update({'status': newStatus.value})
        .eq('id', id);
  }

  // ==================== ATTENDANCE ====================

  /// Get attendance for a specific date
  Future<List<LabourAttendanceModel>> getAttendanceByDate(
    String projectId,
    DateTime date,
  ) async {
    final dateStr = date.toIso8601String().split('T')[0];

    final response = await _client
        .from('labour_attendance')
        .select('*, labour(name, phone, skill_type, daily_wage)')
        .eq('project_id', projectId)
        .eq('date', dateStr)
        .order('created_at');

    return (response as List)
        .map((json) => LabourAttendanceModel.fromJson(json))
        .toList();
  }

  /// Get all labour with today's attendance status (for marking)
  Future<List<Map<String, dynamic>>> getLabourWithAttendance(
    String projectId,
    DateTime date,
  ) async {
    final dateStr = date.toIso8601String().split('T')[0];

    // Get all active labour
    final labourList = await getActiveLabourByProject(projectId);

    // Get existing attendance for this date
    final attendance = await getAttendanceByDate(projectId, date);
    final attendanceMap = {for (var a in attendance) a.labourId: a};

    // Combine
    return labourList.map((labour) {
      return {'labour': labour, 'attendance': attendanceMap[labour.id]};
    }).toList();
  }

  /// Mark attendance (upsert)
  Future<LabourAttendanceModel> markAttendance(
    LabourAttendanceModel attendance,
  ) async {
    final response = await _client
        .from('labour_attendance')
        .upsert(attendance.toUpsertJson(), onConflict: 'labour_id,date')
        .select('*, labour(name, phone, skill_type, daily_wage)')
        .single();

    return LabourAttendanceModel.fromJson(response);
  }

  /// Bulk mark attendance for multiple workers
  Future<void> bulkMarkAttendance(
    List<LabourAttendanceModel> attendances,
  ) async {
    final data = attendances.map((a) => a.toUpsertJson()).toList();

    await _client
        .from('labour_attendance')
        .upsert(data, onConflict: 'labour_id,date');
  }

  /// Get attendance summary for a date range
  Future<Map<String, dynamic>> getAttendanceSummary(
    String projectId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _client
        .from('labour_attendance')
        .select('status')
        .eq('project_id', projectId)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    final records = response as List;

    int present = 0;
    int absent = 0;
    int halfDay = 0;

    for (final record in records) {
      switch (record['status']) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'half_day':
          halfDay++;
          break;
      }
    }

    return {
      'present': present,
      'absent': absent,
      'halfDay': halfDay,
      'total': records.length,
    };
  }
}
