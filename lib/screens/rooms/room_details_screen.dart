import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../attendance/mark_attendance_screen.dart';
import '../students/add_edit_student_screen.dart';
import '../students/student_details_screen.dart';
import 'add_edit_room_dialog.dart';

class RoomDetailsScreen extends StatelessWidget {
  final String roomId;

  const RoomDetailsScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HostelDataProvider>();
    final auth = context.watch<AppAuthProvider>();

    final roomIndex = provider.rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Room Details')),
        body: const Center(child: Text('Room not found')),
      );
    }

    final room = provider.rooms[roomIndex];
    final students = provider.students.where((s) => s.roomId == roomId).toList();
    final isFull = room.isFull;

    return Scaffold(
      appBar: AppBar(
        title: Text('Room ${room.roomNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Room',
            onPressed: () => AddEditRoomDialog.show(context, room: room),
          ),
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppConstants.statusAbsentColor),
              tooltip: 'Delete Room',
              onPressed: () async {
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Delete Room ${room.roomNumber}?',
                  message: students.isNotEmpty
                      ? 'This room contains ${students.length} students. You must reassign or remove all students before deleting this room.'
                      : 'Are you sure you want to delete this room? This action cannot be undone.',
                  confirmText: 'Delete',
                  isDestructive: true,
                );

                if (confirm == true && context.mounted) {
                  try {
                    await provider.deleteRoom(room.id);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Room deleted successfully')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room Info Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: isDark ? 0.3 : 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.meeting_room_rounded, color: AppTheme.primaryLight, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Room ${room.roomNumber}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              room.block,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isFull ? AppConstants.statusAbsentColor : AppConstants.statusPresentColor)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isFull ? 'Full' : '${room.availableBeds} beds available',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isFull ? AppConstants.statusAbsentColor : AppConstants.statusPresentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  // Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(context, 'Block', room.block),
                      _buildMetric(context, 'Capacity', '${room.capacity} Beds'),
                      _buildMetric(context, 'Occupants', '${students.length} Students'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isFull
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Room has reached maximum capacity. Cannot add more students.'),
                                backgroundColor: AppConstants.statusAbsentColor,
                              ),
                            );
                          }
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddEditStudentScreen(preselectedRoomId: room.id),
                              ),
                            );
                          },
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Add Student'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFull ? Colors.grey : AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: students.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MarkAttendanceScreen(preselectedRoomId: room.id),
                              ),
                            );
                          },
                    icon: const Icon(Icons.how_to_reg_outlined, size: 18),
                    label: const Text('Mark Attendance'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Students in this room header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students in Room (${students.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (students.isEmpty)
              EmptyStateView(
                title: 'No Students Assigned',
                subtitle: 'Add students to Room ${room.roomNumber} to manage attendance.',
                icon: Icons.person_off_outlined,
                buttonText: '+ Add Student',
                onButtonPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditStudentScreen(preselectedRoomId: room.id),
                    ),
                  );
                },
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return _buildStudentListItem(context, student, index + 1, provider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentListItem(
    BuildContext context,
    StudentModel student,
    int number,
    HostelDataProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primary.withValues(alpha: isDark ? 0.3 : 0.1),
            child: Text(
              '$number',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => StudentDetailsScreen(studentId: student.id)),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Register No: ${student.registerNumber} • ${student.department}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => StudentDetailsScreen(studentId: student.id)),
              );
            },
          ),
        ],
      ),
    );
  }
}
