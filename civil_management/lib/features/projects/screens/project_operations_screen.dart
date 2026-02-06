import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/project_provider.dart';
import '../../materials/providers/stock_provider.dart';
import '../../materials/data/models/stock_item.dart';
import '../../materials/data/models/material_log.dart';
import '../../machinery/providers/machinery_provider.dart';
import '../../machinery/data/models/machinery_log_model.dart';
import '../../labour/data/models/daily_labour_log.dart';
import '../../labour/providers/labour_provider.dart';
import '../../labour/data/models/labour_model.dart';
import '../../auth/providers/auth_provider.dart';

import '../../materials/screens/material_receive_screen.dart';
import '../../materials/screens/material_consume_screen.dart';

import '../../machinery/screens/machinery_tab_screen.dart';
import '../../labour/screens/labour_tab_screen.dart';

/// Project Operations Screen with Materials, Machinery, and Labor tabs
class ProjectOperationsScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectOperationsScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectOperationsScreen> createState() =>
      _ProjectOperationsScreenState();
}

class _ProjectOperationsScreenState
    extends ConsumerState<ProjectOperationsScreen>
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
    final projectName = state.project?.name ?? 'Project';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              projectName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Skyline Towers / Operations',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Materials'),
            Tab(text: 'Machinery'),
            Tab(text: 'Labor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MaterialsTab(projectId: widget.projectId),
          MachineryTabScreen(projectId: widget.projectId),
          LabourTabScreen(projectId: widget.projectId),
        ],
      ),
    );
  }
}

/// Materials Tab with Received/Consumption toggle
class _MaterialsTab extends ConsumerStatefulWidget {
  final String projectId;

  const _MaterialsTab({required this.projectId});

  @override
  ConsumerState<_MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends ConsumerState<_MaterialsTab> {
  bool _showReceived = true;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(materialLogsProvider(widget.projectId));

    return Column(
      children: [
        // Toggle buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  label: 'Received',
                  isSelected: _showReceived,
                  onTap: () => setState(() => _showReceived = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToggleButton(
                  label: 'Consumption',
                  isSelected: !_showReceived,
                  onTap: () => setState(() => _showReceived = false),
                ),
              ),
            ],
          ),
        ),

        // Embedded Content
        Expanded(
          child: _showReceived
              ? MaterialReceiveScreen(
                  projectId: widget.projectId,
                  isEmbedded: true,
                )
              : MaterialConsumeScreen(
                  projectId: widget.projectId,
                  isEmbedded: true,
                ),
        ),
      ],
    );
  }
}


class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}




