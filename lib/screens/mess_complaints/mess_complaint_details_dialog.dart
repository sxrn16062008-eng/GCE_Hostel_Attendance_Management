import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/mess_complaint_model.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/confirm_dialog.dart';

class MessComplaintDetailsDialog extends StatefulWidget {
  final MessComplaintModel complaint;

  const MessComplaintDetailsDialog({super.key, required this.complaint});

  static Future<void> show(BuildContext context, MessComplaintModel complaint) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MessComplaintDetailsDialog(complaint: complaint),
    );
  }

  @override
  State<MessComplaintDetailsDialog> createState() => _MessComplaintDetailsDialogState();
}

class _MessComplaintDetailsDialogState extends State<MessComplaintDetailsDialog> {
  late String _selectedStatus;
  late final TextEditingController _actionController;
  late final TextEditingController _remarksController;
  bool _isSaving = false;

  final List<String> _wardenActionPresets = [
    'Mess Contractor Warned & Notice Issued',
    'Food Sample Inspected by Warden',
    'Extra Food Prepared & Replenished',
    'Vendor Penalty Levied for Quality Deviation',
    'Strict Serving Timing Enforced',
    'Water Dispenser Cleaned & Refilled',
    'Kitchen & Dining Hall Sanitized',
    'Mess Staff Replaced / Retrained',
    'No Action Required / False Alarm',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.complaint.status;
    _actionController = TextEditingController(text: widget.complaint.wardenAction ?? '');
    _remarksController = TextEditingController(text: widget.complaint.wardenRemarks ?? '');
  }

  @override
  void dispose() {
    _actionController.dispose();
    _remarksController.dispose();
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'under_review':
        return const Color(0xFF3B82F6);
      case 'action_taken':
        return const Color(0xFF8B5CF6);
      case 'resolved':
        return const Color(0xFF10B981);
      case 'dismissed':
        return const Color(0xFF6B7280);
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'under_review':
        return 'Under Review';
      case 'action_taken':
        return 'Action Taken';
      case 'resolved':
        return 'Resolved';
      case 'dismissed':
        return 'Dismissed';
      default:
        return status;
    }
  }

  Future<void> _updateStatus() async {
    setState(() => _isSaving = true);
    try {
      final provider = context.read<HostelDataProvider>();
      await provider.updateMessComplaintStatus(
        complaintId: widget.complaint.id,
        status: _selectedStatus,
        wardenAction: _actionController.text.trim().isNotEmpty ? _actionController.text.trim() : null,
        wardenRemarks: _remarksController.text.trim().isNotEmpty ? _remarksController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mess complaint status updated to "${_formatStatus(_selectedStatus)}"'),
            backgroundColor: AppConstants.statusPresentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppConstants.statusAbsentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteComplaint() async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Complaint?',
      message: 'Are you sure you want to remove this mess complaint?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirm == true && mounted) {
      final provider = context.read<HostelDataProvider>();
      await provider.deleteMessComplaint(widget.complaint.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mess complaint deleted'),
            backgroundColor: AppConstants.statusPresentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();
    final isWarden = auth.isAdmin;
    final c = widget.complaint;
    final sevColor = _getSeverityColor(c.severity);
    final statusColor = _getStatusColor(c.status);
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

            // Header with Meal Badge & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text(
                        c.title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.mealType,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: sevColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${c.severity} Urgency',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: sevColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatStatus(c.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isWarden || auth.currentUser?.id == c.reportedBy)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    tooltip: 'Delete Complaint',
                    onPressed: _deleteComplaint,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Metadata card (Reported by & Time & Category)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Reported By: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Expanded(
                        child: Text(
                          '${c.reportedByName} (${c.reportedByRole.toUpperCase()})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Category: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Expanded(
                        child: Text(
                          c.category,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Reported: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(c.createdAt),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Complaint Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                c.description,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 18),

            // Warden Action & Remarks Section
            if (!isWarden) ...[
              // Representative View of Warden Action
              if (c.wardenAction != null || c.wardenRemarks != null || c.isResolved) ...[
                const Text(
                  'Warden Action & Resolution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: isDark ? 0.4 : 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (c.wardenAction != null && c.wardenAction!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.gavel_rounded, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.wardenAction!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (c.wardenRemarks != null && c.wardenRemarks!.isNotEmpty) ...[
                        Text(
                          c.wardenRemarks!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (c.resolvedAt != null)
                        Text(
                          'Resolved on ${DateFormat('dd MMM yyyy, hh:mm a').format(c.resolvedAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_empty_rounded, size: 16, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Awaiting warden review and action on this mess issue.',
                          style: TextStyle(fontSize: 12, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Warden Interactive Action Form
              const Divider(height: 24),
              const Text(
                'Warden Action & Status Update',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),

              // Status Selector
              const Text('Update Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.flag_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending Review')),
                  DropdownMenuItem(value: 'under_review', child: Text('Under Review')),
                  DropdownMenuItem(value: 'action_taken', child: Text('Action Taken')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'dismissed', child: Text('Dismissed / False Alarm')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),
              const SizedBox(height: 12),

              // Action Presets
              const Text('Official Action Taken', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _wardenActionPresets.take(5).map((preset) {
                  return ActionChip(
                    label: Text(preset, style: const TextStyle(fontSize: 10.5)),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    onPressed: () => _actionController.text = preset,
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _actionController,
                decoration: InputDecoration(
                  hintText: 'e.g. Mess Contractor Warned / Food Inspected',
                  prefixIcon: const Icon(Icons.gavel_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),

              // Remarks
              const Text('Warden Remarks & Feedback (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter internal notes or response to representative...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Icon(Icons.comment_outlined, size: 18),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 20),

              // Save Action Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _updateStatus,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(
                  _isSaving ? 'Updating...' : 'Save Warden Action & Status',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
