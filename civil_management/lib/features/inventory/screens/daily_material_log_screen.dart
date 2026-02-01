import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/loading_widget.dart';
import '../data/models/stock_item_model.dart';
import '../data/models/material_log_model.dart';
import '../providers/inventory_provider.dart';

/// Daily Material Log screen with Inward/Outward tabs for Site Managers
class DailyMaterialLogScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const DailyMaterialLogScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<DailyMaterialLogScreen> createState() => _DailyMaterialLogScreenState();
}

class _DailyMaterialLogScreenState extends ConsumerState<DailyMaterialLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Material Log - ${widget.projectName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.arrow_downward), text: 'Received'),
            Tab(icon: Icon(Icons.arrow_upward), text: 'Used'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LogListTab(
            projectId: widget.projectId,
            logType: LogType.inward,
          ),
          _LogListTab(
            projectId: widget.projectId,
            logType: LogType.outward,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLogDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  void _showAddLogDialog(BuildContext context) {
    final stockItemsAsync = ref.read(stockItemsProvider(widget.projectId));
    
    stockItemsAsync.whenData((items) {
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No stock items available. Ask admin to add materials first.'),
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => _AddLogBottomSheet(
          projectId: widget.projectId,
          stockItems: items,
          initialLogType: _tabController.index == 0 ? LogType.inward : LogType.outward,
          onAdded: () {
            ref.invalidate(inwardLogsProvider(widget.projectId));
            ref.invalidate(outwardLogsProvider(widget.projectId));
            ref.invalidate(stockItemsProvider(widget.projectId));
          },
        ),
      );
    });
  }
}

class _LogListTab extends ConsumerWidget {
  final String projectId;
  final LogType logType;

  const _LogListTab({
    required this.projectId,
    required this.logType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = logType == LogType.inward
        ? ref.watch(inwardLogsProvider(projectId))
        : ref.watch(outwardLogsProvider(projectId));

    return logsAsync.when(
      loading: () => const LoadingWidget(message: 'Loading logs...'),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (logs) => logs.isEmpty
          ? _buildEmptyState(context)
          : _buildLogList(context, ref, logs),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            logType == LogType.inward ? Icons.inbox_outlined : Icons.outbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            logType == LogType.inward 
                ? 'No materials received yet' 
                : 'No materials used yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(BuildContext context, WidgetRef ref, List<MaterialLogModel> logs) {
    return RefreshIndicator(
      onRefresh: () async {
        if (logType == LogType.inward) {
          ref.invalidate(inwardLogsProvider(projectId));
        } else {
          ref.invalidate(outwardLogsProvider(projectId));
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return _MaterialLogCard(log: log);
        },
      ),
    );
  }
}

class _MaterialLogCard extends StatelessWidget {
  final MaterialLogModel log;

  const _MaterialLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: log.logType == LogType.inward 
                        ? Colors.green.withOpacity(0.2) 
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.logType.displayName,
                    style: TextStyle(
                      color: log.logType == LogType.inward ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.itemName ?? 'Unknown Item',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${log.quantity.toStringAsFixed(1)} ${log.itemUnit ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (log.activity != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.construction, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    log.activity!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              log.loggedAt != null ? dateFormat.format(log.loggedAt!) : 'Unknown date',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                log.notes!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddLogBottomSheet extends ConsumerStatefulWidget {
  final String projectId;
  final List<StockItemModel> stockItems;
  final LogType initialLogType;
  final VoidCallback onAdded;

  const _AddLogBottomSheet({
    required this.projectId,
    required this.stockItems,
    required this.initialLogType,
    required this.onAdded,
  });

  @override
  ConsumerState<_AddLogBottomSheet> createState() => _AddLogBottomSheetState();
}

class _AddLogBottomSheetState extends ConsumerState<_AddLogBottomSheet> {
  late LogType _selectedLogType;
  StockItemModel? _selectedItem;
  final _quantityController = TextEditingController();
  String? _selectedActivity;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedLogType = widget.initialLogType;
    _selectedItem = widget.stockItems.isNotEmpty ? widget.stockItems.first : null;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Material Log',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Log Type Toggle
            SegmentedButton<LogType>(
              segments: const [
                ButtonSegment(value: LogType.inward, label: Text('Received')),
                ButtonSegment(value: LogType.outward, label: Text('Used')),
              ],
              selected: {_selectedLogType},
              onSelectionChanged: (v) => setState(() => _selectedLogType = v.first),
            ),
            const SizedBox(height: 16),
            
            // Material Selection
            DropdownButtonFormField<StockItemModel>(
              value: _selectedItem,
              decoration: const InputDecoration(
                labelText: 'Select Material',
                border: OutlineInputBorder(),
              ),
              items: widget.stockItems
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text('${item.name} (${item.quantity} ${item.unit})'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedItem = v),
            ),
            const SizedBox(height: 16),
            
            // Quantity
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: const OutlineInputBorder(),
                suffixText: _selectedItem?.unit ?? '',
              ),
            ),
            const SizedBox(height: 16),
            
            // Activity (for outward only)
            if (_selectedLogType == LogType.outward) ...[
              DropdownButtonFormField<String>(
                value: _selectedActivity,
                decoration: const InputDecoration(
                  labelText: 'Activity',
                  border: OutlineInputBorder(),
                ),
                items: MaterialActivities.commonActivities
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedActivity = v),
              ),
              const SizedBox(height: 16),
            ],
            
            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Submit Button
            FilledButton(
              onPressed: _isSubmitting ? null : _submitLog,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLog() async {
    if (_selectedItem == null) return;
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(inventoryRepositoryProvider);
      final log = MaterialLogModel(
        id: '',
        projectId: widget.projectId,
        itemId: _selectedItem!.id,
        logType: _selectedLogType,
        quantity: quantity,
        activity: _selectedActivity,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await repository.addMaterialLog(log);
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
