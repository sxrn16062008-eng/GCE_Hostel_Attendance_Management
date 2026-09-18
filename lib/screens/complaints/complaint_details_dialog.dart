import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';

class ComplaintDetailsDialog extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailsDialog({super.key, required this.complaint});

  static Future<void> show(BuildContext context, {required ComplaintModel complaint}) {
    return showDialog(
      context: context,
      builder: (context) => ComplaintDetailsDialog(complaint: complaint),
    );
  }

  @override
  State<ComplaintDetailsDialog> createState() => _ComplaintDetailsDialogState();
}

class _ComplaintDetailsDialogState extends State<ComplaintDetailsDialog> {
  late String _selectedStatus;
  late final TextEditingController _remarksController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.complaint.status;
    _remarksController = TextEditingController(text: widget.complaint.wardenRemarks ?? '');
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _handleUpdateStatus() async {
    setState(() => _isUpdating = true);
    final provider = context.read<HostelDataProvider>();

    try {
      await provider.updateComplaintStatus(
        complaintId: widget.complaint.id,
        status: _selectedStatus,
        wardenRemarks: _remarksController.text.trim().isNotEmpty ? _remarksController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint status updated successfully!'),
            backgroundColor: AppConstants.statusPresentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
    final auth = context.watch<AppAuthProvider>();
    final isWarden = auth.isAdmin;
    final c = widget.complaint;
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(c.createdAt);

    Color statusColor;
    String statusLabel;
    if (c.status == AppConstants.complaintResolved) {
      statusColor = AppConstants.statusPresentColor;
      statusLabel = 'RESOLVED';
    } else if (c.status == AppConstants.complaintInProgress) {
      statusColor = Colors.blue;
      statusLabel = 'IN PROGRESS';
    } else {
      statusColor = AppConstants.statusPendingColor;
      statusLabel = 'PENDING';
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.build_rounded, size: 20, color: statusColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room ${c.roomNumber} (${c.block})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  c.category,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                c.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              // Description Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  c.description,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),

              // Reporter & Timestamp Meta
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Raised by: ${c.createdByName}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (c.createdByPhone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Contact: ${c.createdByPhone}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Warden Remarks / Actions Section
              if (isWarden) ...[
                const Text(
                  'Warden Action & Status Update',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Update Complaint Status',
                    prefixIcon: Icon(Icons.track_changes_rounded, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: AppConstants.complaintPending, child: Text('Pending (Awaiting Action)')),
                    DropdownMenuItem(value: AppConstants.complaintInProgress, child: Text('In Progress (Worker Assigned)')),
                    DropdownMenuItem(value: AppConstants.complaintResolved, child: Text('Resolved (Issue Fixed)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: _remarksController,
                  label: 'Warden Remarks / Resolution Notes',
                  hint: 'e.g. Electrician sent, fan replaced on 10/09.',
                  prefixIcon: Icons.rate_review_outlined,
                  maxLines: 2,
                ),
              ] else if (c.wardenRemarks != null && c.wardenRemarks!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.statusPresentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.statusPresentColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded, size: 16, color: AppConstants.statusPresentColor),
                          SizedBox(width: 6),
                          Text(
                            'Warden Remarks / Resolution',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppConstants.statusPresentColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(c.wardenRemarks!, style: const TextStyle(fontSize: 12, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isWarden ? 'Cancel' : 'Close'),
        ),
        if (isWarden)
          ElevatedButton(
            onPressed: _isUpdating ? null : _handleUpdateStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Save Status'),
          ),
      ],
    );
  }
}
