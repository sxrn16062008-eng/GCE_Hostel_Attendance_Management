import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../utils/constants.dart';

class AttendanceTile extends StatelessWidget {
  final StudentModel student;
  final int index;
  final String status; // 'present' or 'absent'
  final ValueChanged<String> onStatusChanged;

  const AttendanceTile({
    super.key,
    required this.student,
    required this.index,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPresent = status == AppConstants.statusPresent;
    final isAbsent = status == AppConstants.statusAbsent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPresent
              ? AppConstants.statusPresentColor.withValues(alpha: 0.5)
              : (isAbsent
                  ? AppConstants.statusAbsentColor.withValues(alpha: 0.5)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          width: (isPresent || isAbsent) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPresent ? AppConstants.statusPresentColor : AppConstants.statusAbsentColor).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Index badge + Name + Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Index Circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isPresent
                      ? AppConstants.statusPresentColor.withValues(alpha: 0.15)
                      : (isAbsent
                          ? AppConstants.statusAbsentColor.withValues(alpha: 0.15)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isPresent
                          ? AppConstants.statusPresentColor
                          : (isAbsent ? AppConstants.statusAbsentColor : (isDark ? Colors.white70 : Colors.black87)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Roll: ${student.rollNumber}  •  Reg: ${student.registerNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Dual Buttons: PRESENT vs ABSENT
          Row(
            children: [
              // Present Button
              Expanded(
                child: InkWell(
                  onTap: () => onStatusChanged(AppConstants.statusPresent),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isPresent
                          ? AppConstants.statusPresentColor
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPresent
                            ? AppConstants.statusPresentColor
                            : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        width: isPresent ? 2 : 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: isPresent ? Colors.white : AppConstants.statusPresentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PRESENT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isPresent
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Absent Button
              Expanded(
                child: InkWell(
                  onTap: () => onStatusChanged(AppConstants.statusAbsent),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isAbsent
                          ? AppConstants.statusAbsentColor
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAbsent
                            ? AppConstants.statusAbsentColor
                            : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        width: isAbsent ? 2 : 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: isAbsent ? Colors.white : AppConstants.statusAbsentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ABSENT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isAbsent
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
