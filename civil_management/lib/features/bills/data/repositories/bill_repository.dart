import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/bill_model.dart';

class BillRepository {
  final SupabaseClient _client;

  BillRepository({SupabaseClient? client}) : _client = client ?? supabase;

  /// Fetch bills with optional filters
  Future<List<BillModel>> getBills({
    String? projectId,
    BillStatus? status,
  }) async {
    try {
      // Explicitly specify the foreign key constraint for created_by relation
      var query = _client.from('bills').select('*, projects(name), user_profiles:user_profiles!bills_created_by_fkey(full_name)');

      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }

      if (status != null) {
        query = query.eq('status', status.value);
      }
      
      // Default sort by date desc
      final orderedQuery = query.order('bill_date', ascending: false);

      final response = await orderedQuery;
      return (response as List).map((json) => BillModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to load bills: $e');
    }
  }

  /// Create a new bill with optional receipt upload
  Future<BillModel> createBill(BillModel bill, {List<int>? receiptBytes, String? receiptName}) async {
    try {
      String? receiptUrl;

      // Upload receipt if provided
      if (receiptBytes != null && receiptName != null) {
        final fileExt = receiptName.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = 'receipts/$fileName';

        await _client.storage.from('receipts').uploadBinary(
              filePath,
              Uint8List.fromList(receiptBytes), 
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );

        // Get public URL
        receiptUrl = _client.storage.from('receipts').getPublicUrl(filePath);
      }

      final billData = bill.copyWith(receiptUrl: receiptUrl).toJson();
      // Remove null fields to let DB defaults work
      billData.removeWhere((key, value) => value == null);

      final response = await _client
          .from('bills')
          .insert(billData)
          .select('*, projects(name), user_profiles:user_profiles!bills_created_by_fkey(full_name)')
          .single();

      return BillModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to create bill: $e');
    }
  }

  /// Update bill status
  Future<void> updateStatus(String id, BillStatus status) async {
    try {
      await _client
          .from('bills')
          .update({'status': status.value}).eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }
}
