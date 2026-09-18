import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_model.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/status_badge.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String? initialRoomId;

  const AttendanceHistoryScreen({super.key, this.initialRoomId});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

enum RoomFilterType { all, hasAbsents, allPresent }

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  RoomFilterType _filterType = RoomFilterType.all;
  List<AttendanceModel> _records = [];
  bool _isLoading = false;
  final Set<String> _expandedRoomIds = {};
  bool _expandAll = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    setState(() => _isLoading = true);
    final provider = context.read<HostelDataProvider>();
    final dateStr = AppDateUtils.formatForStorage(_selectedDate);

    final data = await provider.fetchAttendanceHistory(date: dateStr);
    if (mounted) {
      setState(() {
        _records = data;
        _isLoading = false;
        // If initial room provided, expand it
        if (widget.initialRoomId != null) {
          _expandedRoomIds.add(widget.initialRoomId!);
        }
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
      setState(() {
        _selectedDate = picked;
        _expandedRoomIds.clear();
      });
      _loadHistory();
    }
  }

  void _changeDay(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset));
      _expandedRoomIds.clear();
    });
    _loadHistory();
  }

  void _setToday() {
    final now = DateTime.now();
    if (_selectedDate.year != now.year ||
        _selectedDate.month != now.month ||
        _selectedDate.day != now.day) {
      setState(() {
        _selectedDate = now;
        _expandedRoomIds.clear();
      });
      _loadHistory();
    }
  }

  int _compareRoomNumbers(String a, String b) {
    final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (numA != numB) return numA.compareTo(numB);
    return a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HostelDataProvider>();
    final allRooms = provider.rooms;

    // 1. Group records by room
    final Map<String, List<AttendanceModel>> roomMap = {};
    for (final record in _records) {
      roomMap.putIfAbsent(record.roomId, () => []).add(record);
    }

    // 2. Build room summary objects
    final List<_RoomGroupData> roomGroups = [];
    roomMap.forEach((roomId, recs) {
      final matchedRoom = allRooms.where((r) => r.id == roomId).firstOrNull;
      final roomNumber = recs.isNotEmpty
          ? recs.first.roomNumber
          : (matchedRoom?.roomNumber ?? 'Unknown');
      final block = matchedRoom?.block ?? 'Hostel';

      roomGroups.add(
        _RoomGroupData(
          roomId: roomId,
          roomNumber: roomNumber,
          block: block,
          records: recs,
        ),
      );
    });

    // 3. Sort room groups numerically by room number (101, 102, 103...)
    roomGroups.sort((a, b) => _compareRoomNumbers(a.roomNumber, b.roomNumber));

    // 4. Filter room groups
    final filteredGroups = roomGroups.where((group) {
      // Filter by type
      if (_filterType == RoomFilterType.hasAbsents && !group.hasAbsents) {
        return false;
      }
      if (_filterType == RoomFilterType.allPresent && !group.isAllPresent) {
        return false;
      }

      // Filter by search query
      final q = _searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        final matchesRoom = group.roomNumber.toLowerCase().contains(q) ||
            group.block.toLowerCase().contains(q);
        final matchesStudent = group.records.any((r) =>
            r.studentName.toLowerCase().contains(q) ||
            r.registerNumber.toLowerCase().contains(q));
        return matchesRoom || matchesStudent;
      }

      return true;
    }).toList();

    // Overall KPI statistics
    final totalStudentsMarked = _records.length;
    final totalPresent = _records.where((r) => r.isPresent).length;
    final totalAbsent = _records.where((r) => r.isAbsent).length;
    final overallRate = totalStudentsMarked > 0
        ? (totalPresent / totalStudentsMarked) * 100
        : 0.0;
    final totalRoomsWithAbsents = roomGroups.where((r) => r.hasAbsents).length;
    final isToday = AppDateUtils.isToday(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        actions: [
          IconButton(
            icon: Icon(
              _expandAll ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
              size: 22,
            ),
            tooltip: _expandAll ? 'Collapse All Rooms' : 'Expand All Rooms',
            onPressed: () {
              setState(() {
                _expandAll = !_expandAll;
                if (_expandAll) {
                  _expandedRoomIds.addAll(roomGroups.map((r) => r.roomId));
                } else {
                  _expandedRoomIds.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Date Control & Overall KPI Banner
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
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
              children: [
                // Date Stepper Row
                Row(
                  children: [
                    // Previous Day Button
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: 'Previous Day',
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _changeDay(-1),
                    ),
                    const SizedBox(width: 8),

                    // Date Picker Card
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.primaryLight),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  AppDateUtils.formatDisplay(_selectedDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'TODAY',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Next Day Button
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: 'Next Day',
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _changeDay(1),
                    ),
                    if (!isToday) ...[
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: _setToday,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Overall KPI Summary Card
                if (_records.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [const Color(0xFFF8FAFC), const Color(0xFFEDF2F7)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildKpiTile('Rooms', '${roomGroups.length}', Icons.meeting_room_outlined, Colors.indigo),
                        _buildKpiTile('Present', '$totalPresent', Icons.check_circle_outline, AppConstants.statusPresentColor),
                        _buildKpiTile('Absent', '$totalAbsent', Icons.cancel_outlined, AppConstants.statusAbsentColor),
                        _buildKpiTile('Rate', '${overallRate.toStringAsFixed(1)}%', Icons.analytics_outlined, AppTheme.primaryLight),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Search & Filter Tabs
                Row(
                  children: [
                    // Search Field
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search Room No or Student...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
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
                  ],
                ),
                const SizedBox(height: 8),

                // Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Rooms (${roomGroups.length})', RoomFilterType.all),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'With Absents ($totalRoomsWithAbsents)',
                        RoomFilterType.hasAbsents,
                        color: AppConstants.statusAbsentColor,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        '100% Present (${roomGroups.length - totalRoomsWithAbsents})',
                        RoomFilterType.allPresent,
                        color: AppConstants.statusPresentColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Room List Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredGroups.isEmpty
                    ? EmptyStateView(
                        title: _records.isEmpty
                            ? 'No Attendance Marked'
                            : 'No Matching Rooms',
                        subtitle: _records.isEmpty
                            ? 'No attendance records found for ${AppDateUtils.formatDisplay(_selectedDate)}.'
                            : 'No rooms match your filter or search query.',
                        icon: Icons.meeting_room_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        itemCount: filteredGroups.length,
                        itemBuilder: (context, index) {
                          final group = filteredGroups[index];
                          final isExpanded = _expandedRoomIds.contains(group.roomId);

                          return _RoomAttendanceCard(
                            group: group,
                            isDark: isDark,
                            isExpanded: isExpanded,
                            onToggleExpand: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedRoomIds.remove(group.roomId);
                                } else {
                                  _expandedRoomIds.add(group.roomId);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, RoomFilterType type, {Color? color}) {
    final isSelected = _filterType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (color ?? (isDark ? Colors.grey[300] : Colors.grey[700])),
        ),
      ),
      selected: isSelected,
      selectedColor: color ?? AppTheme.primary,
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: isSelected
            ? Colors.transparent
            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      onSelected: (_) => setState(() => _filterType = type),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildKpiTile(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoomGroupData {
  final String roomId;
  final String roomNumber;
  final String block;
  final List<AttendanceModel> records;

  _RoomGroupData({
    required this.roomId,
    required this.roomNumber,
    required this.block,
    required this.records,
  });

  int get total => records.length;
  int get presentCount => records.where((r) => r.isPresent).length;
  int get absentCount => records.where((r) => r.isAbsent).length;
  double get percentage => total > 0 ? (presentCount / total) * 100 : 0.0;
  bool get hasAbsents => absentCount > 0;
  bool get isAllPresent => total > 0 && absentCount == 0;
}

class _RoomAttendanceCard extends StatelessWidget {
  final _RoomGroupData group;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _RoomAttendanceCard({
    required this.group,
    required this.isDark,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final hasAbsents = group.hasAbsents;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasAbsents
              ? AppConstants.statusAbsentColor.withValues(alpha: isDark ? 0.5 : 0.3)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: hasAbsents ? 1.5 : 1,
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
        children: [
          // Room Header & Overview Tap Region
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Room Number, Block, and Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.meeting_room_rounded, size: 16, color: AppTheme.primaryLight),
                                const SizedBox(width: 6),
                                Text(
                                  'Room ${group.roomNumber}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              group.block,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasAbsents
                              ? AppConstants.statusAbsentColor.withValues(alpha: 0.15)
                              : AppConstants.statusPresentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasAbsents
                                ? AppConstants.statusAbsentColor.withValues(alpha: 0.4)
                                : AppConstants.statusPresentColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasAbsents ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                              size: 13,
                              color: hasAbsents ? AppConstants.statusAbsentColor : AppConstants.statusPresentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasAbsents ? '${group.absentCount} Absent' : 'All Present',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: hasAbsents ? AppConstants.statusAbsentColor : AppConstants.statusPresentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Stats Counter Pills and Expand Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildStatPill('Present: ${group.presentCount}', AppConstants.statusPresentColor),
                          const SizedBox(width: 6),
                          _buildStatPill('Absent: ${group.absentCount}', AppConstants.statusAbsentColor),
                          const SizedBox(width: 6),
                          _buildStatPill('Total: ${group.total}', Colors.blueGrey),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            isExpanded ? 'Hide' : 'View (${group.total})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppTheme.primaryLight,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Progress Bar for Room Attendance
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: group.total > 0 ? group.presentCount / group.total : 0.0,
                      minHeight: 6,
                      backgroundColor: hasAbsents
                          ? AppConstants.statusAbsentColor.withValues(alpha: 0.3)
                          : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.statusPresentColor),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Students List Accordion
          if (isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: group.records.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
                itemBuilder: (context, sIndex) {
                  final record = group.records[sIndex];
                  final isPresent = record.isPresent;

                  final initials = record.studentName.trim().isNotEmpty
                      ? record.studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
                      : 'ST';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: (isPresent
                                  ? AppConstants.statusPresentColor
                                  : AppConstants.statusAbsentColor)
                              .withValues(alpha: isDark ? 0.25 : 0.15),
                          child: Text(
                            initials.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPresent
                                  ? AppConstants.statusPresentColor
                                  : AppConstants.statusAbsentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Reg: ${record.registerNumber}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: record.status),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
