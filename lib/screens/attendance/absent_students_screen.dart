import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_model.dart';
import '../../state/hostel_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state_view.dart';
import '../students/student_details_screen.dart';

class AbsentStudentsScreen extends StatefulWidget {
  final String? initialRoomId;

  const AbsentStudentsScreen({super.key, this.initialRoomId});

  @override
  State<AbsentStudentsScreen> createState() => _AbsentStudentsScreenState();
}

class _AbsentStudentsScreenState extends State<AbsentStudentsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedRoomId = 'All';
  List<AttendanceModel> _absentList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoomId != null) {
      _selectedRoomId = widget.initialRoomId!;
    }
    _loadAbsentStudents();
  }

  void _loadAbsentStudents() async {
    setState(() => _isLoading = true);
    final provider = context.read<HostelDataProvider>();
    final dateStr = AppDateUtils.formatForStorage(_selectedDate);
    final roomId = _selectedRoomId == 'All' ? null : _selectedRoomId;

    final data = await provider.fetchAbsentStudentsHistory(date: dateStr, roomId: roomId);
    if (mounted) {
      setState(() {
        _absentList = data;
        _isLoading = false;
      });
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadAbsentStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HostelDataProvider>();
    final rooms = provider.rooms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absent Students Report'),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Date Selector
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 18, color: AppConstants.statusAbsentColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppDateUtils.formatShort(_selectedDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Room Selector
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        value: _selectedRoomId,
                        isDense: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          prefixIcon: const Icon(Icons.meeting_room_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('All Rooms')),
                          ...rooms.map((r) => DropdownMenuItem(
                                value: r.id,
                                child: Text('Room ${r.roomNumber}'),
                              )),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRoomId = val);
                            _loadAbsentStudents();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Counter Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppConstants.statusAbsentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Total Absent: ${_absentList.length}',
                        style: const TextStyle(
                          color: AppConstants.statusAbsentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppDateUtils.formatDisplay(_selectedDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Absent List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _absentList.isEmpty
                    ? EmptyStateView(
                        title: 'No Absent Students',
                        subtitle: 'All students are present or no attendance marked for this date.',
                        icon: Icons.celebration_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        itemCount: _absentList.length,
                        itemBuilder: (context, index) {
                          final item = _absentList[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppConstants.statusAbsentColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppConstants.statusAbsentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.person_off_rounded, color: AppConstants.statusAbsentColor, size: 22),
                                ),
                              ),
                              title: Text(
                                item.studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 3),
                                  Text(
                                    'Room ${item.roomNumber} • Reg: ${item.registerNumber}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Marked by: ${item.markedByName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => StudentDetailsScreen(studentId: item.studentId),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
