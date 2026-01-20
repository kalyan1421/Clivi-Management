import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/blueprint_model.dart';
import '../data/repositories/blueprint_repository.dart';

part 'blueprints_provider.g.dart';

@riverpod
BlueprintRepository blueprintRepository(BlueprintRepositoryRef ref) {
  // In a real app, you might get the client from another provider
  return BlueprintRepository();
}

@riverpod
Future<List<BlueprintFolder>> blueprintFolders(
  BlueprintFoldersRef ref,
  String projectId,
) {
  final repository = ref.watch(blueprintRepositoryProvider);
  return repository.getBlueprintFolders(projectId);
}

@riverpod
Future<List<Blueprint>> blueprintFiles(
  BlueprintFilesRef ref, {
  required String projectId,
  required String folderName,
}) {
  final repository = ref.watch(blueprintRepositoryProvider);
  return repository.getBlueprintFiles(projectId, folderName);
}
