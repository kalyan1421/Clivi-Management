import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/bill_model.dart';
import '../providers/bill_provider.dart';
import 'package:civil_management/features/projects/providers/project_provider.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Initial load of projects
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectListProvider.notifier).loadProjects();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {}); // Rebuild to filter list
    }
  }

  BillStatus _getCurrentTabStatus() {
    switch (_tabController.index) {
      case 0:
        return BillStatus.pending;
      case 1:
        return BillStatus.approved;
      case 2:
        return BillStatus.paid;
      case 3:
        return BillStatus.rejected;
      default:
        return BillStatus.pending;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectListProvider);

    // Auto-select first project if none selected
    if (_selectedProjectId == null && projectState.projects.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedProjectId == null) {
          setState(() {
            _selectedProjectId = projectState.projects.first.id;
          });
        }
      });
    }

    final AsyncValue<List<BillModel>> billsAsync = _selectedProjectId == null
        ? const AsyncValue.data([])
        : ref.watch(billsStreamProvider(_selectedProjectId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills & Expenses'),
        actions: [
          if (projectState.projects.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProjectId,
                  hint: const Text('Select Project', style: TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  isDense: true,
                  items: projectState.projects.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedProjectId = value;
                      });
                    }
                  },
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            _buildTab('Pending'),
            _buildTab('Approved'),
            _buildTab('Paid'),
            _buildTab('Rejected'),
          ],
        ),
      ),
      body: _selectedProjectId == null && projectState.projects.isEmpty
          ? const Center(child: Text('No projects found'))
          : _selectedProjectId == null
              ? const Center(child: Text('Please select a project'))
              : billsAsync.when(
                  data: (bills) {
                    final status = _getCurrentTabStatus();
                    final filteredBills =
                        bills.where((b) => b.status == status).toList();
                    return _buildBillList(filteredBills);
                  },
                  loading: () => const LoadingWidget(message: 'Loading bills...'),
                  error: (err, stack) => AppErrorWidget(
                    message: err.toString(),
                    onRetry: () => ref.refresh(billsStreamProvider(_selectedProjectId!)),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bills/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTab(String text) {
    return Tab(child: Text(text));
  }

  Widget _buildBillList(List<BillModel> bills) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No bills found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Grouping Logic
    final groupedBills = <String, List<BillModel>>{};
    for (var bill in bills) {
      final dateKey = _getDateKey(bill.billDate);
      if (!groupedBills.containsKey(dateKey)) {
        groupedBills[dateKey] = [];
      }
      groupedBills[dateKey]!.add(bill);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedBills.length,
      itemBuilder: (context, index) {
        final dateKey = groupedBills.keys.elementAt(index);
        final dateBills = groupedBills[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            ...dateBills.map((bill) => _BillCard(bill: bill)),
          ],
        );
      },
    );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Today';
    if (checkDate == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }
}

class _BillCard extends StatelessWidget {
  final BillModel bill;

  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bill.status.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTypeIcon(bill.type),
            color: bill.status.color,
          ),
        ),
        title: Text(
          bill.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(bill.vendorName ?? 'Unknown Vendor'),
            if (bill.projectName != null)
              Text(
                bill.projectName!,
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500),
              ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹${bill.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: bill.status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                bill.status.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: bill.status.color,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Open detail view to approve/reject
        },
      ),
    );
  }

  IconData _getTypeIcon(BillType type) {
    switch (type) {
      case BillType.workers:
        return Icons.group;
      case BillType.materials:
        return Icons.inventory_2;
      case BillType.transport:
        return Icons.local_shipping;
      case BillType.equipmentRent:
        return Icons.handyman;
      case BillType.expense:
        return Icons.outbound;
      case BillType.income:
        return Icons.attach_money;
      case BillType.invoice:
        return Icons.receipt;
    }
  }
}
