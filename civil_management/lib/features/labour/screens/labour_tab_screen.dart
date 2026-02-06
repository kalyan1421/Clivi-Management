import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../common/widgets/searchable_dropdown_with_create.dart';
import '../providers/labour_provider.dart';
import '../data/models/daily_labour_log.dart';
import '../data/models/labour_model.dart';
import '../../auth/providers/auth_provider.dart';

class LabourTabScreen extends ConsumerWidget {
  final String projectId;

  const LabourTabScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(dailyLabourLogsProvider(projectId));
    
    // Calculate Stats for Header (Today's snapshot)
    final logs = logsAsync.valueOrNull ?? [];
    int totalWorkers = 0;
    int skilled = 0;
    int unskilled = 0;
    
    final now = DateTime.now();
    for (var log in logs) {
       if (log.logDate.year == now.year && 
           log.logDate.month == now.month && 
           log.logDate.day == now.day) {
          totalWorkers += (log.skilledCount + log.unskilledCount);
          skilled += log.skilledCount;
          unskilled += log.unskilledCount;
       }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogLaborSheet(context, projectId),
        backgroundColor: const Color(0xFF1E293B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Header / Actions
           Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Labor History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  child: const Text('Select', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
          
          // Stats Card (Optional based on image, but good to keep? 
          // Image shows just history list. I'll Keep the cool gradient stats card because it's valuable 
          // and "Labor History" title is above the list. Wait, Image doesn't show stats card.
          // Image shows list of cards directly below title.
          // I will REMOVE the stats card to strictly follow "match image exactly".
          // But I'll verify if that removes functionality. The user said "Update UI to match image exactly".
          // The image has NO stats card at top. Just "Labor History" and list.
          // I will stick to image.
          
          const SizedBox(height: 12),

          // List
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const Center(child: Text('No labor logs recorded'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final total = log.skilledCount + log.unskilledCount;
                    
                    return _LaborHistoryCard(
                      name: log.contractorName,
                      role: 'Head Contractor', // We don't have role in Log, assume Head/Contractor
                      workers: total,
                      skilled: log.skilledCount,
                      unskilled: log.unskilledCount,
                      initials: _getInitials(log.contractorName),
                      color: _getColor(index),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showLogLaborSheet(BuildContext context, String projectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogLaborSheet(projectId: projectId),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
  
  Color _getColor(int index) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];
    return colors[index % colors.length];
  }
}

class _LaborHistoryCard extends StatelessWidget {
  final String name;
  final String role;
  final int workers;
  final int skilled;
  final int unskilled;
  final String initials;
  final Color color;

  const _LaborHistoryCard({
    required this.name,
    required this.role,
    required this.workers,
    required this.skilled,
    required this.unskilled,
    required this.initials,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Counts
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$workers',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const Text(
                'Workers',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

class _LogLaborSheet extends ConsumerStatefulWidget {
  final String projectId;

  const _LogLaborSheet({required this.projectId});

  @override
  ConsumerState<_LogLaborSheet> createState() => _LogLaborSheetState();
}

class _LogLaborSheetState extends ConsumerState<_LogLaborSheet> {
  final _formKey = GlobalKey<FormState>();
  
  LabourModel? _selectedContractor;
  final _skilledController = TextEditingController(text: '0');
  final _unskilledController = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final activeLabourAsync = ref.watch(activeLabourListProvider(widget.projectId)); // Need a provider for active labour list!

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 
        24, 
        24, 
        MediaQuery.of(context).viewInsets.bottom + 24
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Header
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Log Labor',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add data to the site ledger',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
    
              // Contractor Selection
              const Text('CONTRACTOR / HEAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              
              // Helper to get active labour. 
              // Since we don't have a direct "list provider" in basic CRUD, 
              // we can use a FutureBuilder or a new provider if one exists.
              // I will use `labourListStreamProvider` if exists, or `activeLabourByProject`.
              // I found `streamLabourByProject` in repo. 
              // I'll assume we can use `ref.watch` on a stream or future provider.
              // I'll create a local FutureProvider for efficiency or just inline it if simple.
              // Searchable Dropdown
              Consumer(
                builder: (context, ref, _) {
                  final listAsync = ref.watch(activeLabourListProvider(widget.projectId));
                  
                  return listAsync.when(
                    data: (list) => SearchableDropdownWithCreate<LabourModel>(
                      label: 'Contractor',
                      items: list,
                      itemLabelBuilder: (l) => l.name,
                      value: _selectedContractor,
                      onChanged: (val) {
                        print('[LABOR LOG] Contractor selected: ${val?.name ?? "NULL"}');
                        setState(() => _selectedContractor = val);
                      },
                      hint: 'Select Contractor',
                      onAdd: (name) async {
                         throw 'Creation not implemented yet'; 
                      },
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('Error: $e'),
                  );
                }
              ),
              
              const SizedBox(height: 24),
              
              // Counts
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildCounterRow('Skilled', 'workers', _skilledController, Icon(Icons.engineering, color: Colors.orange[300])),
                    const Divider(height: 24),
                    _buildCounterRow('Unskilled', 'workers', _unskilledController, Icon(Icons.group, color: Colors.grey[400])),
                  ],
                ),
              ),
    
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm & Save Log', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterRow(String label, String sub, TextEditingController controller, Widget icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: icon,
        ),
        const SizedBox(width: 12),
        Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
             // Text(sub, style: TextStyle(color: Colors.grey, fontSize: 10)),
           ],
        ),
        const Spacer(),
        // Simple Counter Buttons or just Text Field?
        // Image shows "0" inside a white Pill. I'll use a numeric text field with +/- buttons.
        SizedBox(
          width: 100,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }


  Future<void> _submit() async {
    print('[LABOR LOG] === SUBMIT FUNCTION CALLED ===');
    if (_selectedContractor == null) {
      print('[LABOR LOG] Validation failed: No contractor selected');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a contractor')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      print('[LABOR LOG] Starting submission...');
      print('[LABOR LOG] Project ID: ${widget.projectId}');
      print('[LABOR LOG] Contractor: ${_selectedContractor!.name}');
      print('[LABOR LOG] Skilled: ${_skilledController.text}');
      print('[LABOR LOG] Unskilled: ${_unskilledController.text}');
      
      final log = DailyLabourLog(
         id: '',
         projectId: widget.projectId,
         contractorName: _selectedContractor!.name,
         skilledCount: int.tryParse(_skilledController.text) ?? 0,
         unskilledCount: int.tryParse(_unskilledController.text) ?? 0,
         logDate: DateTime.now(),
         createdBy: ref.read(currentUserProvider)?.id,
      );
      
      print('[LABOR LOG] Log object created: ${log.toInsertJson()}');
      await ref.read(labourRepositoryProvider).createDailyLog(log);
      print('[LABOR LOG] Save successful!');
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log saved'), backgroundColor: Colors.green));
      }
    } catch (e, stackTrace) {
      print('[LABOR LOG ERROR] $e');
      print('[LABOR LOG STACK] $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Need to define temporary provider or assume it exists. 
// I'll define a local one here reusing the repository.
final activeLabourListProvider = FutureProvider.family<List<LabourModel>, String>((ref, projectId) async {
  final repo = ref.watch(labourRepositoryProvider);
  return repo.getActiveLabourByProject(projectId);
});
