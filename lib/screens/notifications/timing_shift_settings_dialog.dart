import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/reminder_schedule_model.dart';
import '../../services/notification_service.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class TimingShiftSettingsDialog extends StatefulWidget {
  const TimingShiftSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const TimingShiftSettingsDialog(),
    );
  }

  @override
  State<TimingShiftSettingsDialog> createState() =>
      _TimingShiftSettingsDialogState();
}

class _TimingShiftSettingsDialogState extends State<TimingShiftSettingsDialog> {
  late TextEditingController _shiftNameController;
  late TextEditingController _titleController;
  late TextEditingController _messageController;

  late TimeOfDay _scheduledTime;
  late TimeOfDay _shiftStartTime;
  late TimeOfDay _shiftEndTime;
  late bool _isEnabled;

  bool _isSaving = false;
  bool _isTesting = false;
  bool _isSendingInstant = false;
  bool _autoSyncShiftWindow = true;

  // Preset quick times for easy 1-tap selection
  final List<TimeOfDay> _presetTimes = const [
    TimeOfDay(hour: 19, minute: 30), // 7:30 PM
    TimeOfDay(hour: 20, minute: 0),  // 8:00 PM
    TimeOfDay(hour: 20, minute: 30), // 8:30 PM
    TimeOfDay(hour: 21, minute: 0),  // 9:00 PM
    TimeOfDay(hour: 21, minute: 30), // 9:30 PM
    TimeOfDay(hour: 22, minute: 0),  // 10:00 PM
  ];

  final List<Map<String, dynamic>> _quickTemplates = [
    {
      'name': 'Standard Night (8:30 PM)',
      'shiftName': 'Night Roll Call',
      'scheduled': const TimeOfDay(hour: 20, minute: 30),
      'start': const TimeOfDay(hour: 20, minute: 0),
      'end': const TimeOfDay(hour: 21, minute: 30),
      'title': 'Hostel Night Attendance Reminder',
      'message':
          'Dear Representative, please mark attendance for all students in your assigned rooms before 9:30 PM.',
    },
    {
      'name': 'Curfew Roll Call (9:00 PM)',
      'shiftName': 'Curfew Verification',
      'scheduled': const TimeOfDay(hour: 21, minute: 0),
      'start': const TimeOfDay(hour: 20, minute: 30),
      'end': const TimeOfDay(hour: 22, minute: 0),
      'title': 'Urgent: Complete Night Attendance',
      'message':
          'Curfew verification cutoff is at 10:00 PM. Verify all students and record absentees promptly.',
    },
    {
      'name': 'Evening Shift (7:30 PM)',
      'shiftName': 'Evening Shift',
      'scheduled': const TimeOfDay(hour: 19, minute: 30),
      'start': const TimeOfDay(hour: 19, minute: 0),
      'end': const TimeOfDay(hour: 20, minute: 30),
      'title': 'Evening Attendance Reminder',
      'message':
          'Please complete today\'s evening hostel attendance check and record any authorized leave slips.',
    },
  ];

  @override
  void initState() {
    super.initState();
    final current = context.read<HostelDataProvider>().reminderSchedule;

    _shiftNameController = TextEditingController(text: current.shiftName);
    _titleController = TextEditingController(text: current.title);
    _messageController = TextEditingController(text: current.message);

    _scheduledTime = current.scheduledTimeOfDay;
    _shiftStartTime = current.shiftStartTimeOfDay;
    _shiftEndTime = current.shiftEndTimeOfDay;
    _isEnabled = current.isEnabled;
  }

  @override
  void dispose() {
    _shiftNameController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final dt = DateTime(2026, 1, 1, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  /// Adjusts scheduled time by minutes (positive or negative)
  void _adjustScheduledMinutes(int deltaMinutes) {
    int totalMinutes = _scheduledTime.hour * 60 + _scheduledTime.minute + deltaMinutes;
    // Wrap around 24 hours
    totalMinutes = (totalMinutes % (24 * 60) + (24 * 60)) % (24 * 60);

    final newHour = totalMinutes ~/ 60;
    final newMin = totalMinutes % 60;

    setState(() {
      _scheduledTime = TimeOfDay(hour: newHour, minute: newMin);
      if (_autoSyncShiftWindow) {
        _syncShiftWindowFromScheduledTime();
      }
    });
  }

  void _setScheduledTime(TimeOfDay newTime) {
    setState(() {
      _scheduledTime = newTime;
      if (_autoSyncShiftWindow) {
        _syncShiftWindowFromScheduledTime();
      }
    });
  }

  void _syncShiftWindowFromScheduledTime() {
    // Start is 30 mins before or at scheduled time, end is 1 hr after scheduled time
    int schedMin = _scheduledTime.hour * 60 + _scheduledTime.minute;
    int startMin = (schedMin - 30 + (24 * 60)) % (24 * 60);
    int endMin = (schedMin + 60) % (24 * 60);

    _shiftStartTime = TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60);
    _shiftEndTime = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);
  }

