import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/room_card.dart';
import '../../theme/app_theme.dart';
import 'add_edit_room_dialog.dart';
import 'room_details_screen.dart';

class RoomsListScreen extends StatefulWidget {
  const RoomsListScreen({super.key});

  @override
  State<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends State<RoomsListScreen> {
  String _searchQuery = '';
  String _selectedBlock = 'All';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HostelDataProvider>();
    final auth = context.watch<AppAuthProvider>();

    final user = auth.currentUser;
    final assignedIds = user?.assignedRoomIds ?? [];
    final hasAssignedRooms = !auth.isAdmin && assignedIds.isNotEmpty;

    final allBlocks = ['All', ...provider.blocks];

    // Filter rooms by assigned rooms if rep, search query and block
    final baseRooms = hasAssignedRooms
        ? provider.rooms.where((r) => assignedIds.contains(r.id)).toList()
        : provider.rooms;

    final filteredRooms = baseRooms.where((room) {
      final matchesSearch = _searchQuery.isEmpty ||
          room.roomNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          room.block.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesBlock = _selectedBlock == 'All' || room.block == _selectedBlock;

      return matchesSearch && matchesBlock;
    }).toList();

    void handleAddRoom() async {
      final createdRoom = await AddEditRoomDialog.show(context);
      if (createdRoom != null && !auth.isAdmin && user != null && context.mounted) {
        // Automatically link this room to the representative
        final updatedIds = [...assignedIds, createdRoom.id];
        await provider.updateRepresentative(
          userId: user.id,
          name: user.name,
          phone: user.phone,
          assignedRoomIds: updatedIds,
          isActive: user.isActive,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(hasAssignedRooms ? 'My Assigned Rooms' : 'Hostel Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Room',
            onPressed: handleAddRoom,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search room number or block...',
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
          // Block Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: allBlocks.map((block) {
                final isSelected = _selectedBlock == block;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(block),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedBlock = block);
                    },
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryLight,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryLight : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Room List
          Expanded(
            child: filteredRooms.isEmpty
                ? EmptyStateView(
                    title: 'No Rooms Found',
                    subtitle: provider.rooms.isEmpty
                        ? 'Get started by adding your first hostel room.'
                        : 'No rooms match your filter criteria.',
                    icon: Icons.meeting_room_outlined,
                    buttonText: '+ Add Room',
                    onButtonPressed: () => AddEditRoomDialog.show(context),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      return RoomCard(
                        room: room,
                        showDelete: auth.isAdmin,
                        onView: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RoomDetailsScreen(roomId: room.id),
                            ),
                          );
                        },
                        onEdit: () => AddEditRoomDialog.show(context, room: room),
                        onDelete: () async {
                          final confirm = await ConfirmDialog.show(
                            context,
                            title: 'Delete Room ${room.roomNumber}?',
                            message: 'Are you sure you want to delete this room?',
                            confirmText: 'Delete',
                            isDestructive: true,
                          );
                          if (confirm == true && context.mounted) {
                            try {
                              await provider.deleteRoom(room.id);
                              if (context.mounted) {
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
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: handleAddRoom,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Room'),
      ),
    );
  }
}
