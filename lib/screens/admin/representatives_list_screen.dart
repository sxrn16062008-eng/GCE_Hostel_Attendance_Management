import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import 'add_edit_representative_dialog.dart';
import 'allocate_rooms_dialog.dart';

class RepresentativesListScreen extends StatefulWidget {
  const RepresentativesListScreen({super.key});

  @override
  State<RepresentativesListScreen> createState() => _RepresentativesListScreenState();
}

class _RepresentativesListScreenState extends State<RepresentativesListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HostelDataProvider>();
    final reps = provider.representatives;

    final filteredReps = reps.where((r) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          r.name.toLowerCase().contains(q) ||
          r.email.toLowerCase().contains(q) ||
          r.phone.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Representatives (Admins)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Representative',
            onPressed: () => AddEditRepresentativeDialog.show(context),
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
                hintText: 'Search representative name, email, phone...',
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

          // Representatives List
          Expanded(
            child: filteredReps.isEmpty
                ? EmptyStateView(
                    title: reps.isEmpty ? 'No Representatives Added' : 'No Representatives Found',
                    subtitle: reps.isEmpty
                        ? 'Add representatives and create login emails/passwords for them to take attendance.'
                        : 'No representative matches your search query.',
                    icon: Icons.manage_accounts_outlined,
                    buttonText: '+ Add Representative',
                    onButtonPressed: () => AddEditRepresentativeDialog.show(context),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: filteredReps.length,
                    itemBuilder: (context, index) {
                      final rep = filteredReps[index];
                      return _RepresentativeCard(
                        rep: rep,
                        isDark: isDark,
                        onEdit: () => AddEditRepresentativeDialog.show(context, representative: rep),
                        onDelete: () async {
                          final confirm = await ConfirmDialog.show(
                            context,
                            title: 'Delete ${rep.name}?',
                            message: 'Are you sure you want to remove this representative account?',
                            confirmText: 'Delete',
                            isDestructive: true,
                          );
                          if (confirm == true && context.mounted) {
                            try {
                              await provider.deleteRepresentative(rep.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Representative deleted successfully')),
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
                        onToggleActive: (val) async {
                          try {
                            await provider.toggleRepresentativeStatus(rep.id, val);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                              );
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
        onPressed: () => AddEditRepresentativeDialog.show(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Rep'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _RepresentativeCard extends StatelessWidget {
  final AppUser rep;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const _RepresentativeCard({
    required this.rep,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final initials = rep.name.trim().isNotEmpty
        ? rep.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'RP';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Avatar + Name + Active Switch + Actions Menu
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primary.withValues(alpha: isDark ? 0.3 : 0.12),
                  child: Text(
                    initials.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryLight, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rep.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: rep.isActive
                                  ? AppConstants.statusPresentColor.withValues(alpha: 0.15)
                                  : AppConstants.statusAbsentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rep.isActive ? 'ACTIVE' : 'DEACTIVATED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: rep.isActive ? AppConstants.statusPresentColor : AppConstants.statusAbsentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit Representative',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppConstants.statusAbsentColor),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Email & Phone info
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rep.email,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  rep.phone.isNotEmpty ? rep.phone : 'No phone registered',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                if (rep.password.isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Pass: ${rep.password}',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 12),
            // Assigned Rooms Section with Direct Allocate Rooms Button
            Consumer<HostelDataProvider>(
              builder: (context, provider, _) {
                final assignedCount = rep.assignedRoomIds.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Allocated Rooms ($assignedCount):',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => AllocateRoomsDialog.show(context, representative: rep),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: AppTheme.primaryLight.withValues(alpha: 0.6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.meeting_room_rounded, size: 14, color: AppTheme.primaryLight),
                          label: Text(
                            assignedCount == 0 ? 'Allocate Rooms' : 'Edit Rooms',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (assignedCount == 0)
                      GestureDetector(
                        onTap: () => AllocateRoomsDialog.show(context, representative: rep),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'No rooms allocated. Tap here to assign specific rooms to this representative.',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: rep.assignedRoomIds.map((roomId) {
                          final room = provider.rooms.firstWhere(
                            (r) => r.id == roomId || r.roomNumber == roomId,
                            orElse: () => RoomModel(id: roomId, roomNumber: roomId, block: '', capacity: 0),
                          );
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              'Room ${room.roomNumber}${room.block.isNotEmpty ? " (${room.block})" : ""}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
