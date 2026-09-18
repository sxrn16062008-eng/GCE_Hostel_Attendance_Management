import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String roomId;
  final String roomNumber;
  final String block;
  final String category; // 'Electrical', 'Plumbing', 'Cleaning', 'Furniture', 'Discipline', 'Other'
  final String title;
  final String description;
  final String status; // 'pending', 'in_progress', 'resolved'
  final String createdBy; // Rep ID
  final String createdByName;
  final String createdByPhone;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? wardenRemarks;

  const ComplaintModel({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.block,
    required this.category,
    required this.title,
    required this.description,
    this.status = 'pending',
    required this.createdBy,
    required this.createdByName,
    this.createdByPhone = '',
    required this.createdAt,
    this.resolvedAt,
    this.wardenRemarks,
  });

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'block': block,
      'category': category,
      'title': title,
      'description': description,
      'status': status,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByPhone': createdByPhone,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'wardenRemarks': wardenRemarks,
    };
  }

  factory ComplaintModel.fromMap(Map<String, dynamic> map) {
    return ComplaintModel(
      id: map['id'] as String? ?? '',
      roomId: map['roomId'] as String? ?? '',
      roomNumber: map['roomNumber'] as String? ?? '',
      block: map['block'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? 'Representative',
      createdByPhone: map['createdByPhone'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.tryParse(map['resolvedAt'] as String)
          : null,
      wardenRemarks: map['wardenRemarks'] as String?,
    );
  }

  factory ComplaintModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ComplaintModel(
      id: doc.id,
      roomId: data['roomId'] as String? ?? '',
      roomNumber: data['roomNumber'] as String? ?? '',
      block: data['block'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'Representative',
      createdByPhone: data['createdByPhone'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] is Timestamp
              ? (data['resolvedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['resolvedAt'].toString()))
          : null,
      wardenRemarks: data['wardenRemarks'] as String?,
    );
  }

  ComplaintModel copyWith({
    String? id,
    String? roomId,
    String? roomNumber,
    String? block,
    String? category,
    String? title,
    String? description,
    String? status,
    String? createdBy,
    String? createdByName,
    String? createdByPhone,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? wardenRemarks,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      block: block ?? this.block,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByPhone: createdByPhone ?? this.createdByPhone,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      wardenRemarks: wardenRemarks ?? this.wardenRemarks,
    );
  }
}
