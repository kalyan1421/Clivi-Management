import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../providers/blueprints_provider.dart';

class BlueprintFilesScreen extends ConsumerWidget {
  final String projectId;
  final String folderName;

  const BlueprintFilesScreen({
    super.key,
    required this.projectId,
    required this.folderName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(
      blueprintFilesProvider(projectId: projectId, folderName: folderName),
    );

    return Scaffold(
      appBar: AppBar(title: Text(folderName)),
      body: filesAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, stack) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(
            blueprintFilesProvider(
              projectId: projectId,
              folderName: folderName,
            ),
          ),
        ),
        data: (files) {
          if (files.isEmpty) {
            return const Center(child: Text('No files found in this folder.'));
          }
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                leading: Icon(
                  file.fileName.endsWith('.pdf')
                      ? Icons.picture_as_pdf
                      : Icons.image,
                ),
                title: Text(file.fileName),
                subtitle: Text('Uploaded: ${file.createdAt.toLocal()}'),
                trailing: file.isAdminOnly ? const Icon(Icons.lock) : null,
                onTap: () {
                  context.go(
                    '/projects/$projectId/blueprints/$folderName/${file.id}',
                    extra: file,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
