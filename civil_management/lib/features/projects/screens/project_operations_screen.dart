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
          _MachineryTab(projectId: widget.projectId),
          _LaborTab(projectId: widget.projectId),
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

        // Materials list
        Expanded(
          child: logsAsync.when(
            data: (logs) {
              final targetType = _showReceived ? 'inward' : 'outward';
              final filtered = logs.where((l) => l.logType == targetType).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    _showReceived ? 'No materials received yet' : 'No consumption logged',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final log = filtered[index];
                  // supplier is stored in 'activity' for inward? Or 'notes'?
                  // Guide said 'supplier' in UI. Log model has 'activity', 'notes'.
                  // Usually 'activity' = supplier for inward.
                  return _MaterialItem(
                    name: log.itemName ?? 'Unknown Item',
                    quantity: '${log.quantity}',
                    unit: log.itemUnit ?? 'units',
                    date: '${log.loggedAt.day}/${log.loggedAt.month}/${log.loggedAt.year}',
                    supplier: _showReceived ? log.activity : null, // Assuming activity stores supplier name for inward
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),

        // Add buttons (Only if not loading?)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showLogMaterialSheet(
                    context,
                    ref,
                    widget.projectId,
                    _showReceived,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _showReceived ? 'Log Material Receipt' : 'Log Consumption',
                  ),
                ),
              ),
              // Optional: Add New Material Type button?
            ],
          ),
        ),
      ],
    );
  }
}

class _MaterialItem extends StatelessWidget {
  final String name;
  final String quantity;
  final String unit;
  final String date;
  final String? supplier;

  const _MaterialItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.date,
    this.supplier,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (supplier != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    supplier!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
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
                quantity,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                unit,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showLogMaterialSheet(
  BuildContext context,
  WidgetRef ref,
  String projectId,
  bool isReceived,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _LogMaterialSheetContent(
      projectId: projectId,
      isReceived: isReceived,
    ),
  );
}

class _LogMaterialSheetContent extends ConsumerStatefulWidget {
  final String projectId;
  final bool isReceived;

  const _LogMaterialSheetContent({
    required this.projectId,
    required this.isReceived,
  });

  @override
  ConsumerState<_LogMaterialSheetContent> createState() =>
      _LogMaterialSheetContentState();
}

class _LogMaterialSheetContentState
    extends ConsumerState<_LogMaterialSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _activityController = TextEditingController(); // Supplier or Activity
  final _notesController = TextEditingController(); // For notes if needed

