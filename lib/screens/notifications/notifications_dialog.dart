import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../attendance/mark_attendance_screen.dart';
import '../mess_complaints/mess_complaints_list_screen.dart';

class NotificationsDialog extends StatelessWidget {
  const NotificationsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HostelDataProvider>();
    final auth = context.watch<AppAuthProvider>();
    final notifications = provider.notifications;
    final isRep = !auth.isAdmin;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: isDark ? 0.25 : 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_rounded, color: AppTheme.primaryLight, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notification Center',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${notifications.length} updates & attendance reminders',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Notifications List
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Notifications Yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Attendance reminders from Warden will appear here.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          final isReminder = notif.type == 'attendance_reminder';
                          final isMessComplaint = notif.type == 'mess_complaint';

                          Color badgeBg = AppTheme.primaryLight.withValues(alpha: 0.2);
                          Color iconColor = AppTheme.primaryLight;
                          IconData notifIcon = Icons.info_outline_rounded;

                          if (isReminder) {
                            badgeBg = Colors.amber.withValues(alpha: 0.2);
                            iconColor = Colors.amber[700]!;
                            notifIcon = Icons.notification_important_rounded;
                          } else if (isMessComplaint) {
                            badgeBg = Colors.deepOrange.withValues(alpha: 0.2);
                            iconColor = Colors.deepOrange;
                            notifIcon = Icons.restaurant_rounded;
                          }

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: notif.isRead
                                  ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC))
                                  : (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.25) : const Color(0xFFEFF6FF)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: notif.isRead
                                    ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                                    : (isMessComplaint ? Colors.deepOrange.withValues(alpha: 0.5) : AppTheme.primaryLight.withValues(alpha: 0.5)),
                                width: notif.isRead ? 1 : 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        notifIcon,
                                        size: 16,
                                        color: iconColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      AppDateUtils.formatShort(notif.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  notif.message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'From: ${notif.senderName}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                    if (isRep && isReminder)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()),
                                          );
                                        },
                                        icon: const Icon(Icons.how_to_reg_rounded, size: 14),
                                        label: const Text('Mark Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    if (isMessComplaint)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const MessComplaintsListScreen()),
                                          );
                                        },
                                        icon: const Icon(Icons.restaurant_rounded, size: 14),
                                        label: const Text('View Mess Issue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          backgroundColor: Colors.deepOrange,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
