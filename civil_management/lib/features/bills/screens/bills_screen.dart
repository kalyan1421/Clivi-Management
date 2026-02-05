import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/bill_model.dart';
import '../providers/bill_provider.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBills();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadBills();
    }
  }

  void _loadBills() {
    final status = _getCurrentTabStatus();
    ref.read(billListProvider.notifier).loadBills(status: status);
  }

  BillStatus? _getCurrentTabStatus() {
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
    final state = ref.watch(billListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills & Expenses'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            _buildTab('Pending'), // TODO: Add Badges
            _buildTab('Approved'),
            _buildTab('Paid'),
            _buildTab('Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(4, (index) {
          return RefreshIndicator(
            onRefresh: () async => _loadBills(),
            child: _buildBillList(state),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bills/create'), // Updated route
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTab(String text) {
    return Tab(child: Text(text));
  }

  Widget _buildBillList(BillListState state) {
    if (state.isLoading && state.bills.isEmpty) {
      return const LoadingWidget(message: 'Loading bills...');
    }

    if (state.error != null && state.bills.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: _loadBills,
      );
    }

    if (state.bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary),
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
    for (var bill in state.bills) {
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
        final bills = groupedBills[dateKey]!;

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
            ...bills.map((bill) => _BillCard(bill: bill)),
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
                  fontWeight: FontWeight.w500
                ),
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
      case BillType.expense:
        return Icons.outbound;
      case BillType.income:
        return Icons.attach_money;
      case BillType.invoice:
        return Icons.receipt;
    }
  }
}
