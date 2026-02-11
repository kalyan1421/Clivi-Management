import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vendor_payment_model.dart';
import '../models/material_issue_model.dart';
import '../models/vendor_summary_models.dart';

class VendorAnalyticsRepository {
  final SupabaseClient _client;

  VendorAnalyticsRepository(this._client);

  /// Get payment summary for all vendors
  Future<List<VendorPaymentSummary>> getVendorPaymentSummaries() async {
    final response = await _client
        .from('vendor_payment_summary')
        .select()
        .order('total_balance', ascending: false);
    
    return (response as List)
        .map((json) => VendorPaymentSummary.fromJson(json))
        .toList();
  }

  /// Get payment summary for a specific vendor
  Future<VendorPaymentSummary?> getVendorPaymentSummary(String vendorId) async {
    final response = await _client
        .from('vendor_payment_summary')
        .select()
        .eq('vendor_id', vendorId)
        .single();
    
    return VendorPaymentSummary.fromJson(response);
  }

  /// Get stock summary for a specific vendor
  Future<List<VendorStockSummary>> getVendorStockSummary(String vendorId) async {
    final response = await _client
        .from('vendor_stock_summary')
        .select()
        .eq('vendor_id', vendorId)
        .order('last_used_at', ascending: false);
    
    return (response as List)
        .map((json) => VendorStockSummary.fromJson(json))
        .toList();
  }

  /// Get all vendor stock summaries (for admin overview)
  Future<List<VendorStockSummary>> getAllVendorStockSummaries() async {
    final response = await _client
        .from('vendor_stock_summary')
        .select()
        .order('vendor_name');
    
    return (response as List)
        .map((json) => VendorStockSummary.fromJson(json))
        .toList();
  }

  /// Get project inventory summary
  Future<List<ProjectInventorySummary>> getProjectInventorySummary(String projectId) async {
    final response = await _client
        .from('project_inventory_summary')
        .select()
        .eq('project_id', projectId)
        .order('category')
        .order('material_name');
    
    return (response as List)
        .map((json) => ProjectInventorySummary.fromJson(json))
        .toList();
  }

  /// Get all projects inventory summary
  Future<List<ProjectInventorySummary>> getAllProjectsInventorySummary() async {
    final response = await _client
        .from('project_inventory_summary')
        .select()
        .order('project_name')
        .order('category');
    
    return (response as List)
        .map((json) => ProjectInventorySummary.fromJson(json))
        .toList();
  }

  // ============================================================
  // Vendor material aggregations (new RPCs)
  // ============================================================

  /// Top vendors by total supplied quantity across all projects (admin only)
  Future<List<VendorOverview>> getVendorOverview() async {
    dev.log('[VendorAnalytics] Calling get_vendor_overview RPC...', name: 'VendorAnalytics');
    try {
      final response = await _client.rpc('get_vendor_overview');
      dev.log('[VendorAnalytics] get_vendor_overview SUCCESS: ${(response as List).length} vendors returned', name: 'VendorAnalytics');
      return (response as List)
          .map((json) => VendorOverview.fromJson(json))
          .toList();
    } catch (e, st) {
      dev.log('[VendorAnalytics] get_vendor_overview FAILED: $e', name: 'VendorAnalytics', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Per-vendor material totals with optional material filter and project scoping
  Future<List<VendorMaterialTotal>> getVendorMaterialTotals({
    required String vendorId,
    String? materialName,
  }) async {
    dev.log('[VendorAnalytics] Calling get_vendor_material_totals RPC for vendor=$vendorId, material=$materialName', name: 'VendorAnalytics');
    try {
      final response = await _client.rpc(
        'get_vendor_material_totals',
        params: {
          'p_vendor_id': vendorId,
          if (materialName != null) 'p_material_name': materialName,
        },
      );
      dev.log('[VendorAnalytics] get_vendor_material_totals SUCCESS: ${(response as List).length} rows returned', name: 'VendorAnalytics');
      for (final row in response) {
        dev.log('[VendorAnalytics]   row => $row', name: 'VendorAnalytics');
      }
      return (response as List)
          .map((json) => VendorMaterialTotal.fromJson(json))
          .toList();
    } catch (e, st) {
      dev.log('[VendorAnalytics] get_vendor_material_totals FAILED: $e', name: 'VendorAnalytics', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Record a vendor payment
  Future<void> recordPayment({
    required String vendorId,
    String? receiptId,
    required DateTime paymentDate,
    required double paymentAmount,
    String? paymentMethod,
    String? transactionReference,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    
    await _client.from('vendor_payments').insert({
      'vendor_id': vendorId,
      'receipt_id': receiptId,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_amount': paymentAmount,
      'payment_method': paymentMethod,
      'transaction_reference': transactionReference,
      'notes': notes,
      'created_by': userId,
    });

    // Update material_receipts paid_amount if receipt_id is provided
    if (receiptId != null) {
      await _client.rpc('update_receipt_payment', params: {
        'receipt_id': receiptId,
        'payment_amt': paymentAmount,
      });
    }
  }

  /// Get payment history for a vendor
  Future<List<VendorPayment>> getVendorPayments(String vendorId) async {
    final response = await _client
        .from('vendor_payments')
        .select()
        .eq('vendor_id', vendorId)
        .order('payment_date', ascending: false);
    
    return (response as List)
        .map((json) => VendorPayment.fromJson(json))
        .toList();
  }

  /// Record material issue (outgoing stock)
  Future<void> recordMaterialIssue({
    required String projectId,
    required String issueNumber,
    required DateTime issueDate,
    String? stockItemId,
    required String materialName,
    required double quantity,
    String? unit,
    String? grade,
    String? issuedTo,
    String? purpose,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    
    await _client.from('material_issues').insert({
      'project_id': projectId,
      'issue_number': issueNumber,
      'issue_date': issueDate.toIso8601String().split('T')[0],
      'stock_item_id': stockItemId,
      'material_name': materialName,
      'quantity': quantity,
      'unit': unit,
      'grade': grade,
      'issued_to': issuedTo,
      'purpose': purpose,
      'notes': notes,
      'created_by': userId,
    });

    // Update stock_items quantity if stock_item_id is provided
    if (stockItemId != null) {
      await _client.rpc('decrease_stock_quantity', params: {
        'stock_id': stockItemId,
        'qty': quantity,
      });
    }
  }

  /// Get material issues for a project
  Future<List<MaterialIssue>> getProjectMaterialIssues(String projectId) async {
    final response = await _client
        .from('material_issues')
        .select()
        .eq('project_id', projectId)
        .order('issue_date', ascending: false);
    
    return (response as List)
        .map((json) => MaterialIssue.fromJson(json))
        .toList();
  }
}