  String? _selectedItemId;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _activityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch stock items for dropdown
    final stockAsync = ref.watch(stockItemsStreamProvider(widget.projectId));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.isReceived ? 'Log Material Receipt' : 'Log Consumption',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              widget.isReceived
                  ? 'Add received stock to inventory'
                  : 'Record material usage',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Item Dropdown
            stockAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Text('No items found. Create items first.');
                  // Ideally provide a way to create items here too, but separate scope.
                }
                return DropdownButtonFormField<String>(
                  value: _selectedItemId,
                  decoration: InputDecoration(
                    labelText: 'Select Material',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: items.map((item) {
                    return DropdownMenuItem(
                      value: item.id,
                      child: Text('${item.name} (${item.unit})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedItemId = val),
                  validator: (val) => val == null ? 'Required' : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Error loading items: $err'),
            ),
            const SizedBox(height: 16),

            _FormField(
              label: 'Quantity',
              hint: '0.0',
              controller: _quantityController,
              isNumber: true,
            ),

            if (widget.isReceived)
              _FormField(
                label: 'Vendor / Supplier',
                hint: 'Supplier Name',
                controller: _activityController,
              )
            else
              _FormField(
                label: 'Activity / Purpose',
                hint: 'e.g. Foundation Work',
                controller: _activityController,
              ),
            
            // _FormField(label: 'Notes', hint: 'Optional notes', controller: _notesController),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.isReceived ? 'Log Receipt' : 'Log Consumption'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItemId == null) return;

    setState(() => _isLoading = true);

    try {
      final quantity = double.tryParse(_quantityController.text) ?? 0.0;
      final controller = ref.read(stockControllerProvider.notifier);

      bool success;
      if (widget.isReceived) {
        success = await controller.logInward(
          projectId: widget.projectId,
          itemId: _selectedItemId!,
          quantity: quantity,
          activity: _activityController.text, // Supplier
          notes: _notesController.text,
        );
      } else {
        success = await controller.logOutward(
          projectId: widget.projectId,
          itemId: _selectedItemId!,
          quantity: quantity,
          activity: _activityController.text,
          notes: _notesController.text,
        );
      }

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged successfully')),
          );
          // Refresh logs
          ref.refresh(materialLogsProvider(widget.projectId));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Failed to log')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool isNumber;

  const _FormField({
    required this.label,
    required this.hint,
    this.controller,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textDisabled),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Machinery Tab
class _MachineryTab extends ConsumerWidget {
  final String projectId;

  const _MachineryTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(machineryLogsStreamProvider(projectId));

    return Column(
      children: [
        // History list
        Expanded(
          child: logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const Center(child: Text('No machinery usage logged yet'));
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Machinery History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  ...logs.map((log) => _MachineryItem(
                    name: log.machineryName ?? 'Unknown Machine',
                    hours: log.executionHours.toInt(), // or double
                    date: '${log.loggedAt.day}/${log.loggedAt.month}',
                  )),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
        // FAB
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showLogMachinerySheet(context, ref, projectId),
              icon: const Icon(Icons.add),
              label: const Text('Log Machinery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MachineryItem extends StatelessWidget {
  final String name;
  final int hours;
  final String date;

  const _MachineryItem({
    required this.name,
    required this.hours,
    required this.date,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.construction, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
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
                '${hours}Hrs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showLogMachinerySheet(BuildContext context, WidgetRef ref, String projectId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _LogMachinerySheetContent(projectId: projectId),
  );
}

class _LogMachinerySheetContent extends ConsumerStatefulWidget {
  final String projectId;

  const _LogMachinerySheetContent({required this.projectId});

  @override
  ConsumerState<_LogMachinerySheetContent> createState() =>
      _LogMachinerySheetContentState();
}

class _LogMachinerySheetContentState
    extends ConsumerState<_LogMachinerySheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _activityController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  
  String? _selectedMachineryId;
  bool _isLoading = false;

  @override
  void dispose() {
    _activityController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch machinery list
    final machineryListAsync = ref.watch(machineryListProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Log Machinery',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Add time to the site ledger',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            
            machineryListAsync.when(
              data: (items) {
                 if (items.isEmpty) return const Text('No machinery available in system');
                 return DropdownButtonFormField<String>(
                  value: _selectedMachineryId,
                  decoration: InputDecoration(
                    labelText: 'Machine Selection',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: items.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.name} (${m.registrationNo ?? "No Reg"})'))).toList(),
                  onChanged: (v) => setState(() => _selectedMachineryId = v),
                  validator: (v) => v == null ? 'Required' : null,
                 );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Error loading machinery: $err'),
            ),
            const SizedBox(height: 16),

            _FormField(label: 'Work Activity', hint: 'Enter description', controller: _activityController),
            
            Row(
              children: [
                Expanded(
                  child: _FormField(label: 'Start Reading (Hrs)', hint: '1000.0', controller: _startController, isNumber: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormField(label: 'End Reading (Hrs)', hint: '1008.0', controller: _endController, isNumber: true),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm & Save Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMachineryId == null) return;
    
    setState(() => _isLoading = true);

    try {
      final start = double.parse(_startController.text);
      final end = double.parse(_endController.text);
      
      if (end < start) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End reading must be greater than start reading')));
        return;
      }

      final success = await ref.read(machineryControllerProvider.notifier).logUsage(
        projectId: widget.projectId,
        machineryId: _selectedMachineryId!,
        workActivity: _activityController.text,
        startReading: start,
        endReading: end,
      );

      if (success) {
        if (mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged successfully')));
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Labor Tab
class _LaborTab extends ConsumerWidget {
  final String projectId;

  const _LaborTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use daily logs stream
    final logsAsync = ref.watch(dailyLabourLogsProvider(projectId));
    final logs = logsAsync.valueOrNull ?? [];
    
    // Calculate Stats
    int totalWorkers = 0;
    int skilled = 0;
    int unskilled = 0;
    
    for (var log in logs) {
       // Only count today's logs for "Current Strength"?
       // Or total history? Design says "Labor History".
       // Stats usually show *Today's* snapshot.
       // But if I sum all logs, it's thousands.
       // I'll filter for Today for stats.
       if (log.logDate.year == DateTime.now().year && 
           log.logDate.month == DateTime.now().month && 
           log.logDate.day == DateTime.now().day) {
          totalWorkers += (log.skilledCount + log.unskilledCount);
          skilled += log.skilledCount;
          unskilled += log.unskilledCount;
       }
    }
    
    // If no logs today, maybe show "Last Logged"? Or just 0.

    return Column(
      children: [
        // Stats summary (Today's Strength)
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
               _LaborStat(label: "Today's Strength", value: '$totalWorkers'),
               Container(width: 1, height: 40, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 20)),
               _LaborStat(label: 'Skilled', value: '$skilled'),
               Container(width: 1, height: 40, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 20)),
               _LaborStat(label: 'Unskilled', value: '$unskilled'),
            ],
          ),
        ),

        // History list (Daily Logs)
        Expanded(
          child: logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const Center(child: Text('No labor logs recorded'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final isToday = log.logDate.year == DateTime.now().year && 
                                  log.logDate.month == DateTime.now().month && 
                                  log.logDate.day == DateTime.now().day;
                                  
                  return _LaborItem(
                    name: log.contractorName,
                    role: 'Skilled: ${log.skilledCount} | Unskilled: ${log.unskilledCount}',
                    days: isToday ? 0 : 0, // Not used for "Days" anymore really, maybe reuse for Date
                    dateStr: "${log.logDate.day}/${log.logDate.month}",
                    color: AppColors.primary,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
        
        // FAB (Log Labor)
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showLogLaborSheet(context, ref, projectId),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Log Daily Labor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _showLogLaborSheet(BuildContext context, WidgetRef ref, String projectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LogLaborSheetContent(projectId: projectId),
    );
  }
}

class _LaborStat extends StatelessWidget {
  final String label;
  final String value;

  const _LaborStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LaborItem extends StatelessWidget {
  final String name;
  final String role;
  final int days;
  final String dateStr;
  final Color color;

  const _LaborItem({
    required this.name,
    required this.role,
    required this.days,
    required this.dateStr,
    required this.color,
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
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
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
                dateStr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogLaborSheetContent extends ConsumerStatefulWidget {
  final String projectId;

  const _LogLaborSheetContent({required this.projectId});

  @override
  ConsumerState<_LogLaborSheetContent> createState() => _LogLaborSheetContentState();
}

class _LogLaborSheetContentState extends ConsumerState<_LogLaborSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _contractorController = TextEditingController();
  final _skilledController = TextEditingController(text: '0');
  final _unskilledController = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
              children: [
                Text(
                  'Log Labor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Add daily force report to the ledger',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _FormField(label: 'Contractor / Head', hint: 'Enter name', controller: _contractorController),
            const SizedBox(height: 12),
            Text(
              'Worker Count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _FormField(label: 'Skilled', hint: '0', controller: _skilledController, isNumber: true)),
                const SizedBox(width: 12),
                Expanded(child: _FormField(label: 'Unskilled', hint: '0', controller: _unskilledController, isNumber: true)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm & Save Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final skilled = int.tryParse(_skilledController.text) ?? 0;
      final unskilled = int.tryParse(_unskilledController.text) ?? 0;
      final uploaderId = ref.read(currentUserProvider)?.id;
      
      final log = DailyLabourLog(
        id: '', // ignored
        projectId: widget.projectId,
        contractorName: _contractorController.text,
        skilledCount: skilled,
        unskilledCount: unskilled,
        logDate: DateTime.now(),
        createdBy: uploaderId,
      );
      
      await ref.read(labourRepositoryProvider).createDailyLog(log);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily labor log saved'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
