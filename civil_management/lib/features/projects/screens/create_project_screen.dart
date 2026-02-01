import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_widget.dart';
import '../data/models/project_model.dart';
import '../providers/project_provider.dart';

/// Create/Edit Project Screen
class CreateProjectScreen extends ConsumerStatefulWidget {
  final String? projectId; // null for create, id for edit

  const CreateProjectScreen({super.key, this.projectId});

  bool get isEditing => projectId != null;

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();

  ProjectStatus _selectedStatus = ProjectStatus.planning;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadProjectData();
    }
  }

  void _loadProjectData() {
    // Load existing project data for editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(projectDetailProvider(widget.projectId!));
      final project = state.project;
      if (project != null) {
        _nameController.text = project.name;
        _descriptionController.text = project.description ?? '';
        _locationController.text = project.location ?? '';
        _budgetController.text = project.budget?.toStringAsFixed(0) ?? '';
        setState(() {
          _selectedStatus = project.status;
          _startDate = project.startDate;
          _endDate = project.endDate;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final project = ProjectModel(
        id: widget.projectId ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        budget: _budgetController.text.trim().isEmpty
            ? null
            : double.tryParse(_budgetController.text.trim()),
      );

      if (widget.isEditing) {
        // Update existing project
        final success = await ref
            .read(projectDetailProvider(widget.projectId!).notifier)
            .updateProject(project.toJson());

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else {
        // Create new project
        final created = await ref
            .read(createProjectProvider.notifier)
            .createProject(project);

        if (created != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        // Reset end date if it's before start date
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for errors from provider
    final createState = ref.watch(createProjectProvider);
    if (createState.error != null && _errorMessage == null) {
      _errorMessage = createState.error;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.isEditing ? 'Edit Project' : 'Create Project'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error Message
              if (_errorMessage != null) ...[
                InlineErrorWidget(message: _errorMessage!),
                const SizedBox(height: 16),
              ],

              // Project Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  hintText: 'Enter project name',
                  prefixIcon: Icon(Icons.business),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Project name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter project description',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter project location',
                  prefixIcon: Icon(Icons.location_on),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Status Dropdown
              DropdownButtonFormField<ProjectStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: ProjectStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(status.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date Range
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: _selectStartDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DateField(
                      label: 'End Date',
                      date: _endDate,
                      onTap: _selectEndDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Budget
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget',
                  hintText: 'Enter project budget',
                  prefixIcon: Icon(Icons.currency_rupee),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              AppButton(
                text: widget.isEditing ? 'Update Project' : 'Create Project',
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                icon: widget.isEditing ? Icons.save : Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return AppColors.info;
      case ProjectStatus.inProgress:
        return AppColors.success;
      case ProjectStatus.onHold:
        return AppColors.warning;
      case ProjectStatus.completed:
        return AppColors.primary;
      case ProjectStatus.cancelled:
        return AppColors.error;
    }
  }
}

/// Date field widget
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({required this.label, this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null
              ? '${date!.day}/${date!.month}/${date!.year}'
              : 'Select date',
          style: TextStyle(
            color: date != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
