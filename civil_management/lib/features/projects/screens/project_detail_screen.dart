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
import '../../materials/data/models/stock_item.dart';
import '../../materials/providers/stock_provider.dart';

/// Project detail screen matching the design mockup
/// Single scroll layout: Manager → Materials → Blueprints → Operations → Delete
class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectDetailProvider(widget.projectId));
    final role = ref.watch(userRoleProvider);
    final isAdmin = role == UserRole.admin || role == UserRole.superAdmin;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          state.project?.name ?? 'Project Details',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isAdmin && state.project != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black),
              onPressed: () =>
                  context.push('/projects/${widget.projectId}/edit'),
            ),
        ],
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

    final project = state.project!;

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(projectDetailProvider(widget.projectId).notifier)
            .refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manager Card
            _ManagerCard(
              project: project,
              isAdmin: isAdmin,
              onAssignTap: _showAssignManagerSheet,
            ),

            const SizedBox(height: 16),

            // Material Stats Section
            _MaterialStatsSection(projectId: widget.projectId),

            const SizedBox(height: 16),

            // Blueprints Section
            _BlueprintsSection(project: project),

            const SizedBox(height: 16),

            // Operations Section
            _OperationsSection(project: project),

            const SizedBox(height: 16),

            // Reports/Insights Section
            _ReportsSection(project: project),

            // Delete Project Button (Admin only)
            if (isAdmin) ...[
              const SizedBox(height: 24),
              _DeleteProjectButton(
                project: project,
                onDelete: () => _showDeleteConfirmation(project),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Delete Project'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${project.name}"?\n\nThis project will be moved to trash and can be recovered within 30 days.',
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

/// Manager card with avatar, name, phone
class _ManagerCard extends StatelessWidget {
  final ProjectModel project;
  final bool isAdmin;
  final VoidCallback onAssignTap;

  const _ManagerCard({
    required this.project,
    required this.isAdmin,
    required this.onAssignTap,
  });

  @override
  Widget build(BuildContext context) {
    final manager = project.primaryManager;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MANAGER ASSIGNED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (isAdmin)
                TextButton.icon(
                  onPressed: onAssignTap,
                  icon: Icon(
                    manager != null ? Icons.edit : Icons.add,
                    size: 16,
                  ),
                  label: Text(manager != null ? 'Change' : 'Assign'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  (manager?.userName ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager?.userName ?? 'Not Assigned',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (manager?.userPhone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            manager!.userPhone!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (project.projectType != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: project.projectType!.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    project.projectType!.value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: project.projectType!.color,
                    ),
                  ),
                ),
            ],
          ),

          // Project info row
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              if (project.clientName != null) ...[
                Expanded(
                  child: _InfoItem(
                    icon: Icons.business,
                    label: 'Client',
                    value: project.clientName!,
                  ),
                ),
              ],
              if (project.location != null) ...[
                Expanded(
                  child: _InfoItem(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: project.location!,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.calendar_today,
                  label: 'Duration',
                  value: _getDurationText(),
                ),
              ),
              if (project.budget != null)
                Expanded(
                  child: _InfoItem(
                    icon: Icons.currency_rupee,
                    label: 'Budget',
                    value: '₹${_formatBudget(project.budget!)}',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDurationText() {
    if (project.startDate == null) return 'Not set';
    final start =
        '${project.startDate!.day}/${project.startDate!.month}/${project.startDate!.year}';
    if (project.endDate == null) return 'From $start';
    final end =
        '${project.endDate!.day}/${project.endDate!.month}/${project.endDate!.year}';
    return '$start - $end';
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
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Material stats section with grid cards
class _MaterialStatsSection extends ConsumerWidget {
  final String projectId;

  const _MaterialStatsSection({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockItemsStreamProvider(projectId));
    final logsAsync = ref.watch(materialLogsProvider(projectId));

    // Combine data
    return stockAsync.when(
      data: (items) {
        if (items.isEmpty) return _buildEmptyState();

        return logsAsync.when(
          data: (logs) {
             // Basic computation
             // This assumes logs contain all history. 
             // Ideally this should be server-side.
             
             final stats = items.map((item) {
                final itemLogs = logs.where((l) => l.itemId == item.id);
                double received = 0;
                double consumed = 0;
                for (var log in itemLogs) {
                  if (log.quantity > 0) received += log.quantity; // assuming positive is inward? 
                  // Wait, logs have 'logType' or 'quantity_change'.
                  // Check MaterialLog model. 
                  // If quantity is absolute, check logType.
                  if (log.logType == 'inward') received += log.quantity;
                  if (log.logType == 'outward') consumed += log.quantity; // Assuming stored as positive
                }
                
                return _MaterialCard(
                   name: item.name,
                   icon: Icons.grid_view, // Placeholder
                   received: received.toInt(),
                   consumed: consumed.toInt(),
                   remaining: item.quantity.toInt(),
                   unit: item.unit,
                );
             }).toList();
             
             // Sort by activity or name
             // stats.sort...

             return SizedBox(
              height: 140, 
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: stats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: 280, 
                  child: stats[index],
                ),
              ),
             );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox(), // Fail silently or show error
        );
      },
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(strokeWidth: 2),
      )),
      error: (err, _) => Text('Error loading stock: $err', style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.grey),
          SizedBox(width: 8),
          Text('No materials tracked yet', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _StockItemCard extends StatelessWidget {
  final StockItem item;

  const _StockItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.quantity} ${item.unit}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'Current Stock',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _MaterialCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final int received;
  final int consumed;
  final int remaining;
  final String unit;

  const _MaterialCard({
    required this.name,
    required this.icon,
    required this.received,
    required this.consumed,
    required this.remaining,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _StatChip(
                      label: 'Recv.',
                      value: '$received $unit',
                      color: AppColors.success,
                    ),
                    _StatChip(
                      label: 'Cons.',
                      value: '$consumed $unit',
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$remaining',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Remaining',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $value',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Blueprints section
class _BlueprintsSection extends StatelessWidget {
  final ProjectModel project;

  const _BlueprintsSection({required this.project});

  @override
  Widget build(BuildContext context) {
    return _SectionButton(
      icon: Icons.photo_library_outlined,
      title: 'Blueprints',
      subtitle: 'View project drawings and files',
      onTap: () => context.push('/projects/${project.id}/blueprints'),
    );
  }
}

/// Operations section
class _OperationsSection extends StatelessWidget {
  final ProjectModel project;

  const _OperationsSection({required this.project});

  @override
  Widget build(BuildContext context) {
    return _SectionButton(
      icon: Icons.settings_outlined,
      title: 'Operations',
      subtitle: 'Log materials, machinery and labor',
      onTap: () => context.push('/projects/${project.id}/operations'),
    );
  }
}

/// Reports section
class _ReportsSection extends StatelessWidget {
  final ProjectModel project;

  const _ReportsSection({required this.project});

  @override
  Widget build(BuildContext context) {
    return _SectionButton(
      icon: Icons.bar_chart,
      title: 'Reports / Insights',
      subtitle: 'View analytics and reports',
      onTap: () => context.push('/projects/${project.id}/reports'),
    );
  }
}

/// Reusable section button widget
class _SectionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SectionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Delete project button
class _DeleteProjectButton extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onDelete;

  const _DeleteProjectButton({required this.project, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline, color: AppColors.error),
        label: const Text(
          'Delete Project',
          style: TextStyle(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}
