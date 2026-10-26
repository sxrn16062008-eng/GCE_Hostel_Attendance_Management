import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import 'add_complaint_dialog.dart';
import 'complaint_details_dialog.dart';

class ComplaintsListScreen extends StatefulWidget {
  const ComplaintsListScreen({super.key});

  @override
  State<ComplaintsListScreen> createState() => _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends State<ComplaintsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();
    final provider = context.watch<HostelDataProvider>();
    final rawUser = auth.currentUser;
    final user = provider.getEffectiveUser(rawUser);
    final isWarden = auth.isAdmin;
    final assignedIds = user.assignedRoomIds;

    // Filter base complaints for representative
    final baseComplaints = isWarden
        ? provider.complaints
        : (assignedIds.isEmpty ? <ComplaintModel>[] : provider.getComplaintsForRooms(assignedIds));

    final pendingList = baseComplaints.where((c) => c.isPending).toList();
    final inProgressList = baseComplaints.where((c) => c.isInProgress).toList();
    final resolvedList = baseComplaints.where((c) => c.isResolved).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_rounded),
            tooltip: 'Raise Complaint',
            onPressed: () => AddComplaintDialog.show(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'All (${baseComplaints.length})'),
            Tab(text: 'Pending (${pendingList.length})'),
            Tab(text: 'In Progress (${inProgressList.length})'),
            Tab(text: 'Resolved (${resolvedList.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by room, category, title...',
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

          // Tab Bar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildComplaintList(baseComplaints, isDark, isWarden, provider),
                _buildComplaintList(pendingList, isDark, isWarden, provider),
                _buildComplaintList(inProgressList, isDark, isWarden, provider),
                _buildComplaintList(resolvedList, isDark, isWarden, provider),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddComplaintDialog.show(context),
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Raise Complaint'),
        backgroundColor: AppConstants.statusAbsentColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildComplaintList(
    List<ComplaintModel> rawList,
    bool isDark,
    bool isWarden,
    HostelDataProvider provider,
  ) {
    final filtered = rawList.where((c) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          c.roomNumber.toLowerCase().contains(q) ||
          c.block.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q) ||
          c.title.toLowerCase().contains(q) ||
          c.createdByName.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return EmptyStateView(
        title: 'No Complaints Here',
        subtitle: _searchQuery.isNotEmpty
            ? 'No complaints match your search query.'
            : 'No room complaints registered in this category.',
        icon: Icons.check_circle_outline_rounded,
        buttonText: '+ Raise Room Complaint',
        onButtonPressed: () => AddComplaintDialog.show(context),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final c = filtered[index];
        return _ComplaintCard(
          complaint: c,
          isDark: isDark,
          isWarden: isWarden,
          onTap: () => ComplaintDetailsDialog.show(context, complaint: c),
          onDelete: () async {
            final confirm = await ConfirmDialog.show(
              context,
              title: 'Delete Complaint?',
              message: 'Are you sure you want to remove this complaint record?',
              confirmText: 'Delete',
              isDestructive: true,
            );
            if (confirm == true && context.mounted) {
              await provider.deleteComplaint(c.id);
            }
          },
        );
      },
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final bool isDark;
  final bool isWarden;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ComplaintCard({
    required this.complaint,
    required this.isDark,
    required this.isWarden,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final dateStr = DateFormat('MMM dd • hh:mm a').format(c.createdAt);

    Color statusColor;
    String statusLabel;
    if (c.status == AppConstants.complaintResolved) {
      statusColor = AppConstants.statusPresentColor;
      statusLabel = 'RESOLVED';
    } else if (c.status == AppConstants.complaintInProgress) {
      statusColor = Colors.blue;
      statusLabel = 'IN PROGRESS';
    } else {
      statusColor = AppConstants.statusPendingColor;
      statusLabel = 'PENDING';
    }

    IconData categoryIcon = Icons.build_rounded;
    if (c.category.contains('Electrical')) {
      categoryIcon = Icons.bolt_rounded;
    } else if (c.category.contains('Plumbing')) {
      categoryIcon = Icons.water_drop_rounded;
    } else if (c.category.contains('Cleaning')) {
      categoryIcon = Icons.cleaning_services_rounded;
    } else if (c.category.contains('Furniture')) {
      categoryIcon = Icons.bed_rounded;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Room Badge + Category + Status Chip
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: isDark ? 0.25 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(categoryIcon, size: 18, color: AppTheme.primaryLight),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'Room ${c.roomNumber} (${c.block})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  if (isWarden)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                      onSelected: (val) {
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Complaint', style: TextStyle(color: AppConstants.statusAbsentColor, fontSize: 13)),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                c.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Description preview
              Text(
                c.description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Footer: Reporter Name + Date + Action Hint
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            c.createdByName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
