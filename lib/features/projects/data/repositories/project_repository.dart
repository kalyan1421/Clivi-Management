import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/project_model.dart';

/// Repository for project-related Supabase operations
class ProjectRepository {
  final SupabaseClient _client;

  ProjectRepository({SupabaseClient? client}) : _client = client ?? supabase;

  // ============================================================
  // PROJECT CRUD OPERATIONS
  // ============================================================

  /// Get all projects with optional search and pagination
  Future<List<ProjectModel>> getProjects({
    String? search,
    ProjectStatus? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _client
          .from('projects')
          .select('''
            *,
            project_assignments(
              id,
              user_id,
              assigned_role,
              assigned_at,
              user_profiles(id, full_name, phone)
            )
          ''');

      // Apply search filter
      if (search != null && search.isNotEmpty) {
        query = query.or('name.ilike.%$search%,location.ilike.%$search%');
      }

      // Apply status filter
      if (status != null) {
        query = query.eq('status', status.value);
      }

      // Apply pagination and ordering
      final response = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return (response as List)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch projects: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get projects assigned to a specific site manager
  Future<List<ProjectModel>> getAssignedProjects(String userId) async {
    try {
      // First get project IDs assigned to this user
      final assignmentsResponse = await _client
          .from('project_assignments')
          .select('project_id')
          .eq('user_id', userId);

      final projectIds = (assignmentsResponse as List)
          .map((a) => a['project_id'] as String)
          .toList();

      if (projectIds.isEmpty) {
        return [];
      }

      // Then fetch those projects
      final response = await _client
          .from('projects')
          .select('''
            *,
            project_assignments(
              id,
              user_id,
              assigned_role,
              assigned_at,
              user_profiles(id, full_name, phone)
            )
          ''')
          .inFilter('id', projectIds)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch assigned projects: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get single project by ID
  Future<ProjectModel> getProjectById(String projectId) async {
    try {
      final response = await _client
          .from('projects')
          .select('''
            *,
            project_assignments(
              id,
              user_id,
              assigned_role,
              assigned_at,
              user_profiles(id, full_name, phone)
            )
          ''')
          .eq('id', projectId)
          .single();

      return ProjectModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch project: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Create new project
  Future<ProjectModel> createProject(ProjectModel project, String userId) async {
    try {
      final response = await _client
          .from('projects')
          .insert(project.toInsertJson(userId))
          .select()
          .single();

      logger.i('Project created: ${response['name']}');
      return ProjectModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to create project: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Update existing project
  Future<ProjectModel> updateProject(String projectId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('projects')
          .update(updates)
          .eq('id', projectId)
          .select()
          .single();

      logger.i('Project updated: ${response['name']}');
      return ProjectModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to update project: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Delete project
  Future<void> deleteProject(String projectId) async {
    try {
      await _client.from('projects').delete().eq('id', projectId);
      logger.i('Project deleted: $projectId');
    } on PostgrestException catch (e) {
      logger.e('Failed to delete project: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  // ============================================================
  // PROJECT ASSIGNMENTS
  // ============================================================

  /// Get all site managers (for assignment dropdown)
  Future<List<SiteManagerModel>> getSiteManagers() async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('role', 'site_manager')
          .order('full_name');

      return (response as List)
          .map((json) => SiteManagerModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch site managers: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get site managers with assignment status for a project
  Future<List<SiteManagerModel>> getSiteManagersWithAssignmentStatus(String projectId) async {
    try {
      // Get all site managers
      final managersResponse = await _client
          .from('user_profiles')
          .select()
          .eq('role', 'site_manager')
          .order('full_name');

      // Get current assignments for this project
      final assignmentsResponse = await _client
          .from('project_assignments')
          .select('user_id')
          .eq('project_id', projectId);

      final assignedUserIds = (assignmentsResponse as List)
          .map((a) => a['user_id'] as String)
          .toSet();

      return (managersResponse as List)
          .map((json) => SiteManagerModel.fromJson(
                json,
                isAssigned: assignedUserIds.contains(json['id']),
              ))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch site managers: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Assign site manager to project
  Future<void> assignManager({
    required String projectId,
    required String userId,
    required String assignedBy,
    String assignedRole = 'manager',
  }) async {
    try {
      await _client.from('project_assignments').insert({
        'project_id': projectId,
        'user_id': userId,
        'assigned_role': assignedRole,
        'assigned_by': assignedBy,
      });

      logger.i('Manager assigned to project: $userId -> $projectId');
    } on PostgrestException catch (e) {
      logger.e('Failed to assign manager: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Remove site manager from project
  Future<void> removeAssignment({
    required String projectId,
    required String userId,
  }) async {
    try {
      await _client
          .from('project_assignments')
          .delete()
          .eq('project_id', projectId)
          .eq('user_id', userId);

      logger.i('Manager removed from project: $userId <- $projectId');
    } on PostgrestException catch (e) {
      logger.e('Failed to remove assignment: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Update multiple assignments (bulk assign/unassign)
  Future<void> updateAssignments({
    required String projectId,
    required List<String> assignedUserIds,
    required String assignedBy,
  }) async {
    try {
      // Get current assignments
      final currentResponse = await _client
          .from('project_assignments')
          .select('user_id')
          .eq('project_id', projectId);

      final currentUserIds = (currentResponse as List)
          .map((a) => a['user_id'] as String)
          .toSet();

      final newUserIds = assignedUserIds.toSet();

      // Users to add
      final toAdd = newUserIds.difference(currentUserIds);
      // Users to remove
      final toRemove = currentUserIds.difference(newUserIds);

      // Remove unassigned users
      if (toRemove.isNotEmpty) {
        await _client
            .from('project_assignments')
            .delete()
            .eq('project_id', projectId)
            .inFilter('user_id', toRemove.toList());
      }

      // Add newly assigned users
      if (toAdd.isNotEmpty) {
        final insertData = toAdd
            .map((userId) => {
                  'project_id': projectId,
                  'user_id': userId,
                  'assigned_role': 'manager',
                  'assigned_by': assignedBy,
                })
            .toList();

        await _client.from('project_assignments').insert(insertData);
      }

      logger.i('Assignments updated for project: $projectId');
    } on PostgrestException catch (e) {
      logger.e('Failed to update assignments: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get project statistics (for dashboard)
  Future<Map<String, int>> getProjectStats() async {
    try {
      final response = await _client
          .from('projects')
          .select('status');

      final stats = <String, int>{
        'total': 0,
        'planning': 0,
        'in_progress': 0,
        'on_hold': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (final row in response as List) {
        final status = row['status'] as String?;
        stats['total'] = (stats['total'] ?? 0) + 1;
        if (status != null && stats.containsKey(status)) {
          stats[status] = (stats[status] ?? 0) + 1;
        }
      }

      return stats;
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch project stats: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }
}
