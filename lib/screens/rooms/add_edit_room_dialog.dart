import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../state/hostel_data_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';

class AddEditRoomDialog extends StatefulWidget {
  final RoomModel? room;

  const AddEditRoomDialog({super.key, this.room});

  static Future<RoomModel?> show(BuildContext context, {RoomModel? room}) {
    return showDialog<RoomModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditRoomDialog(room: room),
    );
  }

  @override
  State<AddEditRoomDialog> createState() => _AddEditRoomDialogState();
}

class _AddEditRoomDialogState extends State<AddEditRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomNumberController;
  late final TextEditingController _capacityController;
  late final TextEditingController _customBlockController;
  String _selectedBlock = '';
  bool _isAddingCustomBlock = false;
  bool _isLoading = false;

  bool get isEditing => widget.room != null;

  @override
  void initState() {
    super.initState();
    _roomNumberController = TextEditingController(text: widget.room?.roomNumber ?? '');
    _capacityController = TextEditingController(text: widget.room != null ? '${widget.room!.capacity}' : '4');
    _customBlockController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedBlock.isEmpty) {
      final provider = context.read<HostelDataProvider>();
      final availableBlocks = provider.blocks;
      if (widget.room != null && widget.room!.block.isNotEmpty) {
        _selectedBlock = widget.room!.block;
      } else if (availableBlocks.isNotEmpty) {
        _selectedBlock = availableBlocks.first;
      } else {
        _selectedBlock = AppConstants.defaultBlocks.first;
      }
    }
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _capacityController.dispose();
    _customBlockController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final blockToUse = _isAddingCustomBlock
        ? _customBlockController.text.trim()
        : _selectedBlock;

    if (blockToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a block name.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<HostelDataProvider>();

    try {
      if (isEditing) {
        await provider.updateRoom(
          roomId: widget.room!.id,
          roomNumber: _roomNumberController.text.trim(),
          block: blockToUse,
          capacity: int.parse(_capacityController.text.trim()),
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room updated successfully'),
              backgroundColor: AppConstants.statusPresentColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final newRoom = await provider.addRoom(
          roomNumber: _roomNumberController.text.trim(),
          block: blockToUse,
          capacity: int.parse(_capacityController.text.trim()),
        );
        if (mounted) {
          Navigator.of(context).pop(newRoom);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room added successfully'),
              backgroundColor: AppConstants.statusPresentColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
    final availableBlocks = provider.blocks.isNotEmpty
        ? provider.blocks
        : AppConstants.defaultBlocks;

    // Ensure selected block is in the list if not adding custom
    if (!_isAddingCustomBlock && !availableBlocks.contains(_selectedBlock) && availableBlocks.isNotEmpty) {
      _selectedBlock = availableBlocks.first;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isEditing ? 'Edit Room ${widget.room!.roomNumber}' : 'Add New Room',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Block Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hostel Block *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      setState(() {
                        _isAddingCustomBlock = !_isAddingCustomBlock;
                      });
                    },
                    icon: Icon(_isAddingCustomBlock ? Icons.list_rounded : Icons.add_rounded, size: 16),
                    label: Text(
                      _isAddingCustomBlock ? 'Choose Existing' : '+ New Block',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (_isAddingCustomBlock)
                CustomTextField(
                  controller: _customBlockController,
                  label: 'Custom Block Name',
                  hint: 'e.g. Block E, New Wing, Kaveri Block',
                  prefixIcon: Icons.apartment_rounded,
                  validator: (val) {
                    if (_isAddingCustomBlock && (val == null || val.trim().isEmpty)) {
                      return 'Please enter block name';
                    }
                    return null;
                  },
                )
              else
                DropdownButtonFormField<String>(
                  value: availableBlocks.contains(_selectedBlock) ? _selectedBlock : availableBlocks.first,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: availableBlocks.map((b) {
                    return DropdownMenuItem(value: b, child: Text(b));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBlock = val);
                  },
                ),
              const SizedBox(height: 14),

              // Room Number
              CustomTextField(
                controller: _roomNumberController,
                label: 'Room Number *',
                hint: 'e.g. 101, 204, B-12',
                prefixIcon: Icons.meeting_room_outlined,
                validator: AppValidators.roomNumber,
              ),
              const SizedBox(height: 14),

              // Capacity
              CustomTextField(
                controller: _capacityController,
                label: 'Maximum Capacity (Beds) *',
                hint: 'e.g. 4',
                prefixIcon: Icons.bed_outlined,
                keyboardType: TextInputType.number,
                validator: AppValidators.capacity,
              ),
            ],
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
              : Text(isEditing ? 'Save Changes' : 'Create Room'),
        ),
      ],
    );
  }
}
