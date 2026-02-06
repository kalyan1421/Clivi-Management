import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/master_data_provider.dart';
import '../providers/stock_provider.dart'; 
import '../data/models/stock_item.dart';
import '../data/models/material_grade_model.dart';
import '../../inventory/data/models/supplier_model.dart';
import '../../common/widgets/searchable_dropdown_with_create.dart';
import '../data/models/material_master_model.dart';

// Model to hold form state for each entry
class MaterialEntryForm {
  // Use unique key to force rebuild when removing/adding
  final Key key = UniqueKey();
  
  // Data holders
  StockItem? selectedMaterial;
  MaterialGrade? selectedGrade;
  SupplierModel? selectedSupplier;
  
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController billAmountController = TextEditingController();
  String paymentType = 'Cash'; // Default
  
  // Validation helper
  bool isValid() {
    final qty = double.tryParse(quantityController.text) ?? 0;
    final amount = double.tryParse(billAmountController.text) ?? 0;
    
    return selectedMaterial != null &&
           selectedSupplier != null &&
           quantityController.text.isNotEmpty &&
           qty > 0 && // Prevent 0 quantity
           amount >= 0 && // Allow 0 bill amount but not negative
           unitController.text.isNotEmpty &&
           billAmountController.text.isNotEmpty;
  }
  
  void dispose() {
    quantityController.dispose();
    unitController.dispose();
    billAmountController.dispose();
  }
}

class MaterialReceiveScreen extends ConsumerStatefulWidget {
  final String projectId;
  const MaterialReceiveScreen({super.key, required this.projectId});

  @override
  ConsumerState<MaterialReceiveScreen> createState() => _MaterialReceiveScreenState();
}

class _MaterialReceiveScreenState extends ConsumerState<MaterialReceiveScreen> {
  final List<MaterialEntryForm> _entries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addNewEntry(); // Start with one entry
  }

  @override
  void dispose() {
    for (var entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addNewEntry() {
    setState(() {
      _entries.add(MaterialEntryForm());
    });
  }

  void _removeEntry(int index) {
    if (_entries.length > 1) {
      setState(() {
        _entries[index].dispose();
        _entries.removeAt(index);
      });
    }
  }

  Future<void> _submitAll() async {
    // 1) Validate entries first
    for (final entry in _entries) {
      if (!entry.isValid()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please fill all required fields in all entries')),
          );
        }
        return;
      }
    }

    // 2) Validate projectId BEFORE calling backend
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    final pid = widget.projectId.trim();

    if (!uuidRegex.hasMatch(pid) ||
        pid == '00000000-0000-0000-0000-000000000000') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Invalid Project ID. Please open from Projects screen again.\n$pid')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final stockRepo = ref.read(stockRepositoryProvider);

      for (final entry in _entries) {
        // IMPORTANT: Send null grade if user didn’t select
        final grade = (entry.selectedGrade?.gradeName.trim().isEmpty ?? true)
            ? null
            : entry.selectedGrade!.gradeName.trim();

        await stockRepo.logMaterialInward(
          projectId: pid,
          stockItemName: entry.selectedMaterial!.name,
          stockItemGrade: grade,
          stockItemUnit: entry.unitController.text.trim(),
          quantity: double.parse(entry.quantityController.text),
          supplierId: entry.selectedSupplier!.id,
          billAmount: double.parse(entry.billAmountController.text),
          paymentType: entry.paymentType,
          notes: null, // notes is not available in the form
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Materials received successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save material: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Materials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _submitAll,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length + 1, // +1 for "Add New" button
              itemBuilder: (context, index) {
                if (index == _entries.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: OutlinedButton.icon(
                      onPressed: _addNewEntry,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Another Material'),
                    ),
                  );
                }
                return _EntryCard(
                  key: _entries[index].key, // Use UniqueKey
                  entry: _entries[index],
                  index: index,
                  projectId: widget.projectId,
                  onRemove: () => _removeEntry(index),
                  isRemovable: _entries.length > 1,
                );
              },
            ),
    );
  }
}

class _EntryCard extends ConsumerStatefulWidget {
  final MaterialEntryForm entry;
  final int index;
  final String projectId;
  final VoidCallback onRemove;
  final bool isRemovable;

  const _EntryCard({
    super.key,
    required this.entry,
    required this.index,
    required this.projectId,
    required this.onRemove,
    required this.isRemovable,
  });

