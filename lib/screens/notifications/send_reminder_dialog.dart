import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class SendReminderDialog extends StatefulWidget {
  const SendReminderDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const SendReminderDialog(),
    );
  }

  @override
  State<SendReminderDialog> createState() => _SendReminderDialogState();
}

class _SendReminderDialogState extends State<SendReminderDialog> {
  final _titleController = TextEditingController(text: 'Hostel Attendance Reminder');
  final _messageController = TextEditingController(
    text: 'Dear Representative, please mark tonight\'s hostel attendance for your assigned rooms before 9:00 PM.',
  );
  bool _isLoading = false;

  final List<String> _quickTemplates = [
    'Dear Representative, please mark tonight\'s hostel attendance for your assigned rooms before 9:00 PM.',
    'Urgent: Attendance for several rooms is still pending today. Please complete the roll call immediately.',
    'Night roll call reminder: Ensure all hostel students are accounted for and report any absentees.',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both title and message.'),
          backgroundColor: AppConstants.statusAbsentColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AppAuthProvider>();
    final provider = context.read<HostelDataProvider>();
    final senderName = (auth.currentUser?.name.isNotEmpty == true)
        ? auth.currentUser!.name
        : 'Warden';

    try {
      await provider.sendAttendanceReminder(
        title: title,
        message: message,
        senderName: senderName,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Attendance reminder notification sent successfully to all representatives!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppConstants.statusPresentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reminder: $e'),
            backgroundColor: AppConstants.statusAbsentColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HostelDataProvider>();
    final summary = provider.getTodaySummary();
    final totalReps = provider.representatives.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notification_important_rounded,
                      color: Colors.amber,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Remind Representatives',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Broadcast instant notification & push alert',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Summary Info Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.primaryLight),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Targeting all active Representatives ($totalReps reps) • ${summary.notMarkedCount} students unmarked today',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Title Field
              const Text(
                'Notification Title',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.title_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Message Field
              const Text(
                'Reminder Message',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(Icons.message_outlined, size: 20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),

              // Quick Templates
              const Text(
                'Quick Templates:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Standard 9 PM Reminder', style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() {
                      _messageController.text = _quickTemplates[0];
                    }),
                  ),
                  ActionChip(
                    label: const Text('Urgent Pending Alert', style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() {
                      _messageController.text = _quickTemplates[1];
                    }),
                  ),
                  ActionChip(
                    label: const Text('Night Roll Call', style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() {
                      _messageController.text = _quickTemplates[2];
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleSend,
                      icon: _isLoading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.send_rounded, size: 18),
                      label: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            )
                          : const Text(
                              'Send Reminder',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
