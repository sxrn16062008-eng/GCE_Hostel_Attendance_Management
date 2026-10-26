import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../state/hostel_data_provider.dart';
import '../theme/app_theme.dart';
import 'admin/representatives_list_screen.dart';
import 'admin/warden_dashboard.dart';
import 'attendance/mark_attendance_screen.dart';
import 'complaints/complaints_list_screen.dart';
import 'profile/profile_screen.dart';
import 'representative/representative_dashboard.dart';
import 'rooms/rooms_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();
    final provider = context.watch<HostelDataProvider>();
    final isAdmin = auth.isAdmin;
    final pendingCount = provider.pendingComplaintsCount;

    // Real-time synchronization of representative profile & assigned rooms
    final effectiveUser = provider.getEffectiveUser(auth.currentUser);
    if (!isAdmin && effectiveUser.id.isNotEmpty && auth.currentUser != null) {
      if (effectiveUser.assignedRoomIds != auth.currentUser!.assignedRoomIds) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          auth.syncUser(effectiveUser);
        });
      }
    }

    final List<Widget> screens = isAdmin
        ? const [
            WardenDashboard(),
            RepresentativesListScreen(),
            ComplaintsListScreen(),
            RoomsListScreen(),
            ProfileScreen(),
          ]
        : const [
            RepresentativeDashboard(),
            MarkAttendanceScreen(isTab: true),
            ComplaintsListScreen(),
            RoomsListScreen(),
            ProfileScreen(),
          ];

    final List<_NavItemData> navItems = isAdmin
        ? [
            const _NavItemData(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Portal',
            ),
            const _NavItemData(
              icon: Icons.badge_outlined,
              activeIcon: Icons.badge_rounded,
              label: 'Reps',
            ),
            _NavItemData(
              icon: Icons.report_problem_outlined,
              activeIcon: Icons.report_problem_rounded,
              label: 'Complaints',
              badgeCount: pendingCount,
            ),
            const _NavItemData(
              icon: Icons.meeting_room_outlined,
              activeIcon: Icons.meeting_room_rounded,
              label: 'Rooms',
            ),
            const _NavItemData(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ]
        : [
            const _NavItemData(
              icon: Icons.space_dashboard_outlined,
              activeIcon: Icons.space_dashboard_rounded,
              label: 'Dashboard',
            ),
            const _NavItemData(
              icon: Icons.how_to_reg_outlined,
              activeIcon: Icons.how_to_reg_rounded,
              label: 'Attendance',
            ),
            _NavItemData(
              icon: Icons.report_problem_outlined,
              activeIcon: Icons.report_problem_rounded,
              label: 'Complaints',
              badgeCount: pendingCount,
            ),
            const _NavItemData(
              icon: Icons.meeting_room_outlined,
              activeIcon: Icons.meeting_room_rounded,
              label: 'Rooms',
            ),
            const _NavItemData(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ];

    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      extendBody: false,
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = safeIndex == index;

                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: isSelected ? 16 : 0,
                              vertical: isSelected ? 4 : 0,
                            ),
                            decoration: isSelected
                                ? BoxDecoration(
                                    color: AppTheme.primary
                                        .withValues(alpha: isDark ? 0.25 : 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  )
                                : null,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  color: isSelected
                                      ? (isDark
                                          ? const Color(0xFF818CF8)
                                          : AppTheme.primary)
                                      : (isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280)),
                                  size: 22,
                                ),
                                if ((item.badgeCount ?? 0) > 0)
                                  Positioned(
                                    top: -4,
                                    right: -8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.white, width: 1),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 14,
                                        minHeight: 14,
                                      ),
                                      child: Text(
                                        '${item.badgeCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? (isDark
                                      ? const Color(0xFF818CF8)
                                      : AppTheme.primary)
                                  : (isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280)),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}
