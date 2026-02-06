import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/stock_provider.dart';
import '../providers/repository_providers.dart';

// Provider to fetch available stock options
final stockBalanceProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, projectId) {
  return ref.watch(stockRepositoryProvider).getStockBalance(projectId);
});

class MaterialConsumeScreen extends ConsumerStatefulWidget {
  final String projectId;
  const MaterialConsumeScreen({super.key, required this.projectId});

  @override
  ConsumerState<MaterialConsumeScreen> createState() => _MaterialConsumeScreenState();
}

class _MaterialConsumeScreenState extends ConsumerState<MaterialConsumeScreen> {
  final _formKey = GlobalKey<FormState>();
  
  Map<String, dynamic>? _selectedStockItem;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStockItem == null) return;

    final currentStock = (_selectedStockItem!['current_stock'] as num).toDouble();
    final consumeQty = double.parse(_quantityController.text);

    if (consumeQty > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Only $currentStock ${_selectedStockItem!['unit']} available')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(stockRepositoryProvider).logMaterialOutward(
        projectId: widget.projectId,
        itemId: _selectedStockItem!['item_id'],
        quantity: consumeQty,
        activity: _activityController.text.isNotEmpty ? _activityController.text : 'Material Consumed',
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consumption logged successfully')),
        );
        ref.invalidate(stockBalanceProvider(widget.projectId)); // Refresh balance
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(stockBalanceProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Log Consumption')),
      body: stockAsync.when(
        data: (stockItems) {
          // Filter out items with 0 stock
          final availableItems = stockItems.where((i) => (i['current_stock'] as num) > 0).toList();
          
          if (availableItems.isEmpty) {
             return const Center(child: Text('No materials available to consume'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   DropdownButtonFormField<Map<String, dynamic>>(
                     value: _selectedStockItem,
                     decoration: const InputDecoration(
                       labelText: 'Select Material',
                       border: OutlineInputBorder(),
                     ),
                     items: availableItems.map((item) {
                       return DropdownMenuItem(
                         value: item,
                         child: Text('${item['name']} ${item['grade'] ?? ''} (${item['current_stock']} ${item['unit']})'),
                       );
                     }).toList(),
                     onChanged: (val) {
                       setState(() {
                         _selectedStockItem = val;
                         // Reset quantity if changed
                         _quantityController.clear();
                       });
                     },
                     validator: (val) => val == null ? 'Please select a material' : null,
                   ),
                   const SizedBox(height: 16),
                   
                   if (_selectedStockItem != null) ...[
                     Align(
                       alignment: Alignment.centerLeft,
                       child: Padding(
                         padding: const EdgeInsets.only(bottom: 8),
                         child: Text(
                           'Available: ${_selectedStockItem!['current_stock']} ${_selectedStockItem!['unit']}',
                           style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                         ),
                       ),
                     ),
                     CustomTextField(
                       controller: _quantityController,
                       label: 'Quantity Consumed',
                       hintText: '0.0',
                       keyboardType: TextInputType.number,
                       validator: (val) {
                         if (val == null || val.isEmpty) return 'Required';
                         if (double.tryParse(val) == null) return 'Invalid number';
                         if (double.parse(val) <= 0) return 'Must be > 0';
                         return null;
                       },
                     ),
                     const SizedBox(height: 16),
                     
                     CustomTextField(
                       controller: _activityController,
                       label: 'Activity / Purpose',
                       hintText: 'e.g. Foundation Work',
                     ),
                     const SizedBox(height: 16),
                     
                     CustomTextField(
                       controller: _notesController,
                       label: 'Notes (Optional)',
                       hintText: 'Any remarks...',
                     ),
                     const SizedBox(height: 24),
                     
                     SizedBox(
                       width: double.infinity,
                       child: AppButton(
                         text: 'Log Consumption',
                         isLoading: _isLoading,
                         onPressed: _submit,
                       ),
                     ),
                   ],
                ],
              ),
            ),
          );
          
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
