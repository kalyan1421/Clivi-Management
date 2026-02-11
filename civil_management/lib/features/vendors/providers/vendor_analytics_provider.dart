import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/vendor_analytics_repository.dart';
import '../data/models/vendor_summary_models.dart';

// Repository Provider
final vendorAnalyticsRepositoryProvider = Provider<VendorAnalyticsRepository>((ref) {
  final supabase = Supabase.instance.client;
  return VendorAnalyticsRepository(supabase);
});

// Vendor Payment Summaries Provider
final vendorPaymentSummariesProvider = FutureProvider<List<VendorPaymentSummary>>((ref) async {
  final repo = ref.watch(vendorAnalyticsRepositoryProvider);
  return repo.getVendorPaymentSummaries();
});

// Specific Vendor Payment Summary Provider
final vendorPaymentSummaryProvider = FutureProvider.family<VendorPaymentSummary?, String>((ref, vendorId) async {
  final repo = ref.watch(vendorAnalyticsRepositoryProvider);
  return repo.getVendorPaymentSummary(vendorId);
});

// Vendor Stock Summary Provider
final vendorStockSummaryProvider = FutureProvider.family<List<VendorStockSummary>, String>((ref, vendorId) async {
  final repo = ref.watch(vendorAnalyticsRepositoryProvider);
  return repo.getVendorStockSummary(vendorId);
});

// All Vendor Stock Summaries Provider
final allVendorStockSummariesProvider = FutureProvider<List<VendorStockSummary>>((ref) async {
  final repo = ref.watch(vendorAnalyticsRepositoryProvider);
  return repo.getAllVendorStockSummaries();
});

// Project Inventory Summary Provider
final projectInventorySummaryProvider = FutureProvider.family<List<ProjectInventorySummary>, String>((ref, projectId) async {
  final repo = ref.watch(vendorAnalyticsRepositoryProvider);
  return repo.getProjectInventorySummary(projectId);
});

// All Projects Inventory Summary Provider
final allProjectsInventorySummaryProvider = FutureProvider<List<ProjectInventorySummary>>((ref) async {
  final repo = ref.watch(vendorAnalyticsRepositoryProvider);
  return repo.getAllProjectsInventorySummary();
});

// Top vendors across all projects (admin only)
final vendorOverviewProvider = FutureProvider<List<VendorOverview>>((ref) async {
  final repo = ref.watch(vendorAnalyticsRepositoryProvider);
  return repo.getVendorOverview();
});

// Vendor material totals with optional material filter
class VendorTotalsRequest {
  final String vendorId;
  final String? materialName;
  const VendorTotalsRequest(this.vendorId, {this.materialName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorTotalsRequest &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          materialName == other.materialName;

  @override
  int get hashCode => vendorId.hashCode ^ (materialName?.hashCode ?? 0);
}

final vendorMaterialTotalsProvider =
    FutureProvider.family<List<VendorMaterialTotal>, VendorTotalsRequest>((ref, request) async {
  final repo = ref.watch(vendorAnalyticsRepositoryProvider);
  return repo.getVendorMaterialTotals(
    vendorId: request.vendorId,
    materialName: request.materialName,
  );
});
