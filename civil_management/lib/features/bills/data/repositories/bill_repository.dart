import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/bill_model.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class BillRepository {
  final SupabaseClient _client;

  BillRepository({SupabaseClient? client}) : _client = client ?? supabase;

  /// Get bills for a specific project (NOT all bills)
  Future<List<BillModel>> getBillsByProject(String projectId, {String? status}) async {
    try {
      var query = _client
          .from('bills')
          .select('''
            *,
            creator:user_profiles!bills_created_by_fkey(id, full_name, email),
            approver:user_profiles!bills_approved_by_fkey(id, full_name, email),
            project:projects!bills_project_id_fkey(id, name)
          ''')
          .eq('project_id', projectId);

      if (status != null) {
        query = query.eq('status', status);
      }

      // Apply sort order at the end
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => BillModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to fetch bills: $e');
    }
  }

  /// Get pending bills with pagination
  Future<List<BillModel>> getPendingBills({
    required String projectId,
    required int offset,
    required int limit,
  }) async {
    try {
      final response = await _client
          .from('bills')
          .select('''
            *,
            creator:user_profiles!bills_created_by_fkey(id, full_name, email),
            approver:user_profiles!bills_approved_by_fkey(id, full_name, email),
            project:projects!bills_project_id_fkey(id, name)
          ''')
          .eq('project_id', projectId)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => BillModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to fetch pending bills: $e');
    }
  }

  /// Create a new bill
  Future<BillModel> createBill({
    required String projectId,
    required String title,
    required double amount,
    required String billType,
    String? description,
    String? vendorName,
    String? paymentType,
    String? paymentStatus,
    List<int>? receiptBytes,
    String? receiptName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

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

      final data = {
        'project_id': projectId,
        'title': title,
        'amount': amount,
        'bill_type': billType,
        'description': description,
        'vendor_name': vendorName,
        'payment_type': paymentType,
        'payment_status': paymentStatus ?? 'need_to_pay',
        'status': 'pending',
        'created_by': userId,
        'raised_by': userId,
        'receipt_url': receiptUrl,
        'bill_date': DateTime.now().toIso8601String().split('T').first,
      };

      final response = await _client
          .from('bills')
          .insert(data)
          .select('''
            *,
            creator:user_profiles!bills_created_by_fkey(id, full_name, email)
          ''')
          .single();

      return BillModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to create bill: $e');
    }
  }

  /// Update a bill (only pending bills can be updated by site managers)
  Future<BillModel> updateBill(String billId, Map<String, dynamic> updates) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    
    try {
      final response = await _client
          .from('bills')
          .update(updates)
          .eq('id', billId)
          .select('''
            *,
            creator:user_profiles!bills_created_by_fkey(id, full_name, email),
            approver:user_profiles!bills_approved_by_fkey(id, full_name, email)
          ''')
          .single();

      return BillModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to update bill: $e');
    }
  }

  /// Approve a bill (Admin only)
  Future<BillModel> approveBill(String billId) async {
    final userId = _client.auth.currentUser?.id;
    
    try {
      final response = await _client
          .from('bills')
          .update({
            'status': 'approved',
            'approved_by': userId,
            'approved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', billId)
          .select('''
            *,
            creator:user_profiles!bills_created_by_fkey(id, full_name, email),
            approver:user_profiles!bills_approved_by_fkey(id, full_name, email)
          ''')
          .single();

      return BillModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to approve bill: $e');
    }
  }

  /// Reject a bill (Admin only)
  Future<BillModel> rejectBill(String billId, {String? reason}) async {
    final userId = _client.auth.currentUser?.id;
    
    try {
      final response = await _client
          .from('bills')
          .update({
            'status': 'rejected',
            'approved_by': userId,
            'approved_at': DateTime.now().toIso8601String(),
            'description': reason, // Store rejection reason if description field is used for it, or check if 'rejection_reason' column exists? Guide mapped it to 'description'.
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', billId)
          .select()
          .single();

      return BillModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to reject bill: $e');
    }
  }

  /// Delete a bill
  Future<void> deleteBill(String billId) async {
    try {
      await _client.from('bills').delete().eq('id', billId);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      throw Exception('Failed to delete bill: $e');
    }
  }

  /// Stream bills for real-time updates
  Stream<List<BillModel>> streamBillsByProject(String projectId) {
    return _client
        .from('bills')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => BillModel.fromJson(json)).toList());
  }
}
