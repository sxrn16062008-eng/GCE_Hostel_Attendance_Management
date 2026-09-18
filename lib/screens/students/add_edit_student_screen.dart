import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../rooms/add_edit_room_dialog.dart';

class AddEditStudentScreen extends StatefulWidget {
  final StudentModel? student;
  final String? preselectedRoomId;

  const AddEditStudentScreen({super.key, this.student, this.preselectedRoomId});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _regNoController;
  late final TextEditingController _rollNoController;
  late final TextEditingController _phoneController;

  late String _selectedDepartment;
  late String _selectedYear;
  String? _selectedRoomId;
  bool _isLoading = false;

  bool get isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();
    final s = widget.student;

    _nameController = TextEditingController(text: s?.name ?? '');
    _regNoController = TextEditingController(text: s?.registerNumber ?? '');
    _rollNoController = TextEditingController(text: s?.rollNumber ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');

    _selectedDepartment = s?.department ?? AppConstants.departments.first;
    _selectedYear = s?.year ?? AppConstants.years.first;
    _selectedRoomId = s?.roomId ?? widget.preselectedRoomId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNoController.dispose();
    _rollNoController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleQuickAddRoom() async {
    final createdRoom = await AddEditRoomDialog.show(context);
    if (createdRoom != null && mounted) {
      final auth = context.read<AppAuthProvider>();
      final provider = context.read<HostelDataProvider>();
      final user = auth.currentUser;
      if (!auth.isAdmin && user != null) {
        final updated = [...user.assignedRoomIds, createdRoom.id];
        await provider.updateRepresentative(
          userId: user.id,
          name: user.name,
          phone: user.phone,
          assignedRoomIds: updated,
          isActive: user.isActive,
        );
      }
      setState(() {
        _selectedRoomId = createdRoom.id;
      });
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoomId == null || _selectedRoomId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create a hostel room first.'),
          backgroundColor: AppConstants.statusAbsentColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<HostelDataProvider>();

    try {
      if (isEditing) {
        await provider.updateStudent(
          studentId: widget.student!.id,
          name: _nameController.text.trim(),
          registerNumber: _regNoController.text.trim(),
          rollNumber: _rollNoController.text.trim(),
          department: _selectedDepartment,
          year: _selectedYear,
          phone: _phoneController.text.trim(),
          newRoomId: _selectedRoomId!,
        );
      } else {
        await provider.addStudent(
          name: _nameController.text.trim(),
          registerNumber: _regNoController.text.trim(),
          rollNumber: _rollNoController.text.trim(),
          department: _selectedDepartment,
          year: _selectedYear,
          phone: _phoneController.text.trim(),
          roomId: _selectedRoomId!,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Student updated successfully!' : 'Student added successfully!'),
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
    final provider = context.watch<HostelDataProvider>();
    final auth = context.watch<AppAuthProvider>();

    final user = auth.currentUser;
    final assignedIds = user?.assignedRoomIds ?? [];
    final hasAssignedRooms = !auth.isAdmin && assignedIds.isNotEmpty;

    final rooms = hasAssignedRooms
        ? provider.rooms.where((r) => assignedIds.contains(r.id)).toList()
        : provider.rooms;

    // Validate selected room exists in current rooms list
    if (_selectedRoomId != null && !rooms.any((r) => r.id == _selectedRoomId)) {
      _selectedRoomId = rooms.isNotEmpty ? rooms.first.id : null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Student' : 'Add Student'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Student Name
              CustomTextField(
                controller: _nameController,
                label: 'Student Full Name *',
                hint: 'e.g. Saran Kumar S',
                prefixIcon: Icons.person_outline_rounded,
                validator: (val) => AppValidators.requiredField(val, 'Student Name'),
              ),
              const SizedBox(height: 16),

              // Register Number & Roll Number in Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _regNoController,
                      label: 'Register No *',
                      hint: 'e.g. 24IT001',
                      prefixIcon: Icons.badge_outlined,
                      validator: (val) => AppValidators.requiredField(val, 'Register No'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _rollNoController,
                      label: 'Roll No *',
                      hint: 'e.g. IT2401',
                      prefixIcon: Icons.numbers_rounded,
                      validator: (val) => AppValidators.requiredField(val, 'Roll No'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Department Dropdown
              const Text('Department *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                isExpanded: true,
                items: AppConstants.departments.map((dept) {
                  return DropdownMenuItem(
                    value: dept,
                    child: Text(dept, maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDepartment = val);
                },
              ),
              const SizedBox(height: 16),

              // Academic Year Dropdown
              const Text('Academic Year *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: AppConstants.years.map((year) {
                  return DropdownMenuItem(value: year, child: Text(year));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedYear = val);
                },
              ),
              const SizedBox(height: 16),

              // Phone Number
              CustomTextField(
                controller: _phoneController,
                label: 'Mobile Number *',
                hint: '10-digit mobile number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Phone number is required';
                  if (val.trim().length < 10) return 'Enter a valid 10-digit phone number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Room Selector Header with Quick Add Room button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Assigned Room *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _handleQuickAddRoom,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('+ New Room', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (rooms.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'No hostel rooms created yet.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _handleQuickAddRoom,
                        icon: const Icon(Icons.add_business_rounded, size: 16),
                        label: const Text('Create Room Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedRoomId,
                  hint: const Text('Select a room'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.meeting_room_outlined, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  isExpanded: true,
                  items: rooms.map((room) {
                    final isCurrentRoom = isEditing && widget.student!.roomId == room.id;
                    final isFull = room.isFull && !isCurrentRoom;

                    return DropdownMenuItem<String>(
                      value: room.id,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Room ${room.roomNumber} (${room.block})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isFull
                                  ? AppConstants.statusAbsentColor.withValues(alpha: 0.15)
                                  : AppConstants.statusPresentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isFull ? 'FULL (${room.studentCount}/${room.capacity})' : '${room.studentCount}/${room.capacity} beds',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isFull ? AppConstants.statusAbsentColor : AppConstants.statusPresentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRoomId = val);
                  },
                  validator: (val) => val == null ? 'Please select a room' : null,
                ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Add Student to Hostel',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
