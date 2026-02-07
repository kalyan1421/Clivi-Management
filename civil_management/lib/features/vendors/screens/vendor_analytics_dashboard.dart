import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/vendor_analytics_provider.dart';
import '../data/models/vendor_summary_models.dart';

class VendorAnalyticsDashboard extends ConsumerWidget {
  const VendorAnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentSummaries = ref.watch(vendorPaymentSummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(vendorPaymentSummariesProvider);
            },
          ),
        ],
      ),
      body: paymentSummaries.when(
        data: (summaries) => _buildDashboard(context, summaries),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<VendorPaymentSummary> summaries) {
    if (summaries.isEmpty) {
      return const Center(
        child: Text('No vendor data available'),
      );
    }

    // Calculate totals
    final totalInvoices = summaries.fold<double>(
      0, 
      (sum, s) => sum + s.totalInvoiceAmount,
    );
    final totalPaid = summaries.fold<double>(
      0, 
      (sum, s) => sum + s.totalPaid,
    );
    final totalBalance = summaries.fold<double>(
      0, 
      (sum, s) => sum + s.totalBalance,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Invoices',
                  totalInvoices,
                  Colors.blue,
                  Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Paid',
                  totalPaid,
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Balance Due',
                  totalBalance,
                  Colors.orange,
                  Icons.pending,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Vendor List
          Text(
            'Vendors',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...summaries.map((summary) => _buildVendorCard(context, summary)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, VendorPaymentSummary summary) {
    final paymentPercentage = summary.totalInvoiceAmount > 0
        ? (summary.totalPaid / summary.totalInvoiceAmount * 100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to vendor detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VendorDetailScreen(vendorId: summary.vendorId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor Name & Type
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.vendorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (summary.vendorType != null)
                          Text(
                            summary.vendorType!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: summary.totalBalance > 0 ? Colors.orange[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      summary.totalBalance > 0 ? 'Balance Due' : 'Paid',
                      style: TextStyle(
                        color: summary.totalBalance > 0 ? Colors.orange[700] : Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Payment Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: paymentPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    paymentPercentage >= 100 ? Colors.green : Colors.blue,
                  ),
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 12),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Invoices', '${summary.totalInvoices}'),
                  _buildStatItem(
                    'Total',
                    NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                        .format(summary.totalInvoiceAmount),
                  ),
                  _buildStatItem(
                    'Paid',
                    NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                        .format(summary.totalPaid),
                  ),
                  _buildStatItem(
                    'Balance',
                    NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                        .format(summary.totalBalance),
                    isHighlight: summary.totalBalance > 0,
                  ),
                ],
              ),

              // Credit Limit Warning
              if (summary.creditLimit != null && summary.creditUtilization != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Credit: ${summary.creditUtilization!.toStringAsFixed(0)}% of ₹${NumberFormat.decimalPattern().format(summary.creditLimit)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: summary.creditUtilization! > 80 ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.orange[700] : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Placeholder for Vendor Detail Screen
class VendorDetailScreen extends StatelessWidget {
  final String vendorId;

  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Details')),
      body: const Center(child: Text('Vendor Detail Screen - Coming Soon')),
    );
  }
}
