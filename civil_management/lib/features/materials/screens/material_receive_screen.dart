import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
import '../data/models/material_log.dart';

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
    // Bill amount can be 0 (e.g. sample?) but typically should be >= 0
    final amount = double.tryParse(billAmountController.text) ?? 0;
    
    return selectedMaterial != null &&
           selectedSupplier != null &&
           quantityController.text.isNotEmpty &&
           qty > 0 && 
           amount >= 0 && 
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
  final bool isEmbedded;
  
  const MaterialReceiveScreen({
    super.key, 
    required this.projectId,
    this.isEmbedded = false,
  });

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
        // Reset forms instead of popping
        setState(() {
          for (var e in _entries) e.dispose();
          _entries.clear();
          _addNewEntry();
        });
        // Refresh the logs provider
        ref.invalidate(materialLogsProvider(pid));
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
    final bodyContent = _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isEmbedded) ...[
                     const Text('Add data to the site ledger', style: TextStyle(color: Colors.grey)),
                     const SizedBox(height: 16),
                  ],
                  
                  // Dynamic Forms
                  ..._entries.asMap().entries.map((item) {
                    final index = item.key;
                    final entry = item.value;
                    return _EntryCard(
                      key: entry.key,
                      entry: entry,
                      index: index,
                      projectId: widget.projectId,
                      onRemove: () => _removeEntry(index),
                      isRemovable: _entries.length > 1,
                    );
                  }),
                  
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  AppButton(
                    text: 'Save Material Entry',
                    onPressed: _submitAll,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _addNewEntry,
                      child: const Text('Add New Material', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // History Section
                  const _MaterialsHistoryHeader(),
                  const SizedBox(height: 12),
                  _MaterialsHistoryList(projectId: widget.projectId),
                ],
              ),
            );

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Materials'),
        centerTitle: false,
      ),
      body: bodyContent,
    );
  }
}

class _MaterialsHistoryHeader extends StatelessWidget {
  const _MaterialsHistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Materials History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Recent verified logs', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        OutlinedButton(
          onPressed: () {
            // Logic to filter or view all? Currently just visual as per design
          },
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: const Text('Select', style: TextStyle(color: Colors.black)),
        )
      ],
    );
  }
}

class _MaterialsHistoryList extends ConsumerWidget {
  final String projectId;
  const _MaterialsHistoryList({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We reuse the existing FutureProvider associated with logs
    // Note: Assuming materialLogsProvider is defined in stock_provider.dart
    // If not, we should have added it. I recall seeing it in the stock_provider.dart view.
    final logsAsync = ref.watch(materialLogsProvider(projectId));
    
    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('No recent logs'),
          ));
        }
        // Show top 5 recent logs for summary
        final displayLogs = logs.take(5).toList();
        
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayLogs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final log = displayLogs[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.stockItem?.name ?? 'Unknown Material',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (log.grade != null && log.grade!.isNotEmpty)
                          Text(
                            'GRADE ${log.grade}',
                            style: const TextStyle(
                                color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.grey, shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              log.supplier?.name ?? 'Unknown Vendor',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                             TextSpan(
                               text: '${log.quantity.toStringAsFixed(0)} ', 
                               style: const TextStyle(
                                 color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16
                               )
                             ),
                             TextSpan(
                               text: log.stockItem?.unit ?? '',
                               style: const TextStyle(
                                 color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold
                               )
                             )
                          ]
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        DateFormat('MMM dd').format(log.loggedAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
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
    'CFT',
    'Cum',
    'Kg',
    'Liters',
    'Ton',
    'Units',
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
      
      // Filter distinct by name to avoid duplicates in dropdown
      final uniqueMaterials = <String, StockItem>{};
      for (var item in materials) {
        if (!uniqueMaterials.containsKey(item.name.toLowerCase())) {
          uniqueMaterials[item.name.toLowerCase()] = item;
        }
      }
      
      if (mounted) setState(() => _projectMaterials = uniqueMaterials.values.toList());
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isRemovable)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              
            // 1. MATERIAL DROPDOWN
            SearchableDropdownWithCreate<StockItem>(
              label: 'Material Name',
              hint: '-- Select Material --',
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
                final newItem = await ref.read(stockRepositoryProvider).getOrCreateStockItem(
                  projectId: widget.projectId,
                  name: name,
                  unit: 'Units', // Default
                );
                await _fetchMaterials(); 
                return newItem;
              },
            ),
            const SizedBox(height: 16),
            
            // 2. GRADE DROPDOWN
            SearchableDropdownWithCreate<MaterialGrade>(
              label: 'Grade / Type',
              hint: 'Cement, Iron, etc.',
              value: entry.selectedGrade,
              items: _availableGrades,
              isLoading: _loadingGrades,
              itemLabelBuilder: (g) => g.gradeName,
              onChanged: (g) {
                setState(() => entry.selectedGrade = g);
              },
              onAdd: (gradeName) async {
                if (entry.selectedMaterial == null) throw 'Select Material first';
                
                final masterRepo = ref.read(materialMasterRepositoryProvider);
                var masterList = await masterRepo.searchMaterials(entry.selectedMaterial!.name);
                MaterialMaster master;
                if (masterList.isEmpty) {
                  master = await masterRepo.addMaterialMaster(entry.selectedMaterial!.name);
                } else {
                  try {
                    master = masterList.firstWhere(
                      (m) => m.name.toLowerCase() == entry.selectedMaterial!.name.toLowerCase()
                    );
                  } catch (e) {
                    master = await masterRepo.addMaterialMaster(entry.selectedMaterial!.name);
                  }
                }
                
                final newGradeData = await masterRepo.addMaterialGrade(materialId: master.id, gradeName: gradeName);
                final newGrade = MaterialGrade.fromJson(newGradeData);
                await _fetchGrades(entry.selectedMaterial!.name);
                return newGrade;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: entry.quantityController,
                    label: 'Quantity',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unitItems.contains(entry.unitController.text)
                        ? entry.unitController.text
                        : null,
                    decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: _unitItems
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setState(() => entry.unitController.text = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

             // 3. VENDOR DROPDOWN
             SearchableDropdownWithCreate<SupplierModel>(
                label: 'Vendor / Supplier', 
                hint: 'Enter vendor name',
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

             const SizedBox(height: 16),
             
             DropdownButtonFormField<String>(
                value: entry.paymentType,
                decoration: const InputDecoration(
                  labelText: 'Payment Type', 
                  hintText: '-- Select Payment Type --',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                items: ['Cash', 'Online', 'Cheque', 'Credit']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => entry.paymentType = val);
                },
              ),
              
              const SizedBox(height: 16),

             CurrencyTextField(
               controller: entry.billAmountController,
               label: 'Bill amount',
               // prefixText is handled internally by CurrencyTextField with prefixIcon
             ),
          ],
        ),
      ),
    );
  }
}
