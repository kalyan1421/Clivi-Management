import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../data/models/bill_model.dart';
import '../data/repositories/bill_repository.dart';

// ============================================================
// REPO PROVIDER
// ============================================================

final billRepositoryProvider = Provider<BillRepository>((ref) {
  return BillRepository();
});

// ============================================================
// STATE
// ============================================================

class BillListState {
  final List<BillModel> bills;
  final bool isLoading;
  final String? error;

  const BillListState({
    this.bills = const [],
    this.isLoading = false,
    this.error,
  });

  BillListState copyWith({
    List<BillModel>? bills,
    bool? isLoading,
    String? error,
  }) {
    return BillListState(
      bills: bills ?? this.bills,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================================
// NOTIFIERS
// ============================================================

class BillListNotifier extends StateNotifier<BillListState> {
  final BillRepository _repository;

  BillListNotifier(this._repository) : super(const BillListState());

  Future<void> loadBills({String? projectId, BillStatus? status}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final bills = await _repository.getBills(
        projectId: projectId,
        status: status,
      );
      state = state.copyWith(bills: bills, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ExceptionHandler.getMessage(e),
      );
    }
  }

  Future<void> refresh({String? projectId, BillStatus? status}) async {
    await loadBills(projectId: projectId, status: status);
  }
}

class CreateBillNotifier extends StateNotifier<AsyncValue<void>> {
  final BillRepository _repository;

  CreateBillNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> createBill(BillModel bill, {List<int>? receiptBytes, String? receiptName}) async {
    try {
      state = const AsyncValue.loading();
      await _repository.createBill(bill, receiptBytes: receiptBytes, receiptName: receiptName);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for the list of bills
final billListProvider = StateNotifierProvider<BillListNotifier, BillListState>(
  (ref) => BillListNotifier(ref.watch(billRepositoryProvider)),
);

/// Provider for creating bills
final createBillProvider =
    StateNotifierProvider<CreateBillNotifier, AsyncValue<void>>(
      (ref) => CreateBillNotifier(ref.watch(billRepositoryProvider)),
    );
