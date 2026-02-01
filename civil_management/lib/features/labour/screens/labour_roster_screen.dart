import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/labour_model.dart';
import '../providers/labour_provider.dart';

/// Labour Roster Screen - List all workers for a project
class LabourRosterScreen extends ConsumerWidget {
  final String projectId;
  final String projectName;

  const LabourRosterScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(projectLabourProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Labour - $projectName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Mark Attendance',
            onPressed: () => context.push(
              '/projects/$projectId/attendance',
              extra: projectName,
            ),
          ),
        ],
      ),
      body: labourAsync.when(
        loading: () => const LoadingWidget(message: 'Loading workers...'),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (labourList) => labourList.isEmpty
            ? _buildEmptyState(context)
            : _buildLabourList(context, ref, labourList),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLabourDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Worker'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No workers added yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Add workers to track attendance'),
        ],
      ),
    );
  }

  Widget _buildLabourList(BuildContext context, WidgetRef ref, List<LabourModel> labourList) {
    // Separate active and inactive
    final active = labourList.where((l) => l.status == LabourStatus.active).toList();
    final inactive = labourList.where((l) => l.status == LabourStatus.inactive).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectLabourProvider(projectId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          _SummaryCard(
            totalWorkers: labourList.length,
            activeWorkers: active.length,
          ),
          const SizedBox(height: 16),

          // Active workers
          if (active.isNotEmpty) ...[
            Text(
              'Active Workers (${active.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...active.map((labour) => _LabourCard(
              labour: labour,
              onToggleStatus: () => _toggleStatus(ref, labour),
            )),
          ],

          // Inactive workers
          if (inactive.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Inactive Workers (${inactive.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...inactive.map((labour) => _LabourCard(
              labour: labour,
              onToggleStatus: () => _toggleStatus(ref, labour),
            )),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleStatus(WidgetRef ref, LabourModel labour) async {
    final newStatus = labour.status == LabourStatus.active
        ? LabourStatus.inactive
        : LabourStatus.active;

    final repo = ref.read(labourRepositoryProvider);
    await repo.toggleLabourStatus(labour.id, newStatus);
    ref.invalidate(projectLabourProvider(projectId));
  }

  void _showAddLabourDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddLabourSheet(
        projectId: projectId,
        onAdded: () {
          ref.invalidate(projectLabourProvider(projectId));
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalWorkers;
  final int activeWorkers;

  const _SummaryCard({
    required this.totalWorkers,
    required this.activeWorkers,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'Total',
              value: totalWorkers.toString(),
              icon: Icons.people,
            ),
            _StatItem(
              label: 'Active',
              value: activeWorkers.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _StatItem(
              label: 'Inactive',
              value: (totalWorkers - activeWorkers).toString(),
              icon: Icons.pause_circle,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.primary,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LabourCard extends StatelessWidget {
  final LabourModel labour;
  final VoidCallback onToggleStatus;

  const _LabourCard({
    required this.labour,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: labour.status.color.withOpacity(0.2),
          child: Text(
            labour.name[0].toUpperCase(),
            style: TextStyle(
              color: labour.status.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          labour.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (labour.skillType != null)
              Text(labour.skillType!, style: const TextStyle(fontSize: 12)),
            if (labour.dailyWage != null)
              Text(
                '₹${labour.dailyWage!.toStringAsFixed(0)}/day',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'toggle') {
              onToggleStatus();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Text(labour.status == LabourStatus.active
                  ? 'Mark Inactive'
                  : 'Mark Active'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddLabourSheet extends ConsumerStatefulWidget {
  final String projectId;
  final VoidCallback onAdded;

  const _AddLabourSheet({
    required this.projectId,
    required this.onAdded,
  });

  @override
  ConsumerState<_AddLabourSheet> createState() => _AddLabourSheetState();
}

class _AddLabourSheetState extends ConsumerState<_AddLabourSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _wageController = TextEditingController();
  String? _selectedSkill;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add New Worker',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedSkill,
              decoration: const InputDecoration(
                labelText: 'Skill Type',
                prefixIcon: Icon(Icons.work),
              ),
              items: SkillTypes.all.map((skill) {
                return DropdownMenuItem(value: skill, child: Text(skill));
              }).toList(),
              onChanged: (v) => setState(() => _selectedSkill = v),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _wageController,
              decoration: const InputDecoration(
                labelText: 'Daily Wage (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Worker'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(labourRepositoryProvider);
      
      final labour = LabourModel(
        id: '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        skillType: _selectedSkill,
        dailyWage: double.tryParse(_wageController.text),
        projectId: widget.projectId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.addLabour(labour);
      widget.onAdded();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
