import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case AppConstants.statusPresent:
        bg = AppConstants.statusPresentColor.withValues(alpha: 0.15);
        fg = AppConstants.statusPresentColor;
        label = customLabel ?? 'Present';
        break;
      case AppConstants.statusAbsent:
        bg = AppConstants.statusAbsentColor.withValues(alpha: 0.15);
        fg = AppConstants.statusAbsentColor;
        label = customLabel ?? 'Absent';
        break;
      case AppConstants.roleAdmin:
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purple;
        label = customLabel ?? 'Warden / Admin';
        break;
      case AppConstants.roleRepresentative:
        bg = AppTheme.primaryLight.withValues(alpha: 0.15);
        fg = AppTheme.primaryLight;
        label = customLabel ?? 'Representative';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        label = customLabel ?? status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
