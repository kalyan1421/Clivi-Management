import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/project_model.dart';
import '../providers/project_provider.dart';

/// Project list screen - shows all projects for admin, assigned projects for site manager
class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Guard against accessing position after dispose
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(projectListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectListProvider);
    final role = ref.watch(userRoleProvider);
    final isAdmin = role == UserRole.admin || role == UserRole.superAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterSheet(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search projects...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(projectListProvider.notifier).search('');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  ref.read(projectListProvider.notifier).search(value);
                },
              ),
            ),

          // Active Filter Chip
          if (state.statusFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(state.statusFilter!.displayName),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      ref
                          .read(projectListProvider.notifier)
                          .filterByStatus(null);
                    },
                  ),
                ],
              ),
            ),

          // Content
          Expanded(child: _buildContent(state, isAdmin)),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/projects/create'),
              icon: const Icon(Icons.add),
              label: const Text('New Project'),
            )
          : null,
    );
  }

  Widget _buildContent(ProjectListState state, bool isAdmin) {
    if (state.isLoading && state.projects.isEmpty) {
      return const LoadingWidget(message: 'Loading projects...');
    }

    if (state.error != null && state.projects.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(projectListProvider.notifier).refresh(),
      );
    }

    if (state.projects.isEmpty) {
      return EmptyStateWidget(
        message: isAdmin
            ? 'No projects found.\nCreate your first project!'
            : 'No projects assigned to you yet.',
        icon: Icons.folder_open,
        action: isAdmin
            ? ElevatedButton.icon(
                onPressed: () => context.push('/projects/create'),
                icon: const Icon(Icons.add),
                label: const Text('Create Project'),
              )
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(projectListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.projects.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.projects.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final project = state.projects[index];
          return _ProjectCard(
            project: project,
            onTap: () => context.push('/projects/${project.id}'),
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterSheet(
        currentFilter: ref.read(projectListProvider).statusFilter,
        onFilterSelected: (status) {
          ref.read(projectListProvider.notifier).filterByStatus(status);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Project card widget
class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusChip(status: project.status),
                ],
              ),
              const SizedBox(height: 8),

              // Location
              if (project.location != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project.location!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Info row
              Row(
                children: [
                  // Dates
                  if (project.startDate != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateRange(project.startDate, project.endDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // Assigned managers count
                  if (project.assignments != null &&
                      project.assignments!.isNotEmpty) ...[
                    const Icon(
                      Icons.people,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${project.assignments!.length} manager${project.assignments!.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Budget
                  if (project.budget != null)
                    Text(
                      '₹${_formatBudget(project.budget!)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),

              // Progress Bar (timeline based)
              if (project.startDate != null && project.endDate != null) ...[
                const SizedBox(height: 12),
                _TimelineProgress(
                  startDate: project.startDate!,
                  endDate: project.endDate!,
                  status: project.status,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return '';
    final startStr = '${start.day}/${start.month}/${start.year}';
    if (end == null) return startStr;
    final endStr = '${end.day}/${end.month}/${end.year}';
    return '$startStr - $endStr';
  }

  String _formatBudget(double budget) {
    if (budget >= 10000000) {
      return '${(budget / 10000000).toStringAsFixed(1)}Cr';
    } else if (budget >= 100000) {
      return '${(budget / 100000).toStringAsFixed(1)}L';
    } else if (budget >= 1000) {
      return '${(budget / 1000).toStringAsFixed(1)}K';
    }
    return budget.toStringAsFixed(0);
  }
}

/// Status chip widget
class _StatusChip extends StatelessWidget {
  final ProjectStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }
}

/// Timeline progress widget - shows completion based on dates
class _TimelineProgress extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final ProjectStatus status;

  const _TimelineProgress({
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final progressColor = _getProgressColor(progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Timeline Progress',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  double _calculateProgress() {
    // If completed or cancelled, show appropriate progress
    if (status == ProjectStatus.completed) return 1.0;
    if (status == ProjectStatus.cancelled) return 0.0;

    final now = DateTime.now();
    final totalDuration = endDate.difference(startDate).inDays;
    if (totalDuration <= 0) return 0.0;

    final elapsed = now.difference(startDate).inDays;
    if (elapsed < 0) return 0.0;
    if (elapsed > totalDuration) return 1.0;

    return elapsed / totalDuration;
  }

  Color _getProgressColor(double progress) {
    if (status == ProjectStatus.completed) return Colors.green;
    if (status == ProjectStatus.cancelled) return Colors.grey;
    if (status == ProjectStatus.onHold) return Colors.orange;

    // Check if behind schedule
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Colors.red; // Overdue

    if (progress < 0.25) return Colors.blue;
    if (progress < 0.5) return Colors.cyan;
    if (progress < 0.75) return Colors.orange;
    return Colors.green;
  }
}

/// Filter bottom sheet
class _FilterSheet extends StatelessWidget {
  final ProjectStatus? currentFilter;
  final Function(ProjectStatus?) onFilterSelected;

  const _FilterSheet({this.currentFilter, required this.onFilterSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Status',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // All option
          _FilterOption(
            label: 'All Projects',
            isSelected: currentFilter == null,
            onTap: () => onFilterSelected(null),
          ),

          const Divider(),

          // Status options - using status.color directly
          ...ProjectStatus.values.map(
            (status) => _FilterOption(
              label: status.displayName,
              isSelected: currentFilter == status,
              onTap: () => onFilterSelected(status),
              color: status.color,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Filter option widget
class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: color != null
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          : null,
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      contentPadding: EdgeInsets.zero,
    );
  }
}
