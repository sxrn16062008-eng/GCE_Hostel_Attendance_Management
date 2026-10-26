import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/mess_complaint_model.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state_view.dart';
import 'add_mess_complaint_dialog.dart';
import 'mess_complaint_details_dialog.dart';

class MessComplaintsListScreen extends StatefulWidget {
  const MessComplaintsListScreen({super.key});

  @override
  State<MessComplaintsListScreen> createState() => _MessComplaintsListScreenState();
}

class _MessComplaintsListScreenState extends State<MessComplaintsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedMealFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'under_review':
        return const Color(0xFF3B82F6);
      case 'action_taken':
        return const Color(0xFF8B5CF6);
      case 'resolved':
        return const Color(0xFF10B981);
      case 'dismissed':
        return const Color(0xFF6B7280);
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
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
        return status;
    }
  }

  IconData _getMealIcon(String mealType) {
    if (mealType.contains('Breakfast')) return Icons.wb_sunny_outlined;
    if (mealType.contains('Lunch')) return Icons.sunny;
    if (mealType.contains('Snacks')) return Icons.coffee_rounded;
    if (mealType.contains('Dinner')) return Icons.nights_stay_rounded;
    return Icons.restaurant_rounded;
  }

  List<MessComplaintModel> _applyFilters(List<MessComplaintModel> list) {
    return list.where((c) {
      // Meal filter
      if (_selectedMealFilter != 'All' && !c.mealType.contains(_selectedMealFilter)) {
        return false;
      }
      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = c.title.toLowerCase().contains(q);
        final matchesDesc = c.description.toLowerCase().contains(q);
        final matchesCat = c.category.toLowerCase().contains(q);
        final matchesMeal = c.mealType.toLowerCase().contains(q);
        final matchesReporter = c.reportedByName.toLowerCase().contains(q);
        return matchesTitle || matchesDesc || matchesCat || matchesMeal || matchesReporter;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HostelDataProvider>();
    final allComplaints = provider.messComplaints;

    final pendingList = allComplaints.where((c) => c.isPending).toList();
    final inReviewList = allComplaints.where((c) => c.isUnderReview || c.isActionTaken).toList();
    final resolvedList = allComplaints.where((c) => c.isResolved || c.isDismissed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess & Food Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_rounded),
            tooltip: 'Report Mess Issue',
            onPressed: () => AddMessComplaintDialog.show(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepOrange,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'All (${allComplaints.length})'),
            Tab(text: 'Pending (${pendingList.length})'),
            Tab(text: 'In Review (${inReviewList.length})'),
            Tab(text: 'Resolved (${resolvedList.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search food issue, meal, category, rep...',
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

          // Meal Type Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                'All',
                'Breakfast',
                'Lunch',
                'Snacks',
                'Dinner',
              ].map((meal) {
                final isSelected = _selectedMealFilter == meal;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(meal),
                    selected: isSelected,
                    selectedColor: Colors.deepOrange,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : null,
                    ),
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setState(() => _selectedMealFilter = meal);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Tab Bar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_applyFilters(allComplaints), isDark, 'No mess complaints recorded'),
                _buildList(_applyFilters(pendingList), isDark, 'No pending mess complaints'),
                _buildList(_applyFilters(inReviewList), isDark, 'No complaints currently under review'),
                _buildList(_applyFilters(resolvedList), isDark, 'No resolved mess complaints yet'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddMessComplaintDialog.show(context),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Report Mess Issue', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildList(List<MessComplaintModel> list, bool isDark, String emptyMessage) {
    if (list.isEmpty) {
      return EmptyStateView(
        icon: Icons.restaurant_rounded,
        title: emptyMessage,
        subtitle: 'Tap "Report Mess Issue" to submit food quality or meal delay complaints.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final c = list[index];
        final sevColor = _getSeverityColor(c.severity);
        final statusColor = _getStatusColor(c.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0),
            ),
          ),
          elevation: 0,
          color: isDark ? const Color(0xFF152037) : Colors.white,
          child: InkWell(
            onTap: () => MessComplaintDetailsDialog.show(context, c),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Meal Chip & Severity & Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getMealIcon(c.mealType), size: 14, color: Colors.deepOrange),
                            const SizedBox(width: 4),
                            Text(
                              c.mealType,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: sevColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.severity,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: sevColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _formatStatus(c.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    c.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),

                  // Category
                  Text(
                    c.category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description snippet
                  Text(
                    c.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Warden Resolution Preview (if available)
                  if (c.wardenAction != null && c.wardenAction!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gavel_rounded, size: 14, color: Colors.green),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Warden Action: ${c.wardenAction}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Bottom info: Reporter & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'By: ${c.reportedByName}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM, hh:mm a').format(c.createdAt),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
