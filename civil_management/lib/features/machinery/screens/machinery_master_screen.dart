import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/machinery_provider.dart';
import '../../../core/widgets/custom_text_field.dart';
// import '../../../core/widgets/app_dropdown.dart'; // unused or use standard

class MachineryMasterScreen extends ConsumerWidget {
  const MachineryMasterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machineryListAsync = ref.watch(machineryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Machinery Master'),
      ),
      body: machineryListAsync.when(
        data: (machinery) {
          if (machinery.isEmpty) {
            return const Center(child: Text('No machinery added yet.'));
          }
          return ListView.builder(
            itemCount: machinery.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = machinery[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(item.ownershipType == 'Own' ? Icons.handyman : Icons.car_rental),
                  ),
                  title: Text(item.name),
                  subtitle: Text('${item.type ?? 'Unknown Type'} • ${item.registrationNo ?? 'No Reg No'}'),
                  trailing: Chip(
                    label: Text(item.status),
                    backgroundColor: item.status == 'active' ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: item.status == 'active' ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMachinerySheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMachinerySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddMachineryForm(),
    );
  }
}

class _AddMachineryForm extends ConsumerStatefulWidget {
  const _AddMachineryForm();

  @override
  ConsumerState<_AddMachineryForm> createState() => _AddMachineryFormState();
}

class _AddMachineryFormState extends ConsumerState<_AddMachineryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController(); // Or dropdown
  final _regNoController = TextEditingController();
  
  String _ownershipType = 'Rental'; // Default
  final List<String> _ownershipOptions = ['Own', 'Rental'];
  
  // Common machinery types for suggestion
  static const List<String> _machineryTypes = [
    'Excavator', 'JCB', 'Crane', 'Mixer', 'Tractor', 'Truck', 'Roller', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    // Handle keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add New Machinery', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Machinery Name (e.g. JCB 3DX)'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            
            // Type (Autocomplete)
            Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return _machineryTypes;
                return _machineryTypes.where((element) => 
                     element.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (option) => _typeController.text = option,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                 // Sync
                 controller.addListener(() {
                   _typeController.text = controller.text;
                 });
                 return TextFormField(
                   controller: controller,
                   focusNode: focusNode,
                   decoration: const InputDecoration(labelText: 'Type (e.g. Excavator)'),
                   validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                 );
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _regNoController,
              decoration: const InputDecoration(labelText: 'Registration No (Optional)'),
            ),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: _ownershipType,
              decoration: const InputDecoration(labelText: 'Ownership'),
              items: _ownershipOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _ownershipType = val);
              },
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Add Machinery'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final success = await ref.read(machineryControllerProvider.notifier).createMachinery(
      name: _nameController.text.trim(),
      type: _typeController.text.trim(),
      registrationNo: _regNoController.text.trim().isEmpty ? null : _regNoController.text.trim(),
      ownershipType: _ownershipType,
    );

    if (success && mounted) {
      context.pop();
      // Refresh list
      ref.invalidate(machineryListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Machinery Added Successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add machinery! Check console logs.'), backgroundColor: Colors.red),
      );
    }
  }
}
