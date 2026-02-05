import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../data/models/report_models.dart';
import '../data/repositories/report_repository.dart';

// ============================================================
// REPOSITORY PROVIDER
// ============================================================

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

// ============================================================
// STATE
// ============================================================

class ReportState {
  final FinancialStats stats;
  final TimePeriod selectedPeriod;
  final bool isLoading;
  final String? error;

  const ReportState({
    this.stats = FinancialStats.empty,
    this.selectedPeriod = TimePeriod.monthly,
    this.isLoading = false,
    this.error,
  });

  ReportState copyWith({
    FinancialStats? stats,
    TimePeriod? selectedPeriod,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ReportState(
      stats: stats ?? this.stats,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ============================================================
// NOTIFIER
// ============================================================

class ReportNotifier extends StateNotifier<ReportState> {
  final ReportRepository _repository;

  ReportNotifier(this._repository) : super(const ReportState()) {
    loadReports();
  }

  /// Load reports based on current filter
  Future<void> loadReports({String? projectId}) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final stats = await _repository.getFinancialMetrics(
        period: state.selectedPeriod,
        projectId: projectId,
      );

      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ExceptionHandler.getMessage(e),
      );
    }
  }

  /// Change time period filter
  void setPeriod(TimePeriod period, {String? projectId}) {
    if (state.selectedPeriod == period) return;
    
    state = state.copyWith(selectedPeriod: period);
    loadReports(projectId: projectId);
  }
  
  /// Refresh data
  Future<void> refresh({String? projectId}) async {
    await loadReports(projectId: projectId);
  }
}

// ============================================================
// PROVIDER
// ============================================================

/// Reports provider (optionally qualified by project ID)
/// Since reports screen is global for now, we don't need family yet, 
/// but keeping structure flexible.
final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return ReportNotifier(repository);
});
