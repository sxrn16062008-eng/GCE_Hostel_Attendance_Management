import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../utils/date_utils.dart';
import '../../widgets/dashboard_card.dart';
import '../notifications/notifications_dialog.dart';
import '../attendance/absent_students_screen.dart';
import '../attendance/attendance_history_screen.dart';
import '../attendance/mark_attendance_screen.dart';
import '../complaints/complaints_list_screen.dart';
import '../student_complaints/student_complaints_list_screen.dart';
import '../mess_complaints/mess_complaints_list_screen.dart';
import '../mess_complaints/add_mess_complaint_dialog.dart';
import '../mess_complaints/mess_complaint_details_dialog.dart';
import '../rooms/rooms_list_screen.dart';
import '../students/students_list_screen.dart';
import '../../widgets/change_password_dialog.dart';

class RepresentativeDashboard extends StatelessWidget {
  const RepresentativeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();
    final provider = context.watch<HostelDataProvider>();
    final user = auth.currentUser;
    final assignedIds = user?.assignedRoomIds ?? [];
    final hasAssignedRooms = !auth.isAdmin && assignedIds.isNotEmpty;

    final summary = hasAssignedRooms
        ? provider.getTodaySummaryForRooms(assignedIds)
        : provider.getTodaySummary();
    final totalRooms = hasAssignedRooms
        ? provider.rooms.where((r) => assignedIds.contains(r.id)).length
        : provider.rooms.length;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await provider.refreshData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar with Avatar & Rep Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => ChangePasswordDialog.show(context),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF06B6D4), Color(0xFF4F46E5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF06B6D4)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  (user?.name.isNotEmpty == true)
                                      ? user!.name[0].toUpperCase()
                                      : 'R',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user?.name ?? 'Representative',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              letterSpacing: -0.5,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: AppTheme.primaryLight
                                                .withValues(alpha: 0.4)),
                                      ),
                                      child: const Text(
                                        'REP',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasAssignedRooms
                                      ? '${assignedIds.length} Assigned Room${assignedIds.length > 1 ? "s" : ""}'
                                      : 'General Representative',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Badge(
                            isLabelVisible:
                                provider.unreadNotificationsCount > 0,
                            label: Text(
                                '${provider.unreadNotificationsCount}'),
                            backgroundColor: Colors.redAccent,
                            child: const Icon(Icons.notifications_outlined,
                                size: 22),
                          ),
                          tooltip: 'Notifications & Reminders',
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF162035)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF1E2D4A)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          onPressed: () => NotificationsDialog.show(context),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF162035)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E2D4A)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 13, color: AppTheme.primaryLight),
                              const SizedBox(width: 4),
                              Text(
                                AppDateUtils.formatShort(DateTime.now()),
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Active Attendance Shift & Timing Schedule Banner
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF152037)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.primaryLight
                          .withValues(alpha: isDark ? 0.35 : 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.schedule_rounded,
                                color: AppTheme.primaryLight, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      provider.reminderSchedule.shiftName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        provider.reminderSchedule
                                            .formattedShiftWindow,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  provider.reminderSchedule.isEnabled
                                      ? 'Daily alert: ${provider.reminderSchedule.formattedScheduledTime} • By ${provider.reminderSchedule.updatedBy}'
                                      : 'Auto reminders paused by Warden',
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
                        ],
                      ),
                      if (provider.reminderSchedule.message.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF090D16)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote_rounded,
                                  size: 14, color: AppTheme.primaryLight),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  provider.reminderSchedule.message,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Attendance Pending Alert / Reminder Banner
                if (summary.notMarkedCount > 0) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: isDark ? 0.6 : 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notification_important_rounded,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attendance Reminder',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${summary.notMarkedCount} students pending today in your rooms. Please take attendance.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const MarkAttendanceScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Mark Now',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Attendance Rate Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4F46E5),
                        Color(0xFF2563EB),
                        Color(0xFF0EA5E9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasAssignedRooms
                                  ? "Assigned Rooms Attendance"
                                  : "Overall Attendance Status",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${summary.attendancePercentage.toStringAsFixed(1)}% Present',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${summary.presentCount} Present  •  ${summary.absentCount} Absent  •  ${summary.notMarkedCount} Pending',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const MarkAttendanceScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Take Attendance',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4 Grid Dashboard Cards
                const Text(
                  'Overview & Fast Stats',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.30,
                  children: [
                    DashboardCard(
                      title: 'Assigned Rooms',
                      value: '$totalRooms',
                      icon: Icons.meeting_room_rounded,
                      color: const Color(0xFF4F46E5),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RoomsListScreen()),
                        );
                      },
                    ),
                    DashboardCard(
                      title: 'Total Students',
                      value: '${summary.totalStudents}',
                      icon: Icons.people_rounded,
                      color: const Color(0xFF06B6D4),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const StudentsListScreen()),
                        );
                      },
                    ),
                    DashboardCard(
                      title: 'Present Today',
                      value: '${summary.presentCount}',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AttendanceHistoryScreen()),
                        );
                      },
                    ),
                    DashboardCard(
                      title: 'Absent Today',
                      value: '${summary.absentCount}',
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFFF43F5E),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AbsentStudentsScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                 // Quick Navigation Actions
                const Text(
                  'Quick Representative Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        title: 'Student Issues',
                        icon: Icons.person_off_rounded,
                        color: Colors.redAccent,
                        badgeCount: provider.pendingStudentComplaintsCount,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const StudentComplaintsListScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        title: 'Room Issues',
                        icon: Icons.build_circle_rounded,
                        color: Colors.amber[800] ?? Colors.amber,
                        badgeCount: provider.pendingComplaintsCount,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ComplaintsListScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        title: 'Mess Issues',
                        icon: Icons.restaurant_rounded,
                        color: Colors.deepOrange,
                        badgeCount: provider.pendingMessComplaintsCount,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const MessComplaintsListScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        title: 'Mark Attendance',
                        icon: Icons.how_to_reg_rounded,
                        color: AppTheme.primary,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const MarkAttendanceScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        title: 'View History',
                        icon: Icons.history_rounded,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AttendanceHistoryScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        title: 'Hostel Rooms',
                        icon: Icons.meeting_room_rounded,
                        color: const Color(0xFF4F46E5),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const RoomsListScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        title: 'Absent Today',
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFF43F5E),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AbsentStudentsScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        title: 'All Students',
                        icon: Icons.people_rounded,
                        color: const Color(0xFF06B6D4),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const StudentsListScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ─── DEDICATED MESS COMPLAINTS SECTION ────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mess Complaints & Feedback',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () => AddMessComplaintDialog.show(context),
                      icon: const Icon(Icons.add_rounded, size: 16, color: Colors.deepOrange),
                      label: const Text(
                        'Report Food Issue',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF152037) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withValues(alpha: isDark ? 0.1 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
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
                                Row(
                                  children: [
                                    const Text(
                                      'Hostel Mess System',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (provider.pendingMessComplaintsCount > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.deepOrange,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${provider.pendingMessComplaintsCount} Pending',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Food quality, late serving delay, hygiene or shortage feedback',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Recent Mess Complaints List Preview (if any)
                      if (provider.messComplaints.isNotEmpty) ...[
                        ...provider.messComplaints.take(2).map((comp) {
                          final isCompResolved = comp.isResolved || comp.isDismissed;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0D1526) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: InkWell(
                              onTap: () => MessComplaintDetailsDialog.show(context, comp),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      comp.mealType,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      comp.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCompResolved
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : Colors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      comp.isPending ? 'Pending' : (isCompResolved ? 'Resolved' : 'In Review'),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: isCompResolved ? Colors.green : Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                      ],

                      // Action row inside card
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => AddMessComplaintDialog.show(context),
                              icon: const Icon(Icons.add_comment_rounded, size: 14, color: Colors.deepOrange),
                              label: const Text(
                                'Report Food Issue',
                                style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.deepOrange.withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MessComplaintsListScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.list_alt_rounded, size: 14),
                              label: Text(
                                'View All (${provider.messComplaints.length})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF152037) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E2D4A)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

