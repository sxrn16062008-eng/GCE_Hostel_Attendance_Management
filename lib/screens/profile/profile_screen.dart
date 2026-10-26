import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../state/theme_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/change_password_dialog.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;

    final initials = user != null && user.name.trim().isNotEmpty
        ? user.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'US';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primary.withValues(alpha: isDark ? 0.3 : 0.12),
                    child: Text(
                      initials.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user?.name ?? 'Hostel Staff',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showEditProfileDialog(context, user?.name ?? '', user?.phone ?? ''),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded, size: 14, color: AppTheme.primaryLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  if (user?.phone.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_outlined, size: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          user!.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  StatusBadge(status: user?.role ?? AppConstants.roleRepresentative),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showEditProfileDialog(context, user?.name ?? '', user?.phone ?? ''),
                    icon: const Icon(Icons.badge_outlined, size: 16),
                    label: Text(
                      user?.isAdmin == true ? 'Change Warden Name' : 'Edit Profile Name',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryLight,
                      side: BorderSide(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account Security Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Account & Security',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryLight, size: 22),
                    ),
                    title: const Text('Edit Display Name', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      user?.isAdmin == true
                          ? 'Update official Warden name shown to representatives'
                          : 'Update your display name',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _showEditProfileDialog(context, user?.name ?? '', user?.phone ?? ''),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: AppTheme.primaryLight, size: 22),
                    ),
                    title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Verify old password & update your account password', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => ChangePasswordDialog.show(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preferences Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Appearance & System',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  // Dark Mode Switch
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.amber.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: Colors.amber,
                        size: 22,
                      ),
                    ),
                    title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      themeProvider.themeMode == ThemeMode.dark
                          ? 'Dark Mode'
                          : (themeProvider.themeMode == ThemeMode.light ? 'Light Mode' : 'System Default'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeProvider.themeMode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                      ],
                      onChanged: (mode) {
                        if (mode != null) themeProvider.setThemeMode(mode);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () async {
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Logout',
                  message: 'Are you sure you want to log out from GCE Boys Hostel?',
                  confirmText: 'Logout',
                  isDestructive: true,
                );

                if (confirm == true && context.mounted) {
                  await auth.signOut();
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.statusAbsentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, String currentName, String currentPhone) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _EditProfileDialog(
        initialName: currentName,
        initialPhone: currentPhone,
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final String initialName;
  final String initialPhone;

  const _EditProfileDialog({
    required this.initialName,
    required this.initialPhone,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();

    setState(() => _isSaving = true);
    final auth = context.read<AppAuthProvider>();
    final hostelProvider = context.read<HostelDataProvider>();

    final error = await auth.updateProfile(
      name: newName,
      phone: newPhone,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (error == null) {
        // Sync schedule in hostel provider if warden
        if (auth.isAdmin) {
          final sched = hostelProvider.reminderSchedule.copyWith(updatedBy: newName);
          await hostelProvider.updateReminderSchedule(sched);
        }

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
                      'Display name updated to "$newName" successfully!',
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppConstants.statusAbsentColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = context.read<AppAuthProvider>().isAdmin;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.badge_outlined, color: AppTheme.primaryLight, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isAdmin ? 'Edit Warden Name' : 'Edit Profile Name',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAdmin
                    ? 'Enter your official name. This name will appear on notifications, roll call alerts, and dashboard shown to representatives.'
                    : 'Enter your display name for the application.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: isAdmin ? 'Warden Name *' : 'Full Name *',
                  hintText: isAdmin ? 'e.g. Dr. A. Kumar / Chief Warden Saran' : 'e.g. Manikandan R',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  hintText: 'e.g. 9876543210',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
