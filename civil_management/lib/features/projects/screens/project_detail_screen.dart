import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/project_model.dart';
import '../providers/project_provider.dart';
import 'widgets/assign_manager_sheet.dart';

/// Redesigned Project Detail Screen
/// Reference: Skyline Towers Mockup
class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectDetailProvider(widget.projectId));
    final authState = ref.watch(authProvider);
    final isAdmin = authState.isAtLeast(UserRole.admin);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          projectState.project?.name ?? 'Project Details',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black),
              onPressed: () => context.pushNamed('edit-project', pathParameters: {'id': widget.projectId}),
            ),
        ],
      ),
      body: projectState.isLoading
          ? const LoadingWidget()
          : projectState.error != null
              ? AppErrorWidget(message: projectState.error!)
              : projectState.project == null
                  ? const Center(child: Text('Project not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Hero Section (Manager + Status + Material Snapshot)
                          _HeroSection(
                            project: projectState.project!,
                            isAdmin: isAdmin,
                            onEditManager: () => _showAssignManagerSheet(context),
                            onEditProject: () => context.pushNamed('edit-project', pathParameters: {'id': widget.projectId}),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Module Navigation
                          _ModuleNavigation(projectId: widget.projectId),
                        ],
                      ),
                    ),
    );
  }

  void _showAssignManagerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignManagerSheet(projectId: widget.projectId),
    );
  }
}

/// The main dashboard card showing Engineer, Status, and Material Snapshot
class _HeroSection extends StatelessWidget {
  final ProjectModel project;
  final bool isAdmin;
  final VoidCallback onEditManager;
  final VoidCallback onEditProject;

  const _HeroSection({
    required this.project,
    required this.isAdmin,
    required this.onEditManager,
    required this.onEditProject,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM yyyy');
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assigned Engineer Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ASSIGNED ENGINEER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              if (isAdmin)
                 InkWell(
                   onTap: onEditManager,
                   borderRadius: BorderRadius.circular(8),
                   child: Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: Colors.grey[100],
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: const Icon(Icons.person_add_alt_1, size: 16, color: Colors.black),
                   ),
                 ),
            ],
          ),
          const SizedBox(height: 8),
          // Engineer Name
          Text(
            project.managerName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 20),
          
          // Phase/Status & Date & Edit Project
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               _StatusChip(status: project.status),
               Row(
                 children: [
                   if (project.endDate != null)
                     Row(
                       children: [
                         const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                         const SizedBox(width: 4),
                         Text(
                           'Completion by ${dateFormat.format(project.endDate!)}',
                           style: TextStyle(
                             fontSize: 13,
                             color: Colors.grey[600],
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ],
                     ),
                   if (isAdmin) ...[
                     const SizedBox(width: 12),
                     InkWell(
                       onTap: onEditProject,
                       borderRadius: BorderRadius.circular(8),
                       child: Padding(
                         padding: const EdgeInsets.all(4),
                         child: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                       ),
                     ),
                   ],
                 ],
               ),
             ],
          ),
          
          const SizedBox(height: 24),
          
          // Material Snapshot
          _MaterialSnapshot(projectId: project.id),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ProjectStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    // Custom labels for the design
    String label = status.displayName;
    if (status == ProjectStatus.inProgress) label = 'PHASE 2 WORK'; // Matching mockup vibe

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1), // Fixed
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Material Snapshot within Hero Section (Steel & Cement)
class _MaterialSnapshot extends ConsumerWidget {
  final String projectId;
  const _MaterialSnapshot({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(projectMaterialBreakdownProvider(projectId));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE), // Very light blue-grey
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: breakdownAsync.when(
        data: (materials) {
          // Filter logic: Find Steel and Cement (or top 2)
          // Naive matching for user demo - can be improved to prioritize critical materials
          final steel = materials.firstWhere(
            (m) => m.name.toLowerCase().contains('steel'),
            orElse: () => const MaterialBreakdown(name: 'Steel', unit: 'Tons'),
          );
          final cement = materials.firstWhere(
            (m) => m.name.toLowerCase().contains('cement'),
            orElse: () => const MaterialBreakdown(name: 'Cement', unit: 'Bags'),
          );
          
          // Fallback if list is empty but we want to show placeholders? 
          // Requirements say "No dummy data". Show what we have.
          final displayItems = <MaterialBreakdown>[
             if (materials.any((m) => m.name.toLowerCase().contains('steel'))) steel,
             if (materials.any((m) => m.name.toLowerCase().contains('cement'))) cement,
          ];
          
          // If no specific Steel/Cement, show top 2 items
          if (displayItems.isEmpty && materials.isNotEmpty) {
             displayItems.addAll(materials.take(2));
          }

          if (displayItems.isEmpty) {
             return const Center(
               child: Text('No material data tracked', style: TextStyle(color: Colors.grey, fontSize: 12)),
             );
          }

          return Column(
            children: displayItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _MaterialRow(item: item),
            )).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (err, _) => const Text('Failed to load materials', style: TextStyle(fontSize: 12, color: Colors.red)),
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  final MaterialBreakdown item;
  const _MaterialRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final unit = item.unit ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_view_day, size: 14, color: Colors.black54),
            const SizedBox(width: 8),
            Text(
              item.name.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatPill(label: 'Received', value: '${item.received} $unit'),
            _StatPill(label: 'Consumed', value: '${item.consumed} $unit'),
            _StatPill(label: 'Remaining', value: '${item.remaining} $unit'),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90, // Fixed width for alignment like in mockup
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4FF), // Light blue tint
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0055FF), // Vibrant blue
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation Modules (Vertical List)
class _ModuleNavigation extends StatelessWidget {
  final String projectId;
  const _ModuleNavigation({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModuleNavCard(
          title: 'Blueprints',
          subtitle: 'Project Documents / Drawings',
          icon: Icons.description_outlined,
          color: const Color(0xFFE8F0FE), // Light Blue
          iconColor: const Color(0xFF1967D2),
          onTap: () => context.goNamed('project-blueprints', pathParameters: {'id': projectId}),
        ),
        const SizedBox(height: 16),
        _ModuleNavCard(
          title: 'Operations',
          subtitle: 'Consumption And Expenses',
          icon: Icons.engineering_outlined,
          color: const Color(0xFFE3F2FD), 
          iconColor: const Color(0xFF1565C0),
          // Note: Mockup shows specific design, we map to existing Operations screen
          onTap: () => context.goNamed('project-operations', pathParameters: {'id': projectId}), 
        ),
        const SizedBox(height: 16),
        _ModuleNavCard(
          title: 'Reports / Insights',
          subtitle: 'Bills And Reports',
          icon: Icons.analytics_outlined,
          color: const Color(0xFFF3E5F5), // Light purple tone
          iconColor: const Color(0xFF7B1FA2),
          onTap: () => context.goNamed('project-reports', pathParameters: {'id': projectId}),
        ),
      ],
    );
  }
}

class _ModuleNavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ModuleNavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // Fixed
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