  String _calculateCountdownText() {
    final now = DateTime.now();
    final schedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    Duration diff = schedDateTime.difference(now);
    if (diff.isNegative) {
      // It will trigger tomorrow
      final tomorrow = schedDateTime.add(const Duration(days: 1));
      diff = tomorrow.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return 'Tomorrow at ${_formatTimeOfDay(_scheduledTime)} (in ${hours}h ${minutes}m)';
    } else {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours == 0 && minutes == 0) {
        return 'Today at ${_formatTimeOfDay(_scheduledTime)} (within 1 min)';
      }
      return 'Today at ${_formatTimeOfDay(_scheduledTime)} (in ${hours}h ${minutes}m)';
    }
  }

  Future<void> _pickTime({
    required BuildContext context,
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onPicked,
    required String helpText,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: helpText,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _handleTestNotification() async {
    setState(() => _isTesting = true);
    try {
      await NotificationService.instance.testNotificationNow(
        title: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : '🔔 Daily Attendance Reminder',
        body: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : 'Sound & banner test for ${_formatTimeOfDay(_scheduledTime)} attendance notification.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Test alert sent to your device! Check status bar and sound.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppConstants.statusPresentColor,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notification failed: $e'),
            backgroundColor: AppConstants.statusAbsentColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _handleSaveSchedule() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final shiftName = _shiftNameController.text.trim();

    if (title.isEmpty || message.isEmpty || shiftName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in shift name, title, and message.'),
          backgroundColor: AppConstants.statusAbsentColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final auth = context.read<AppAuthProvider>();
    final provider = context.read<HostelDataProvider>();
    final wardenName = auth.currentUser?.name ?? 'Chief Warden';

    final updated = ReminderScheduleModel(
      id: 'default_schedule',
      shiftName: shiftName,
      scheduledHour: _scheduledTime.hour,
      scheduledMinute: _scheduledTime.minute,
      shiftStartHour: _shiftStartTime.hour,
      shiftStartMinute: _shiftStartTime.minute,
      shiftEndHour: _shiftEndTime.hour,
      shiftEndMinute: _shiftEndTime.minute,
      title: title,
      message: message,
      isEnabled: _isEnabled,
      updatedBy: wardenName,
      updatedAt: DateTime.now(),
    );

    try {
      await provider.updateReminderSchedule(updated);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daily attendance reminder scheduled at ${_formatTimeOfDay(_scheduledTime)} daily!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppConstants.statusPresentColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save schedule: $e'),
            backgroundColor: AppConstants.statusAbsentColor,
          ),
        );
      }
    }
  }

  Future<void> _handleInstantBroadcast() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide title and message for broadcast.'),
          backgroundColor: AppConstants.statusAbsentColor,
        ),
      );
      return;
    }

    setState(() => _isSendingInstant = true);

    final auth = context.read<AppAuthProvider>();
    final provider = context.read<HostelDataProvider>();
    final wardenName = auth.currentUser?.name ?? 'Chief Warden';

    try {
      await provider.sendAttendanceReminder(
        title: title,
        message: message,
        senderName: wardenName,
      );

      if (mounted) {
        setState(() => _isSendingInstant = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Instant notification sent immediately to all representatives!'),
            backgroundColor: AppConstants.statusPresentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingInstant = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error broadcasting instant alert: $e'),
            backgroundColor: AppConstants.statusAbsentColor,
          ),
        );
      }
    }
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _shiftNameController.text = template['shiftName'] as String;
      _scheduledTime = template['scheduled'] as TimeOfDay;
      _shiftStartTime = template['start'] as TimeOfDay;
      _shiftEndTime = template['end'] as TimeOfDay;
      _titleController.text = template['title'] as String;
      _messageController.text = template['message'] as String;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalReps =
        context.watch<HostelDataProvider>().representatives.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance Notification Timing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Set daily reminder time & roll call shift window',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
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
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Toggle Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isEnabled
                            ? AppTheme.primaryLight.withValues(alpha: 0.1)
                            : (isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isEnabled
                              ? AppTheme.primaryLight.withValues(alpha: 0.35)
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_rounded,
                            color: _isEnabled
                                ? AppTheme.primaryLight
                                : Colors.grey,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEnabled
                                      ? 'Daily Automatic Alarm: ENABLED'
                                      : 'Daily Automatic Alarm: DISABLED',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _isEnabled
                                        ? AppTheme.primaryLight
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isEnabled
                                      ? 'Will ring for $totalReps reps at ${_formatTimeOfDay(_scheduledTime)} daily.'
                                      : 'No scheduled reminders will be triggered.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isEnabled,
                            activeTrackColor: AppTheme.primaryLight,
                            onChanged: (val) {
                              setState(() => _isEnabled = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Daily Notification Time Card (Centerpiece)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: isDark ? 0.4 : 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.alarm_rounded,
                                      color: Colors.amber, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Daily Notification Time',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.amber[200] : const Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _pickTime(
                                  context: context,
                                  initialTime: _scheduledTime,
                                  helpText: 'Select Notification Sending Time',
                                  onPicked: _setScheduledTime,
                                ),
                                icon: const Icon(Icons.access_time_rounded, size: 14),
                                label: const Text('Clock Dial', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? Colors.amber[300] : const Color(0xFF92400E),
                                  side: BorderSide(
                                    color: Colors.amber.withValues(alpha: 0.5),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Large Time Display
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                _formatTimeOfDay(_scheduledTime),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Quick Step Buttons (-30m, -15m, -5m, +5m, +15m, +30m)
                          Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildStepChip('-30m', () => _adjustScheduledMinutes(-30), isDark),
                                  const SizedBox(width: 6),
                                  _buildStepChip('-15m', () => _adjustScheduledMinutes(-15), isDark),
                                  const SizedBox(width: 6),
                                  _buildStepChip('-5m', () => _adjustScheduledMinutes(-5), isDark),
                                  const SizedBox(width: 8),
                                  _buildStepChip('+5m', () => _adjustScheduledMinutes(5), isDark),
                                  const SizedBox(width: 6),
                                  _buildStepChip('+15m', () => _adjustScheduledMinutes(15), isDark),
                                  const SizedBox(width: 6),
                                  _buildStepChip('+30m', () => _adjustScheduledMinutes(30), isDark),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Quick Preset Pills
                          Text(
                            'Quick Preset Times:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[400] : const Color(0xFF78350F),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _presetTimes.map((preset) {
                              final isSelected = _scheduledTime.hour == preset.hour &&
                                  _scheduledTime.minute == preset.minute;
                              return ChoiceChip(
                                label: Text(
                                  _formatTimeOfDay(preset),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: Colors.amber[800],
                                onSelected: (_) => _setScheduledTime(preset),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),

                          // Next Alert Countdown Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined,
                                    size: 16, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isEnabled
                                        ? 'Next Alert: ${_calculateCountdownText()}'
                                        : 'Alert is currently disabled',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _isEnabled
                                          ? (isDark ? Colors.grey[200] : Colors.grey[800])
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Templates Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Preset Shifts',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '1-tap auto fill',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _quickTemplates.map((tpl) {
                        return ActionChip(
                          avatar: const Icon(Icons.flash_on_rounded, size: 14),
                          label: Text(tpl['name'] as String,
                              style: const TextStyle(fontSize: 11)),
                          onPressed: () => _applyTemplate(tpl),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Shift Window (Start & End Time)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Attendance Shift Window',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _autoSyncShiftWindow,
                              onChanged: (v) {
                                setState(() {
                                  _autoSyncShiftWindow = v ?? true;
                                  if (_autoSyncShiftWindow) {
                                    _syncShiftWindowFromScheduledTime();
                                  }
                                });
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(
                              'Auto-sync',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _pickTime(
                              context: context,
                              initialTime: _shiftStartTime,
                              helpText: 'Select Shift Start Time',
                              onPicked: (t) {
                                setState(() {
                                  _shiftStartTime = t;
                                  _autoSyncShiftWindow = false;
                                });
                              },
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Shift Starts At',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.play_circle_outline_rounded,
                                          size: 16, color: AppTheme.primaryLight),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatTimeOfDay(_shiftStartTime),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _pickTime(
                              context: context,
                              initialTime: _shiftEndTime,
                              helpText: 'Select Shift Cutoff / End Time',
                              onPicked: (t) {
                                setState(() {
                                  _shiftEndTime = t;
                                  _autoSyncShiftWindow = false;
                                });
                              },
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Shift Cutoff / End',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.stop_circle_outlined,
                                          size: 16, color: Colors.redAccent),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatTimeOfDay(_shiftEndTime),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Shift Name Field
                    const Text(
                      'Shift Name',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _shiftNameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        hintText: 'e.g. Night Roll Call / Evening Shift',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notification Title Field
                    const Text(
                      'Notification Title',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.title_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Notification Message Field
                    const Text(
                      'Notification Message',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _messageController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(Icons.message_outlined, size: 20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Direct Test Notification Button
                    OutlinedButton.icon(
                      onPressed: _isTesting ? null : _handleTestNotification,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.ring_volume_rounded, size: 18, color: Colors.amber),
                      label: Text(
                        _isTesting
                            ? 'Sending Test Alert...'
                            : '🔔 Test Notification Sound & Alert on this Phone',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving || _isSendingInstant
                          ? null
                          : _handleInstantBroadcast,
                      icon: _isSendingInstant
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Instant Alert', style: TextStyle(fontSize: 12)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving || _isSendingInstant
                          ? null
                          : _handleSaveSchedule,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.alarm_add_rounded, size: 18),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isSaving
                              ? 'Saving...'
                              : 'Save Daily Schedule (${_formatTimeOfDay(_scheduledTime)})',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
