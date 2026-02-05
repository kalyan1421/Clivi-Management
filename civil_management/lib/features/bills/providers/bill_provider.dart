import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../data/models/bill_model.dart';
import '../data/repositories/bill_repository.dart';

// ============================================================
// REPOSITORY PROVIDER
// ============================================================

final billRepositoryProvider = Provider<BillRepository>((ref) {
  return BillRepository();
});

// ============================================================
// STREAMS (READ)
// ============================================================

/// Real-time stream of bills for a specific project
final billsStreamProvider = StreamProvider.family<List<BillModel>, String>((ref, projectId) {
  final repository = ref.watch(billRepositoryProvider);
  return repository.streamBillsByProject(projectId);
});

// ============================================================
// CONTROLLER (WRITE)
// ============================================================

class BillController extends StateNotifier<AsyncValue<void>> {
  final BillRepository _repository;

  BillController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> createBill({
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
    state = const AsyncValue.loading();
    try {
      await _repository.createBill(
        projectId: projectId,
        title: title,
        amount: amount,
        billType: billType,
        description: description,
        vendorName: vendorName,
        paymentType: paymentType,
        paymentStatus: paymentStatus,
        receiptBytes: receiptBytes,
        receiptName: receiptName,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> approveBill(String billId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.approveBill(billId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectBill(String billId, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectBill(billId, reason: reason);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBill(String billId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteBill(billId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Controller Provider
final billControllerProvider = StateNotifierProvider<BillController, AsyncValue<void>>((ref) {
  return BillController(ref.watch(billRepositoryProvider));
});
