import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stock_item.dart';
import '../models/material_log.dart';

class StockRepository {
  final SupabaseClient _client;

  StockRepository(this._client);

  /// Gets stock items for a SPECIFIC project
  Future<List<StockItem>> getStockItemsByProject(String projectId) async {
    final response = await _client
        .from('stock_items')
        .select('*')
        .eq('project_id', projectId)  // 👈 FILTER BY PROJECT
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => StockItem.fromJson(json)).toList();
  }

  /// Get material logs for a specific project
  Future<List<MaterialLog>> getMaterialLogsByProject(String projectId) async {
    final response = await _client
        .from('material_logs')
        .select('''
          *,
          stock_item:stock_items!material_logs_item_id_fkey(id, name, unit)
        ''')
        .eq('project_id', projectId)  // 👈 FILTER BY PROJECT
        .order('logged_at', ascending: false);
    
    return (response as List).map((json) => MaterialLog.fromJson(json)).toList();
  }

  /// Log material inward (received)
  Future<void> logMaterialInward({
    required String projectId,
    required String itemId,
    required double quantity,
    String? activity,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;

    // Insert log
    await _client.from('material_logs').insert({
      'project_id': projectId,
      'item_id': itemId,
      'log_type': 'inward',
      'quantity': quantity,
      'activity': activity,
      'notes': notes,
      'logged_by': userId,
      'logged_at': DateTime.now().toIso8601String(),
    });

    // Update stock quantity
    await _client.rpc('update_stock_quantity', params: {
      'p_item_id': itemId,
      'p_quantity': quantity,
      'p_operation': 'add',
    });
  }

  /// Log material outward (consumed)
  Future<void> logMaterialOutward({
    required String projectId,
    required String itemId,
    required double quantity,
    String? activity,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;

    // Insert log
    await _client.from('material_logs').insert({
      'project_id': projectId,
      'item_id': itemId,
      'log_type': 'outward',
      'quantity': quantity,
      'activity': activity,
      'notes': notes,
      'logged_by': userId,
      'logged_at': DateTime.now().toIso8601String(),
    });

    // Update stock quantity
    await _client.rpc('update_stock_quantity', params: {
      'p_item_id': itemId,
      'p_quantity': quantity,
      'p_operation': 'subtract',
    });
  }

  /// Stream stock items for real-time updates
  Stream<List<StockItem>> streamStockItemsByProject(String projectId) {
    return _client
        .from('stock_items')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => StockItem.fromJson(json)).toList());
  }
}
