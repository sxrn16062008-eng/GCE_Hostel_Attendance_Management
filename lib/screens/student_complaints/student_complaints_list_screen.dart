import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import 'add_student_complaint_dialog.dart';
import 'student_complaint_details_dialog.dart';

class StudentComplaintsListScreen extends StatefulWidget {
  final String? studentId;

  const StudentComplaintsListScreen({super.key, this.studentId});

  @override
  State<StudentComplaintsListScreen> createState() => _StudentComplaintsListScreenState();
}

class _StudentComplaintsListScreenState extends State<StudentComplaintsListScreen> {
  String _selectedFilter = 'all'; // 'all', 'pending', 'under_review', 'action_taken', 'resolved'
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'high':
        return const Color(0xFFF97316);
      case 'critical':
        return const Color(0xFFEF4444);
      default:
        return AppTheme.primaryLight;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'under_review':
        return const Color(0xFF06B6D4);
      case 'action_taken':
        return const Color(0xFF8B5CF6);
      case 'resolved':
        return const Color(0xFF10B981);
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'under_review':
        return 'In Review';
      case 'action_taken':
        return 'Action Taken';
      case 'resolved':
        return 'Resolved';
      case 'dismissed':
        return 'Dismissed';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HostelDataProvider>();

    var list = widget.studentId != null

        ? provider.getStudentComplaintsForStudent(widget.studentId!)
        : provider.studentComplaints;

    // Filter by status tab
    if (_selectedFilter == 'pending') {
      list = list.where((c) => c.status == 'pending').toList();
    } else if (_selectedFilter == 'under_review') {
      list = list.where((c) => c.status == 'under_review').toList();
    } else if (_selectedFilter == 'action_taken') {
      list = list.where((c) => c.status == 'action_taken').toList();
    } else if (_selectedFilter == 'resolved') {
      list = list.where((c) => c.status == 'resolved' || c.status == 'dismissed').toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        return c.studentName.toLowerCase().contains(q) ||
            c.rollNumber.toLowerCase().contains(q) ||
            c.roomNumber.toLowerCase().contains(q) ||
            c.title.toLowerCase().contains(q) ||
            c.incidentCategory.toLowerCase().contains(q);
      }).toList();
    }

    final totalCount = provider.studentComplaints.length;
    final pendingCount = provider.studentComplaints.where((c) => c.status == 'pending').length;
    final inReviewCount = provider.studentComplaints.where((c) => c.status == 'under_review').length;
    final actionTakenCount = provider.studentComplaints.where((c) => c.status == 'action_taken').length;
    final resolvedCount = provider.studentComplaints.where((c) => c.status == 'resolved').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Disciplinary Issues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => provider.refreshData(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddStudentComplaintDialog.show(context),
        icon: const Icon(Icons.report_problem_rounded),
        label: const Text('Report Student'),
        backgroundColor: Colors.redAccent[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search & Fast Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by student name, roll no, room, issue...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('all', 'All ($totalCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending ($pendingCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('under_review', 'In Review ($inReviewCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('action_taken', 'Action Taken ($actionTakenCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('resolved', 'Resolved ($resolvedCount)'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List of Complaints
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user_outlined, size: 48, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Student Complaints Found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No complaints match your search query.'
                                : 'All students conduct logs are clear in this category.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = list[index];
                      final sevColor = _getSeverityColor(c.severity);
                      final statColor = _getStatusColor(c.status);

                      return InkWell(
                        onTap: () => StudentComplaintDetailsDialog.show(context, c),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF152037) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Student Name + Severity Chip
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.15),
                                    child: Text(
                                      c.studentName.isNotEmpty ? c.studentName[0].toUpperCase() : 'S',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryLight,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          'Room ${c.roomNumber} (${c.block}) • Roll: ${c.rollNumber}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: sevColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: sevColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.circle, size: 6, color: sevColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          c.severity.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: sevColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Incident Title & Category
                              Text(
                                c.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Badges & Footer
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _formatStatus(c.status),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statColor,
                                      ),
                                    ),
                                  ),
                                  if (c.wardenAction != null) ...[
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Action: ${c.wardenAction}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ] else
                                    const Spacer(),
                                  Text(
                                    AppDateUtils.formatShort(c.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
          color: isSelected
              ? Colors.white
              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: isSelected
            ? AppTheme.primary
            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = value);
      },
    );
  }
}
