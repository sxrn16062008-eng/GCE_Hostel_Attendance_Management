import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../state/hostel_data_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/student_card.dart';
import '../students/add_edit_student_screen.dart';
import '../students/student_details_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HostelDataProvider>();

    final results = _query.isEmpty
        ? <StudentModel>[]
        : provider.students.where((s) {
            final q = _query.toLowerCase();
            return s.name.toLowerCase().contains(q) ||
                s.registerNumber.toLowerCase().contains(q) ||
                s.rollNumber.toLowerCase().contains(q) ||
                s.roomNumber.toLowerCase().contains(q) ||
                s.department.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search student, reg no, room...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (val) => setState(() => _query = val.trim()),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? const EmptyStateView(
              title: 'Search Hostel Directory',
              subtitle: 'Type a student name, register number (e.g. 24IT001), roll number, or room number.',
              icon: Icons.search_rounded,
            )
          : results.isEmpty
              ? EmptyStateView(
                  title: 'No Matching Results',
                  subtitle: 'No student found matching "$_query".',
                  icon: Icons.search_off_rounded,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final student = results[index];
                    return StudentCard(
                      student: student,
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
                        await provider.deleteStudent(student.id);
                      },
                    );
                  },
                ),
    );
  }
}