  @override
  ConsumerState<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends ConsumerState<_EntryCard> {
  // Local state for async fetches in dropdowns
  List<StockItem> _projectMaterials = [];
  List<MaterialGrade> _availableGrades = [];
  List<SupplierModel> _projectSuppliers = [];
  bool _loadingMaterials = false;
  bool _loadingGrades = false;
  bool _loadingSuppliers = false;

  final List<String> _unitItems = const [
    'Bags',
    'Kg',
    'Ton',
    'CFT',
    'Liters',
    'Units',
    'Cum'
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    _fetchMaterials();
    _fetchSuppliers();
  }

  Future<void> _fetchMaterials() async {
    setState(() => _loadingMaterials = true);
    try {
      final materials = await ref.read(stockRepositoryProvider).getStockItemsByProject(widget.projectId);
      if (mounted) setState(() => _projectMaterials = materials);
    } catch (e) {
      debugPrint('Error fetching materials: $e');
    } finally {
      if (mounted) setState(() => _loadingMaterials = false);
    }
  }

  Future<void> _fetchSuppliers() async {
    setState(() => _loadingSuppliers = true);
    try {
      final suppliers = await ref.read(stockRepositoryProvider).getProjectSuppliers(widget.projectId);
      if (mounted) setState(() => _projectSuppliers = suppliers);
    } catch (e) {
      debugPrint('Error fetching suppliers: $e');
    } finally {
      if (mounted) setState(() => _loadingSuppliers = false);
    }
  }

  Future<void> _fetchGrades(String materialName) async {
    setState(() => _loadingGrades = true);
    try {
      final grades = await ref.read(materialMasterRepositoryProvider).getGradesForMaterialName(materialName);
      if (mounted) setState(() => _availableGrades = grades);
    } catch (e) {
       debugPrint('Error fetching grades: $e');
       if (mounted) setState(() => _availableGrades = []);
    } finally {
      if (mounted) setState(() => _loadingGrades = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Entry #${widget.index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (widget.isRemovable)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // 1. MATERIAL DROPDOWN
            SearchableDropdownWithCreate<StockItem>(
              label: 'Material Name',
              hint: 'Select or Add Material',
              value: entry.selectedMaterial,
              items: _projectMaterials,
              isLoading: _loadingMaterials,
              itemLabelBuilder: (item) => item.name,
              onChanged: (item) {
                setState(() {
                  entry.selectedMaterial = item;
                  entry.selectedGrade = null; // Reset grade
                  entry.unitController.text = item?.unit ?? '';
                  _availableGrades = []; // Clear old grades
                });
                if (item != null) {
                  _fetchGrades(item.name);
                }
              },
              onAdd: (name) async {
                // Determine default unit from user or constant? 
                // Currently user has to type unit in the form. But repository needs it.
                // We'll pass a default 'Units' or try to capture it. 
                // For simplified flow, we create the StockItem here with a temporary unit, 
                // but the user can edit the unit field below which updates the Log, 
                // but stock_item.unit is set once.
                // Better approach: Let Repo handle creation or update unit if null.
                // Here we just create the item wrapper.
                final newItem = await ref.read(stockRepositoryProvider).getOrCreateStockItem(
                  projectId: widget.projectId,
                  name: name,
                  unit: 'Units', // Default, user can update logs
                  // Wait, if we create it here, we should probably prompt for Unit?
                  // For now, let's assume 'Units' and user sets logs. 
                  // If we want detailed creation loop, we need a dialog.
                  // User request: "Auto-select the newly added material".
                );
                
                // Add to master silently for global awareness? 
                // Trigger `sync_material_master` handles this.
                
                await _fetchMaterials(); // Refresh list to include new
                
                // Return the specific item from the refreshed list (or just the newItem)
                return newItem;
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // 2. GRADE DROPDOWN
                Expanded(
                  child: SearchableDropdownWithCreate<MaterialGrade>(
                    label: 'Grade / Type',
                    hint: 'Select or Add',
                    value: entry.selectedGrade,
                    items: _availableGrades,
                    isLoading: _loadingGrades,
                    itemLabelBuilder: (g) => g.gradeName,
                    onChanged: (g) {
                      setState(() => entry.selectedGrade = g);
                    },
                    validator: (val) => null, // Optional
                    onAdd: (gradeName) async {
                      if (entry.selectedMaterial == null) throw 'Select Material first';
                      
                      // We need material ID for master grades table
                      // Helper logic: find master ID by name, then insert.
                      // First ensure master exists for this name.
                      final masterRepo = ref.read(materialMasterRepositoryProvider);
                      
                      // 1. Get/Create Master
                      var masterList = await masterRepo.searchMaterials(entry.selectedMaterial!.name);
                      MaterialMaster master;
                      if (masterList.isEmpty) {
                        master = await masterRepo.addMaterialMaster(entry.selectedMaterial!.name);
                      } else {
                        // Exact match check
                        try {
                          master = masterList.firstWhere(
                            (m) => m.name.toLowerCase() == entry.selectedMaterial!.name.toLowerCase()
                          );
                        } catch (e) {
                          master = await masterRepo.addMaterialMaster(entry.selectedMaterial!.name);
                        }
                      }
                      
                      // 2. Add Grade
                      final newGradeData = await masterRepo.addMaterialGrade(materialId: master.id, gradeName: gradeName);
                      final newGrade = MaterialGrade.fromJson(newGradeData);
                      await _fetchGrades(entry.selectedMaterial!.name);
                      return newGrade;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: entry.quantityController,
                    label: 'Quantity',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                 Expanded(
                   child: DropdownButtonFormField<String>(
                     value: _unitItems.contains(entry.unitController.text)
                         ? entry.unitController.text
                         : null,
                     decoration: const InputDecoration(
                         labelText: 'Unit', border: OutlineInputBorder()),
                     items: _unitItems
                         .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                         .toList(),
                     onChanged: (val) {
                       if (val != null)
                         setState(() => entry.unitController.text = val);
                     },
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: DropdownButtonFormField<String>(
                    value: entry.paymentType,
                    decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
                    items: ['Cash', 'Online', 'Cheque', 'Credit']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => entry.paymentType = val);
                    },
                  ),
                 ),
              ],
            ),
             const SizedBox(height: 12),

             // 3. VENDOR DROPDOWN
             SearchableDropdownWithCreate<SupplierModel>(
                label: 'Vendor / Supplier', 
                hint: 'Select or Add Vendor',
                value: entry.selectedSupplier,
                items: _projectSuppliers,
                isLoading: _loadingSuppliers,
                itemLabelBuilder: (s) => s.name,
                onChanged: (s) => setState(() => entry.selectedSupplier = s),
                onAdd: (name) async {
                   final newSupplier = await ref.read(stockRepositoryProvider).addProjectSupplier(widget.projectId, name);
                   await _fetchSuppliers();
                   return newSupplier;
                },
             ),

             const SizedBox(height: 12),
             
             CustomTextField(
               controller: entry.billAmountController,
               label: 'Bill Amount (₹)',
               keyboardType: TextInputType.number,
             ),
          ],
        ),
      ),
    );
  }
}
