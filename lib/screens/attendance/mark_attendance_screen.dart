import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../models/student_model.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/attendance_tile.dart';
import '../../widgets/empty_state_view.dart';
import '../rooms/add_edit_room_dialog.dart';
import 'absentee_report_screen.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String? preselectedRoomId;
  final bool isTab;

  const MarkAttendanceScreen({
    super.key,
    this.preselectedRoomId,
    this.isTab = false,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final Map<String, String> _statusMap = {}; // studentId -> 'present' | 'absent'
  final Map<String, GlobalKey> _roomKeys = {}; // roomId -> GlobalKey for auto-scroll
  final ScrollController _scrollController = ScrollController();

  bool _isSaving = false;
  bool _initialized = false;
  String? _activeJumpRoomId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = context.read<HostelDataProvider>();
      _populateAllStatuses(provider);
      _initialized = true;

      // If preselectedRoomId provided, scroll to it after first frame
      if (widget.preselectedRoomId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToRoom(widget.preselectedRoomId!);
        });
      }
    }
  }

  void _populateAllStatuses(HostelDataProvider provider) {
    final todayMap = {for (var a in provider.todayAttendance) a.studentId: a.status};

    for (final s in provider.students) {
      if (!_statusMap.containsKey(s.id)) {
        _statusMap[s.id] = todayMap[s.id] ?? AppConstants.statusPresent;
      }
    }
  }

  void _scrollToRoom(String roomId) {
    setState(() => _activeJumpRoomId = roomId);
    final key = _roomKeys[roomId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  void _markRoomAll(List<StudentModel> roomStudents, String status) {
    setState(() {
      for (final s in roomStudents) {
        _statusMap[s.id] = status;
      }
    });
  }

  void _handleSaveAllAttendance(List<RoomModel> rooms, List<StudentModel> allStudents) async {
    if (allStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students found to mark attendance.'),
          backgroundColor: AppConstants.statusAbsentColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<HostelDataProvider>();
    final auth = context.read<AppAuthProvider>();
    final user = auth.currentUser;
    final today = AppDateUtils.todayStorage();

    final List<StudentModel> allAbsentList = [];

    try {
      // Save attendance for each room in batch
      for (final room in rooms) {
        final roomStudents = allStudents.where((s) => s.roomId == room.id).toList();
        if (roomStudents.isEmpty) continue;

        final absents = await provider.saveAttendance(
          roomId: room.id,
          roomNumber: room.roomNumber,
          date: today,
          markedBy: user?.id ?? 'rep_user',
          markedByName: user?.name ?? 'Hostel Representative',
          statusMap: _statusMap,
          students: roomStudents,
        );
        allAbsentList.addAll(absents);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        // Navigate to Absentee Report screen with consolidated report
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AbsenteeReportScreen(
              absentStudents: allAbsentList,
              roomNumber: rooms.length == 1 ? rooms.first.roomNumber : 'All Rooms',
              date: AppDateUtils.todayDisplay(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
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
    final provider = context.watch<HostelDataProvider>();
    final auth = context.watch<AppAuthProvider>();

    final user = auth.currentUser;
    final assignedIds = user?.assignedRoomIds ?? [];
    final hasAssignedRooms = !auth.isAdmin && assignedIds.isNotEmpty;

    // Filter available rooms and students
    final displayRooms = hasAssignedRooms
        ? provider.rooms.where((r) => assignedIds.contains(r.id)).toList()
        : provider.rooms;

    final displayStudents = hasAssignedRooms
        ? provider.students.where((s) => assignedIds.contains(s.roomId)).toList()
        : provider.students;

    // Ensure statusMap has keys for all students
    for (final s in displayStudents) {
      if (!_statusMap.containsKey(s.id)) {
        _statusMap[s.id] = AppConstants.statusPresent;
      }
    }

    // Calculate live totals
    int totalPresent = 0;
    int totalAbsent = 0;
    for (final s in displayStudents) {
      final st = _statusMap[s.id] ?? AppConstants.statusPresent;
      if (st == AppConstants.statusPresent) {
        totalPresent++;
      } else {
        totalAbsent++;
      }
    }

    // Ensure keys exist for each room
    for (final r in displayRooms) {
      _roomKeys.putIfAbsent(r.id, () => GlobalKey());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(hasAssignedRooms ? 'Mark Attendance (My Rooms)' : 'Mark Hostel Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Add Room',
            onPressed: () => AddEditRoomDialog.show(context),
          ),
        ],
      ),
      body: displayRooms.isEmpty
          ? EmptyStateView(
              title: 'No Rooms Available',
              subtitle: hasAssignedRooms
                  ? 'No rooms are currently assigned to your account. Please contact the Warden.'
                  : 'Get started by creating your first hostel room.',
              icon: Icons.meeting_room_outlined,
              buttonText: '+ Create Room',
              onButtonPressed: () => AddEditRoomDialog.show(context),
            )
          : Column(
              children: [
                // Top Sticky Controls: Date + Quick Jump Room Chips + Mass Mark
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Live Summary Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 15, color: AppTheme.primaryLight),
                              const SizedBox(width: 6),
                              Text(
                                AppDateUtils.todayDisplay(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppConstants.statusPresentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'P: $totalPresent',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.statusPresentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppConstants.statusAbsentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'A: $totalAbsent',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.statusAbsentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quick Jump Room Chips (Horizontal Scroll)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                'Jump to:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ),
                            ...displayRooms.map((room) {
                              final isSelected = _activeJumpRoomId == room.id;
                              final roomStudentCount = displayStudents.where((s) => s.roomId == room.id).length;

                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: isSelected
                                      ? AppTheme.primaryLight
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                  label: Text(
                                    'Room ${room.roomNumber} ($roomStudentCount)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                  onPressed: () => _scrollToRoom(room.id),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Continuous Multi-Room Vertical Scroll List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: displayRooms.length + (displayStudents.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, roomIndex) {
                      if (roomIndex == displayRooms.length) {
                        // Big prominent Submit Attendance card at end of room list
                        return Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Roll Call Complete',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '$totalPresent Present • $totalAbsent Absent',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _isSaving
                                    ? null
                                    : () => _handleSaveAllAttendance(displayRooms, displayStudents),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.check_circle_outline_rounded, size: 22),
                                label: Text(
                                  _isSaving
                                      ? 'Saving Attendance...'
                                      : 'Submit Attendance ($totalPresent Present • $totalAbsent Absent)',
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final room = displayRooms[roomIndex];
                      final roomStudents = displayStudents.where((s) => s.roomId == room.id).toList();

                      int roomPresent = 0;
                      int roomAbsent = 0;
                      for (final s in roomStudents) {
                        final st = _statusMap[s.id] ?? AppConstants.statusPresent;
                        if (st == AppConstants.statusPresent) {
                          roomPresent++;
                        } else {
                          roomAbsent++;
                        }
                      }

                      return Container(
                        key: _roomKeys[room.id],
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Room Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.meeting_room_rounded,
                                            size: 18, color: AppTheme.primaryLight),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Room ${room.roomNumber}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          room.block,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '$roomPresent P',
                                        style: const TextStyle(
                                            color: AppConstants.statusPresentColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                      const Text(' • ', style: TextStyle(color: Colors.grey)),
                                      Text(
                                        '$roomAbsent A',
                                        style: const TextStyle(
                                            color: AppConstants.statusAbsentColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                      const SizedBox(width: 6),
                                      TextButton(
                                        onPressed: () => _markRoomAll(roomStudents, AppConstants.statusPresent),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Text('All P', style: TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Students in this Room
                            if (roomStudents.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text('No students assigned to this room.',
                                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: roomStudents.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                                itemBuilder: (context, sIndex) {
                                  final student = roomStudents[sIndex];
                                  final status = _statusMap[student.id] ?? AppConstants.statusPresent;

                                  return AttendanceTile(
                                    student: student,
                                    index: sIndex + 1,
                                    status: status,
                                    onStatusChanged: (newStatus) {
                                      setState(() {
                                        _statusMap[student.id] = newStatus;
                                      });
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

      // Bottom Action Bar when opened as standalone screen
      bottomNavigationBar: (!widget.isTab && displayStudents.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _handleSaveAllAttendance(displayRooms, displayStudents),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 22),
                  label: Text(
                    _isSaving
                        ? 'Saving Attendance...'
                        : 'Submit Attendance ($totalPresent Present • $totalAbsent Absent)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
