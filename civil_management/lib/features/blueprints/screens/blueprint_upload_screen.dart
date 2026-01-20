import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../projects/data/models/project_model.dart';
import '../providers/blueprints_provider.dart';

class BlueprintUploadScreen extends ConsumerStatefulWidget {
  final ProjectModel project;

  const BlueprintUploadScreen({super.key, required this.project});

  @override
  ConsumerState<BlueprintUploadScreen> createState() => _BlueprintUploadScreenState();
}

class _BlueprintUploadScreenState extends ConsumerState<BlueprintUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _folderNameController = TextEditingController();

  File? _selectedFile;
  bool _isAdminOnly = false;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uploaderId = ref.read(currentUserProvider)!.id;

    try {
      await ref.read(blueprintRepositoryProvider).uploadBlueprint(
        projectId: widget.project.id,
        folderName: _folderNameController.text.trim(),
        isAdminOnly: _isAdminOnly,
        file: _selectedFile!,
        uploaderId: uploaderId,
      );

      // Invalidate providers to refresh the lists
      ref.invalidate(blueprintFoldersProvider);
      ref.invalidate(blueprintFilesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Blueprint uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Blueprint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // File Picker
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('Select File'),
              ),
              if (_selectedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Selected: ${_selectedFile!.path.split('/').last}',
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),

              // Folder Name
              TextFormField(
                controller: _folderNameController,
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                  hintText: 'e.g., Floor Plans, Electrical',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Folder name cannot be empty.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Admin Only Switch
              SwitchListTile(
                title: const Text('Admin Only'),
                subtitle: const Text('If enabled, only admins can see this file.'),
                value: _isAdminOnly,
                onChanged: (value) {
                  setState(() {
                    _isAdminOnly = value;
                  });
                },
                secondary: const Icon(Icons.lock_outline),
              ),
              const SizedBox(height: 32),

              // Upload Button
              AppButton(
                text: 'Upload Blueprint',
                isLoading: _isLoading,
                onPressed: _handleUpload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
