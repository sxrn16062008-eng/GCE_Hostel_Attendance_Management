import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../state/auth_provider.dart';
import '../../state/hostel_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';

class AddComplaintDialog extends StatefulWidget {
  final String? preselectedRoomId;

  const AddComplaintDialog({super.key, this.preselectedRoomId});

  static Future<void> show(BuildContext context, {String? preselectedRoomId}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddComplaintDialog(preselectedRoomId: preselectedRoomId),
    );
  }

  @override
  State<AddComplaintDialog> createState() => _AddComplaintDialogState();
}

class _AddComplaintDialogState extends State<AddComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  String? _selectedRoomId;
  String _selectedCategory = AppConstants.complaintCategories.first;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _selectedRoomId = widget.preselectedRoomId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomId == null || _selectedRoomId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a room for this complaint.'),
          backgroundColor: AppConstants.statusAbsentColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<HostelDataProvider>();
    final auth = context.read<AppAuthProvider>();
    final user = auth.currentUser;

    final room = provider.rooms.firstWhere(
      (r) => r.id == _selectedRoomId,
      orElse: () => RoomModel(id: _selectedRoomId!, roomNumber: 'Room', block: 'Hostel', capacity: 0),
    );

    try {
      await provider.addComplaint(
        roomId: room.id,
        roomNumber: room.roomNumber,
        block: room.block,
        category: _selectedCategory,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        createdBy: user?.id ?? 'rep_user',
        createdByName: user?.name ?? 'Hostel Representative',
        createdByPhone: user?.phone ?? '',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint lodged successfully and notified to Warden!'),
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

    final availableRooms = hasAssignedRooms
        ? provider.rooms.where((r) => assignedIds.contains(r.id)).toList()
        : provider.rooms;

    if (_selectedRoomId == null && availableRooms.isNotEmpty) {
      _selectedRoomId = availableRooms.first.id;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.report_problem_rounded, color: AppConstants.statusAbsentColor, size: 22),
          SizedBox(width: 8),
          Text('Raise Room Complaint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
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
                // Room Selector
                const Text('Affected Room *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (availableRooms.isEmpty)
                  const Text('No rooms available.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  DropdownButtonFormField<String>(
                    value: availableRooms.any((r) => r.id == _selectedRoomId)
                        ? _selectedRoomId
                        : availableRooms.first.id,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.meeting_room_outlined, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    isExpanded: true,
                    items: availableRooms.map((r) {
                      return DropdownMenuItem(
                        value: r.id,
                        child: Text('Room ${r.roomNumber} (${r.block})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRoomId = val);
                    },
                    validator: (val) => val == null ? 'Please select a room' : null,
                  ),
                const SizedBox(height: 14),

                // Category Picker
                const Text('Complaint Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  isExpanded: true,
                  items: AppConstants.complaintCategories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat, maxLines: 1, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 14),

                // Issue Title
                CustomTextField(
                  controller: _titleController,
                  label: 'Issue / Problem Summary *',
                  hint: 'e.g. Ceiling fan not working / Tap leaking',
                  prefixIcon: Icons.title_rounded,
                  validator: (val) => AppValidators.requiredField(val, 'Issue Summary'),
                ),
                const SizedBox(height: 14),

                // Detailed Description
                CustomTextField(
                  controller: _descController,
                  label: 'Detailed Description *',
                  hint: 'Describe the issue clearly for the Warden and maintenance team...',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 3,
                  validator: (val) => AppValidators.requiredField(val, 'Description'),
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
            backgroundColor: AppConstants.statusAbsentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Submit to Warden'),
        ),
      ],
    );
  }
}
