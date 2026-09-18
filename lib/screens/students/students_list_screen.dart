import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/student_card.dart';
import 'add_edit_student_screen.dart';
import 'student_details_screen.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  String _searchQuery = '';
  String _selectedRoom = 'All';
  String _selectedDepartment = 'All';
  String _selectedYear = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HostelDataProvider>();
    final auth = context.watch<AppAuthProvider>();

    final user = auth.currentUser;
    final assignedIds = user?.assignedRoomIds ?? [];
    final hasAssignedRooms = !auth.isAdmin && assignedIds.isNotEmpty;

    final baseRooms = hasAssignedRooms
        ? provider.rooms.where((r) => assignedIds.contains(r.id)).toList()
        : provider.rooms;

    final allRooms = ['All', ...baseRooms.map((r) => r.roomNumber)];
    final allDepts = ['All', ...AppConstants.departments];
    final allYears = ['All', ...AppConstants.years];

    final baseStudents = hasAssignedRooms
        ? provider.students.where((s) => assignedIds.contains(s.roomId)).toList()
        : provider.students;

    // Filter students
    final filteredStudents = baseStudents.where((s) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.registerNumber.toLowerCase().contains(q) ||
          s.rollNumber.toLowerCase().contains(q) ||
          s.roomNumber.toLowerCase().contains(q);

      final matchesRoom = _selectedRoom == 'All' || s.roomNumber == _selectedRoom;
      final matchesDept = _selectedDepartment == 'All' || s.department == _selectedDepartment;
      final matchesYear = _selectedYear == 'All' || s.year == _selectedYear;

      return matchesSearch && matchesRoom && matchesDept && matchesYear;
    }).toList();

    // Map today's attendance status for quick badges
    final todayMap = {for (var a in provider.todayAttendance) a.studentId: a.status};

    return Scaffold(
      appBar: AppBar(
        title: Text(hasAssignedRooms ? 'My Students' : 'Students Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Student',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, reg no, roll no, room...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Room Filter
                _buildDropdownChip(
                  context,
                  label: _selectedRoom == 'All' ? 'Room: All' : 'Room: $_selectedRoom',
                  items: allRooms,
                  selectedValue: _selectedRoom,
                  onChanged: (val) => setState(() => _selectedRoom = val!),
                ),
                const SizedBox(width: 8),

                // Department Filter
                _buildDropdownChip(
                  context,
                  label: _selectedDepartment == 'All' ? 'Dept: All' : 'Dept: ${_shortDept(_selectedDepartment)}',
                  items: allDepts,
                  selectedValue: _selectedDepartment,
                  onChanged: (val) => setState(() => _selectedDepartment = val!),
                ),
                const SizedBox(width: 8),

                // Year Filter
                _buildDropdownChip(
                  context,
                  label: _selectedYear == 'All' ? 'Year: All' : 'Year: $_selectedYear',
                  items: allYears,
                  selectedValue: _selectedYear,
                  onChanged: (val) => setState(() => _selectedYear = val!),
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Clear Filters', style: TextStyle(fontSize: 11, color: AppConstants.statusAbsentColor)),
                    onPressed: () {
                      setState(() {
                        _selectedRoom = 'All';
                        _selectedDepartment = 'All';
                        _selectedYear = 'All';
                        _searchQuery = '';
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Students List
          Expanded(
            child: filteredStudents.isEmpty
                ? EmptyStateView(
                    title: 'No Students Found',
                    subtitle: provider.students.isEmpty
                        ? 'Add students to hostel rooms to manage them.'
                        : 'No students match your filter criteria.',
                    icon: Icons.people_outline_rounded,
                    buttonText: '+ Add Student',
                    onButtonPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return StudentCard(
                        student: student,
                        attendanceStatus: todayMap[student.id],
                        onView: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentDetailsScreen(studentId: student.id),
                            ),
                          );
                        },
                        onEdit: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditStudentScreen(student: student),
                            ),
                          );
                        },
                        onDelete: () async {
                          final confirm = await ConfirmDialog.show(
                            context,
                            title: 'Delete ${student.name}?',
                            message: 'Are you sure you want to remove this student from hostel records?',
                            confirmText: 'Delete',
                            isDestructive: true,
                          );

                          if (confirm == true && context.mounted) {
                            try {
                              await provider.deleteStudent(student.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Student removed successfully')),
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
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
          );
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Student'),
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedRoom != 'All' || _selectedDepartment != 'All' || _selectedYear != 'All' || _searchQuery.isNotEmpty;

  String _shortDept(String dept) {
    if (dept.contains('(')) {
      return dept.split('(').last.replaceAll(')', '');
    }
    return dept;
  }

  Widget _buildDropdownChip(
    BuildContext context, {
    required String label,
    required List<String> items,
    required String selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => items.map((item) {
        return PopupMenuItem(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              fontWeight: item == selectedValue ? FontWeight.bold : FontWeight.normal,
              color: item == selectedValue ? AppTheme.primaryLight : null,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selectedValue != 'All'
              ? AppTheme.primary.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedValue != 'All'
                ? AppTheme.primaryLight
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selectedValue != 'All' ? FontWeight.bold : FontWeight.w500,
                color: selectedValue != 'All'
                    ? AppTheme.primaryLight
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }
}
