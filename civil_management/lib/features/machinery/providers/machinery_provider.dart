import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/machinery_model.dart';
import '../data/models/machinery_log_model.dart';
import '../data/repositories/machinery_repository.dart';
import '../../../../core/config/supabase_client.dart';

final machineryRepositoryProvider = Provider<MachineryRepository>((ref) {
  return MachineryRepository(supabase);
});

// Logs Stream
final machineryLogsStreamProvider = StreamProvider.family<List<MachineryLog>, String>((ref, projectId) {
  final repo = ref.watch(machineryRepositoryProvider);
  return repo.streamMachineryLogsByProject(projectId);
});

// Machinery List (for dropdown)
final machineryListProvider = FutureProvider<List<MachineryModel>>((ref) async {
  final repo = ref.watch(machineryRepositoryProvider);
  return repo.getAllMachinery();
});

// Controller
class MachineryController extends StateNotifier<AsyncValue<void>> {
  final MachineryRepository _repository;

  MachineryController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> logUsage({
    required String projectId,
    required String machineryId,
    required String workActivity,
    required double startReading,
    required double endReading,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.logMachineryUsage(
        projectId: projectId,
        machineryId: machineryId,
        workActivity: workActivity,
        startReading: startReading,
        endReading: endReading,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final machineryControllerProvider = StateNotifierProvider<MachineryController, AsyncValue<void>>((ref) {
  return MachineryController(ref.watch(machineryRepositoryProvider));
});
