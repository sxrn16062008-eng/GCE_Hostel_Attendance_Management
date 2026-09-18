import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/student_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class AbsenteeReportScreen extends StatelessWidget {
  final List<StudentModel> absentStudents;
  final String roomNumber;
  final String date;

  const AbsenteeReportScreen({
    super.key,
    required this.absentStudents,
    required this.roomNumber,
    required this.date,
  });

  String _buildStudentCopyText(StudentModel s) {
    return 'Room: ${s.roomNumber}  |  Name: ${s.name}  |  Roll No: ${s.rollNumber}';
  }

  String _buildAllCopyText() {
    if (absentStudents.isEmpty) return 'No absentees today.';
    final lines = absentStudents.map((s) => _buildStudentCopyText(s)).join('\n');
    return 'Absentees – $date\n$lines';
  }

  void _copyOne(BuildContext context, StudentModel s) {
    Clipboard.setData(ClipboardData(text: _buildStudentCopyText(s)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Copied: ${s.name}', style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyAll(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _buildAllCopyText()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Copied all ${absentStudents.length} absentees', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppConstants.statusPresentColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Absentee Report'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (absentStudents.isNotEmpty)
            TextButton.icon(
              onPressed: () => _copyAll(context),
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text('Copy All', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: absentStudents.isEmpty
          ? _buildAllPresentBanner(context)
          : Column(
              children: [
                // Summary Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.person_off_rounded, color: Colors.white, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        '${absentStudents.length} Student${absentStudents.length == 1 ? '' : 's'} Absent',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Room $roomNumber  •  $date',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _copyAll(context),
                          icon: const Icon(Icons.copy_all_rounded, size: 18),
                          label: Text(
                            'Copy All ${absentStudents.length} Absentees',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFDC2626),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Absent Students List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: absentStudents.length,
                    itemBuilder: (context, index) {
                      final student = absentStudents[index];
                      return _AbsenteeCard(
                        index: index + 1,
                        student: student,
                        isDark: isDark,
                        onCopy: () => _copyOne(context, student),
                        copyText: _buildStudentCopyText(student),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              // Pop back to dashboard
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home_rounded),
            label: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllPresentBanner(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppConstants.statusPresentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 80,
              color: AppConstants.statusPresentColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🎉 All Present!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'All students are present today.\nAttendance saved successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _AbsenteeCard extends StatelessWidget {
  final int index;
  final StudentModel student;
  final bool isDark;
  final VoidCallback onCopy;
  final String copyText;

  const _AbsenteeCard({
    required this.index,
    required this.student,
    required this.isDark,
    required this.onCopy,
    required this.copyText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.statusAbsentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.statusAbsentColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Index Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppConstants.statusAbsentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.statusAbsentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _InfoChip(label: 'Room ${student.roomNumber}', icon: Icons.meeting_room_outlined),
                    _InfoChip(label: student.rollNumber, icon: Icons.tag_rounded),
                  ],
                ),
              ],
            ),
          ),

          // Copy Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.copy_rounded, size: 20, color: AppTheme.primaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
