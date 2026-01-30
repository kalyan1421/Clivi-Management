import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/project_model.dart';
import '../providers/project_provider.dart';
import 'widgets/assign_manager_sheet.dart';

/// Project detail screen with tabs
class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectDetailProvider(widget.projectId));
    final role = ref.watch(userRoleProvider);
    final isAdmin = role == UserRole.admin || role == UserRole.superAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.project?.name ?? 'Project'),
        actions: [
          if (isAdmin && state.project != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.push('/projects/${widget.projectId}/edit'),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, state.project!),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'assign',
                  child: ListTile(
                    leading: Icon(Icons.person_add),
                    title: Text('Assign Managers'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: AppColors.error),
                    title: Text(
                      'Delete Project',
                      style: TextStyle(color: AppColors.error),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.info_outline)),
            Tab(text: 'Team', icon: Icon(Icons.people_outline)),
            Tab(text: 'Activity', icon: Icon(Icons.timeline)),
          ],
        ),
      ),
      body: _buildBody(state, isAdmin),
    );
  }

  Widget _buildBody(ProjectDetailState state, bool isAdmin) {
    if (state.isLoading) {
      return const LoadingWidget(message: 'Loading project...');
    }

    if (state.error != null) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref
            .read(projectDetailProvider(widget.projectId).notifier)
            .refresh(),
      );
    }

    if (state.project == null) {
      return const AppErrorWidget(message: 'Project not found');
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _OverviewTab(project: state.project!, isAdmin: isAdmin),
        _TeamTab(
          project: state.project!,
          isAdmin: isAdmin,
          onAssignTap: () => _showAssignManagerSheet(),
        ),
        _ActivityTab(project: state.project!),
      ],
    );
  }

  void _handleMenuAction(String action, ProjectModel project) {
    switch (action) {
      case 'assign':
        _showAssignManagerSheet();
        break;
      case 'delete':
        _showDeleteConfirmation(project);
        break;
    }
  }

  void _showAssignManagerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AssignManagerSheet(projectId: widget.projectId),
    );
  }

  void _showDeleteConfirmation(ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "${project.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(projectDetailProvider(widget.projectId).notifier)
                  .deleteProject();
              if (success && mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Project deleted'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Overview tab
class _OverviewTab extends StatelessWidget {
  final ProjectModel project;
  final bool isAdmin;

  const _OverviewTab({required this.project, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(project.status),
                      color: _getStatusColor(project.status),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.status.displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(project.status),
                              ),
                        ),
                        if (project.startDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _getDateRangeText(),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (project.budget != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Budget',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          '₹${_formatBudget(project.budget!)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Details Section
          _SectionCard(
            title: 'Details',
            icon: Icons.info_outline,
            children: [
              if (project.description != null &&
                  project.description!.isNotEmpty)
                _DetailRow(
                  label: 'Description',
                  value: project.description!,
                  isMultiLine: true,
                ),
              if (project.location != null && project.location!.isNotEmpty)
                _DetailRow(
                  label: 'Location',
                  value: project.location!,
                  icon: Icons.location_on,
                ),
              _DetailRow(
                label: 'Created',
                value: _formatDate(project.createdAt),
                icon: Icons.calendar_today,
              ),
              if (project.updatedAt != null)
                _DetailRow(
                  label: 'Last Updated',
                  value: _formatDate(project.updatedAt),
                  icon: Icons.update,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Timeline Section
          _SectionCard(
            title: 'Timeline',
            icon: Icons.timeline,
            children: [
              _DetailRow(
                label: 'Start Date',
                value: project.startDate != null
                    ? _formatDate(project.startDate)
                    : 'Not set',
                icon: Icons.play_arrow,
              ),
              _DetailRow(
                label: 'End Date',
                value: project.endDate != null
                    ? _formatDate(project.endDate)
                    : 'Not set',
                icon: Icons.stop,
              ),
              if (project.startDate != null && project.endDate != null)
                _DetailRow(
                  label: 'Duration',
                  value:
                      '${project.endDate!.difference(project.startDate!).inDays} days',
                  icon: Icons.hourglass_empty,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Blueprints Section
          _SectionCard(
            title: 'Blueprints',
            icon: Icons.photo_library_outlined,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('View Project Blueprints'),
                subtitle: const Text('Access folders and files'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.go(
                  '/projects/${project.id}/blueprints',
                  extra: project,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Inventory Section
          _SectionCard(
            title: 'Inventory',
            icon: Icons.inventory_2_outlined,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.warehouse, color: Colors.blueGrey),
                title: const Text('Stock Items'),
                subtitle: const Text('Manage materials inventory'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.go(
                  '/projects/${project.id}/stock',
                  extra: project.name,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.swap_vert, color: Colors.teal),
                title: const Text('Material Log'),
                subtitle: const Text('Track inward/outward movements'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.go(
                  '/projects/${project.id}/material-log',
                  extra: project.name,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDateRangeText() {
    if (project.startDate == null) return '';
    final start = _formatDate(project.startDate);
    if (project.endDate == null) return 'Started $start';
    final end = _formatDate(project.endDate);
    return '$start - $end';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatBudget(double budget) {
    if (budget >= 10000000) {
      return '${(budget / 10000000).toStringAsFixed(1)} Cr';
    } else if (budget >= 100000) {
      return '${(budget / 100000).toStringAsFixed(1)} L';
    } else if (budget >= 1000) {
      return '${(budget / 1000).toStringAsFixed(1)} K';
    }
    return budget.toStringAsFixed(0);
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

  IconData _getStatusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return Icons.edit_note;
      case ProjectStatus.inProgress:
        return Icons.play_circle;
      case ProjectStatus.onHold:
        return Icons.pause_circle;
      case ProjectStatus.completed:
        return Icons.check_circle;
      case ProjectStatus.cancelled:
        return Icons.cancel;
    }
  }
}

/// Team tab
class _TeamTab extends StatelessWidget {
  final ProjectModel project;
  final bool isAdmin;
  final VoidCallback onAssignTap;

  const _TeamTab({
    required this.project,
    required this.isAdmin,
    required this.onAssignTap,
  });

  @override
  Widget build(BuildContext context) {
    final assignments = project.assignments ?? [];

    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'No team members assigned',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAssignTap,
                icon: const Icon(Icons.person_add),
                label: const Text('Assign Managers'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${assignments.length} Team Member${assignments.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAssignTap,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Manage'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.siteManager.withOpacity(0.1),
                    child: Text(
                      (assignment.userName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.siteManager,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(assignment.userName ?? 'Unknown User'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (assignment.userPhone != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              assignment.userPhone!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      Text(
                        'Assigned: ${_formatDate(assignment.assignedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.siteManager.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      assignment.assignedRole.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.siteManager,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Activity tab (placeholder)
class _ActivityTab extends StatelessWidget {
  final ProjectModel project;

  const _ActivityTab({required this.project});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timeline, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            'Activity Log',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

/// Section card widget
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool isMultiLine;

  const _DetailRow({
    required this.label,
    required this.value,
    this.icon,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isMultiLine
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            )
          : Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
    );
  }
}
