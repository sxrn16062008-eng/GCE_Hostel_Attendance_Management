import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class AddMessComplaintDialog extends StatefulWidget {
  final String? initialMealType;

  const AddMessComplaintDialog({super.key, this.initialMealType});

  static Future<void> show(BuildContext context, {String? initialMealType}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMessComplaintDialog(initialMealType: initialMealType),
    );
  }

  @override
  State<AddMessComplaintDialog> createState() => _AddMessComplaintDialogState();
}

class _AddMessComplaintDialogState extends State<AddMessComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedMealType;
  late String _selectedCategory;
  String _selectedSeverity = 'Medium';
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _quickSuggestions = [
    'Dinner served 45+ mins late',
    'Food was cold and undercooked',
    'Shortage of rice & curry during lunch',
    'Drinking water dispenser empty/dirty',
    'Unhygienic dining tables & plates',
    'Scheduled menu item not served',
    'Mess staff behavior / rude response',
    'Breakfast finished early before cutoff',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType ?? AppConstants.messMealTypes.first;
    _selectedCategory = AppConstants.messComplaintCategories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'high':
        return const Color(0xFFF97316);
      case 'critical':
        return const Color(0xFFEF4444);
      default:
        return AppTheme.primaryLight;
    }
  }

  IconData _getMealIcon(String mealType) {
    if (mealType.contains('Breakfast')) return Icons.wb_sunny_outlined;
    if (mealType.contains('Lunch')) return Icons.sunny;
    if (mealType.contains('Snacks')) return Icons.coffee_rounded;
    if (mealType.contains('Dinner')) return Icons.nights_stay_rounded;
    return Icons.restaurant_rounded;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AppAuthProvider>();
      final provider = context.read<HostelDataProvider>();
      final user = auth.currentUser;

      await provider.addMessComplaint(
        mealType: _selectedMealType,
        category: _selectedCategory,
        severity: _selectedSeverity,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        reportedBy: user?.id ?? 'rep_user',
        reportedByName: user?.name ?? 'Hostel Representative',
        reportedByRole: auth.isAdmin ? 'admin' : 'representative',
        reportedByPhone: user?.phone ?? '',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Mess complaint registered successfully!'),
                ),
              ],
            ),
            backgroundColor: AppConstants.statusPresentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: AppConstants.statusAbsentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Colors.deepOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report Mess & Food Issue',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Food quality, serving delay, shortage or hygiene feedback',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Meal Type Selector
              const Text(
                'Meal Type / Session',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AppConstants.messMealTypes.map((meal) {
                    final isSelected = _selectedMealType == meal;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(
                          _getMealIcon(meal),
                          size: 16,
                          color: isSelected ? Colors.white : Colors.deepOrange,
                        ),
                        label: Text(meal),
                        selected: isSelected,
                        selectedColor: Colors.deepOrange,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedMealType = meal);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Issue Category Dropdown
              const Text(
                'Issue Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_rounded, size: 20, color: Colors.deepOrange),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: AppConstants.messComplaintCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              // Urgency / Severity
              const Text(
                'Urgency / Severity Level',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: AppConstants.messComplaintSeverities.map((sev) {
                  final isSelected = _selectedSeverity == sev;
                  final color = _getSeverityColor(sev);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => setState(() => _selectedSeverity = sev),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.2)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sev,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? color : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Quick Suggestions Chips
              const Text(
                'Quick Issue Suggestions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickSuggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion, style: const TextStyle(fontSize: 11)),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    onPressed: () {
                      _titleController.text = suggestion;
                      if (_descController.text.isEmpty) {
                        _descController.text = 'Reported regarding $_selectedMealType: $suggestion.';
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Title Field
              const Text(
                'Complaint Title *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Dinner served 45 mins late / Food spoiled',
                  prefixIcon: const Icon(Icons.title_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a complaint title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              const Text(
                'Detailed Description *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Provide specific details (time, item name, what happened, affected students)...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.description_rounded, size: 20),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please provide issue details';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Mess Complaint',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
