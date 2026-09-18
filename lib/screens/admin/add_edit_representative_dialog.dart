import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../state/hostel_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';

class AddEditRepresentativeDialog extends StatefulWidget {
  final AppUser? representative;

  const AddEditRepresentativeDialog({super.key, this.representative});

  static Future<void> show(BuildContext context, {AppUser? representative}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditRepresentativeDialog(representative: representative),
    );
  }

  @override
  State<AddEditRepresentativeDialog> createState() => _AddEditRepresentativeDialogState();
}

class _AddEditRepresentativeDialogState extends State<AddEditRepresentativeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneController;

  final Set<String> _selectedRoomIds = {};
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get isEditing => widget.representative != null;

  @override
  void initState() {
    super.initState();
    final rep = widget.representative;
    _nameController = TextEditingController(text: rep?.name ?? '');
    _emailController = TextEditingController(text: rep?.email ?? '');
    _passwordController = TextEditingController(text: rep?.password ?? '');
    _phoneController = TextEditingController(text: rep?.phone ?? '');
    if (rep != null) {
      _selectedRoomIds.addAll(rep.assignedRoomIds);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = context.read<HostelDataProvider>();

    try {
      final rawEmail = _emailController.text.trim().toLowerCase();
      final cleanEmail = rawEmail.contains('@') ? rawEmail : '$rawEmail@gce.edu';

      if (isEditing) {
        await provider.updateRepresentative(
          userId: widget.representative!.id,
          name: _nameController.text.trim(),
          email: cleanEmail,
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
          assignedRoomIds: _selectedRoomIds.toList(),
          isActive: widget.representative!.isActive,
        );
      } else {
        await provider.addRepresentative(
          name: _nameController.text.trim(),
          email: cleanEmail,
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
          assignedRoomIds: _selectedRoomIds.toList(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Representative details updated successfully'
                : 'Representative account created successfully!'),
            backgroundColor: AppConstants.statusPresentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
    final rooms = provider.rooms;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isEditing ? 'Edit Representative' : 'Add Representative',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Representative Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Representative Name *',
                  hint: 'e.g. Manikandan R',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) => AppValidators.requiredField(val, 'Representative Name'),
                ),
                const SizedBox(height: 14),

                // Login Username or Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Login Username or Email *',
                  hint: 'e.g. rep1 or rep1@gce.edu',
                  prefixIcon: Icons.badge_outlined,
                  keyboardType: TextInputType.text,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Username or Email is required';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Login Password
                CustomTextField(
                  controller: _passwordController,
                  label: isEditing ? 'Password (Leave as is to keep)' : 'Set Login Password *',
                  hint: 'e.g. pass123 or rep@2026',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (!isEditing && (val == null || val.trim().length < 4)) {
                      return 'Password must be at least 4 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Mobile Phone
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number *',
                  hint: '10-digit mobile number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Phone number is required';
                    if (val.trim().length < 10) return 'Enter 10-digit phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Assigned Rooms Selector
                const Text(
                  'Assign Rooms (Optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select which rooms this representative will manage:',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),

                if (rooms.isEmpty)
                  const Text('No rooms created yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: rooms.map((room) {
                      final isSelected = _selectedRoomIds.contains(room.id);
                      return FilterChip(
                        label: Text('Room ${room.roomNumber} (${room.block})'),
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
                        selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.primaryLight,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryLight : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(isEditing ? 'Save Changes' : 'Create Representative'),
        ),
      ],
    );
  }
}
