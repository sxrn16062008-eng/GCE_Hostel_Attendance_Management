import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class AllocateRoomsDialog extends StatefulWidget {
  final AppUser representative;

  const AllocateRoomsDialog({
    super.key,
    required this.representative,
  });

  static Future<void> show(BuildContext context, {required AppUser representative}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AllocateRoomsDialog(representative: representative),
    );
  }

  @override
  State<AllocateRoomsDialog> createState() => _AllocateRoomsDialogState();
}

class _AllocateRoomsDialogState extends State<AllocateRoomsDialog> {
  final Set<String> _selectedRoomIds = {};
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedRoomIds.addAll(widget.representative.assignedRoomIds);
  }

  void _handleSave() async {
    setState(() => _isSaving = true);
    final provider = context.read<HostelDataProvider>();

    try {
      await provider.updateRepresentative(
        userId: widget.representative.id,
        name: widget.representative.name,
        email: widget.representative.email,
        password: widget.representative.password,
        phone: widget.representative.phone,
        assignedRoomIds: _selectedRoomIds.toList(),
        isActive: widget.representative.isActive,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Allocated ${_selectedRoomIds.length} rooms to ${widget.representative.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppConstants.statusPresentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to allocate rooms: ${e.toString().replaceAll("Exception: ", "")}'),
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
    final allRooms = provider.rooms;

    // Filter rooms by search query
    final filteredRooms = allRooms.where((r) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return r.roomNumber.toLowerCase().contains(q) ||
          r.block.toLowerCase().contains(q);
    }).toList();

    // Group rooms by block
    final Map<String, List<RoomModel>> blockGroups = {};
    for (final room in filteredRooms) {
      final blockName = room.block.isNotEmpty ? room.block : 'General Block';
      blockGroups.putIfAbsent(blockName, () => []).add(room);
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment_ind_rounded, color: AppTheme.primaryLight, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Allocate Rooms',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      widget.representative.name,
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedRoomIds.isNotEmpty
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedRoomIds.isNotEmpty
                        ? AppTheme.primaryLight.withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${_selectedRoomIds.length} Selected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _selectedRoomIds.isNotEmpty ? AppTheme.primaryLight : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select the rooms that ${widget.representative.name} is authorized to manage and mark attendance for.',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.92,
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            // Search Bar & Bulk Actions
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search room or block...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedRoomIds.length == allRooms.length) {
                        _selectedRoomIds.clear();
                      } else {
                        _selectedRoomIds.addAll(allRooms.map((r) => r.id));
                      }
                    });
                  },
                  child: Text(
                    _selectedRoomIds.length == allRooms.length ? 'Clear All' : 'Select All',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Rooms Grouped by Block
            Expanded(
              child: allRooms.isEmpty
                  ? const Center(
                      child: Text(
                        'No rooms created yet.\nCreate rooms first in the Rooms tab.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : blockGroups.isEmpty
                      ? const Center(
                          child: Text(
                            'No rooms match your search query.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: blockGroups.keys.length,
                          itemBuilder: (context, index) {
                            final blockName = blockGroups.keys.elementAt(index);
                            final blockRooms = blockGroups[blockName]!;
                            final blockSelectedCount = blockRooms
                                .where((r) => _selectedRoomIds.contains(r.id))
                                .length;
                            final isAllBlockSelected =
                                blockSelectedCount == blockRooms.length;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Block Header
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.apartment_rounded,
                                              size: 16,
                                              color: AppTheme.primaryLight),
                                          const SizedBox(width: 6),
                                          Text(
                                            blockName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '$blockSelectedCount/${blockRooms.length}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryLight,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            if (isAllBlockSelected) {
                                              for (final r in blockRooms) {
                                                _selectedRoomIds.remove(r.id);
                                              }
                                            } else {
                                              for (final r in blockRooms) {
                                                _selectedRoomIds.add(r.id);
                                              }
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize
                                              .shrinkWrap,
                                        ),
                                        child: Text(
                                          isAllBlockSelected
                                              ? 'Deselect Block'
                                              : 'Select Block',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Room Chips
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: blockRooms.map((room) {
                                      final isSelected =
                                          _selectedRoomIds.contains(room.id);
                                      return FilterChip(
                                        label: Text(
                                          'Room ${room.roomNumber} (${room.capacity} Beds)',
                                        ),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedRoomIds.add(room.id);
                                            } else {
                                              _selectedRoomIds.remove(room.id);
                                            }
                                          });
                                        },
                                        selectedColor: AppTheme.primary
                                            .withValues(alpha: 0.22),
                                        checkmarkColor: AppTheme.primaryLight,
                                        backgroundColor: isDark
                                            ? const Color(0xFF0F172A)
                                            : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          side: BorderSide(
                                            color: isSelected
                                                ? AppTheme.primaryLight
                                                : (isDark
                                                    ? const Color(0xFF334155)
                                                    : const Color(0xFFCBD5E1)),
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                        ),
                                        labelStyle: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppTheme.primaryLight
                                              : (isDark
                                                  ? Colors.white70
                                                  : Colors.black87),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(_isSaving
              ? 'Saving...'
              : 'Save Room Allocation (${_selectedRoomIds.length})'),
        ),
      ],
    );
  }
}
