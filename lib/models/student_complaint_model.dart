import 'package:cloud_firestore/cloud_firestore.dart';

class StudentComplaintModel {
  final String id;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String registerNumber;
  final String roomNumber;
  final String block;
  final String department;
  final String incidentCategory; // 'Curfew & Night Attendance', 'Ragging & Harassment', 'Noise & Hostel Disturbance', 'Substance / Smoking', 'Property Damage', 'Misbehavior & Disrespect', 'Unauthorized Guest', 'Other Conduct'
  final String severity; // 'Low', 'Medium', 'High', 'Critical'
  final String title;
  final String description;
  final String reportedBy; // User ID
  final String reportedByName;
  final String reportedByRole; // 'representative' or 'admin'
  final String reportedByPhone;
  final String status; // 'pending', 'under_review', 'action_taken', 'resolved', 'dismissed'
  final String? wardenAction; // e.g. 'Warning Letter Issued', 'Parents Contacted', 'Fine Levied', 'Room Reassigned', 'Suspension Notice'
  final String? wardenRemarks;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const StudentComplaintModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    this.registerNumber = '',
    required this.roomNumber,
    this.block = 'Main Block',
    this.department = 'Engineering',
    required this.incidentCategory,
    this.severity = 'Medium',
    required this.title,
    required this.description,
    required this.reportedBy,
    required this.reportedByName,
    this.reportedByRole = 'representative',
    this.reportedByPhone = '',
    this.status = 'pending',
    this.wardenAction,
    this.wardenRemarks,
    required this.createdAt,
    this.resolvedAt,
  });

  bool get isPending => status == 'pending';
  bool get isUnderReview => status == 'under_review';
  bool get isActionTaken => status == 'action_taken';
  bool get isResolved => status == 'resolved';
  bool get isDismissed => status == 'dismissed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'registerNumber': registerNumber,
      'roomNumber': roomNumber,
      'block': block,
      'department': department,
      'incidentCategory': incidentCategory,
      'severity': severity,
      'title': title,
      'description': description,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'reportedByRole': reportedByRole,
      'reportedByPhone': reportedByPhone,
      'status': status,
      'wardenAction': wardenAction,
      'wardenRemarks': wardenRemarks,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  factory StudentComplaintModel.fromMap(Map<String, dynamic> map) {
    return StudentComplaintModel(
      id: map['id'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      rollNumber: map['rollNumber'] as String? ?? '',
      registerNumber: map['registerNumber'] as String? ?? '',
      roomNumber: map['roomNumber'] as String? ?? '',
      block: map['block'] as String? ?? 'Main Block',
      department: map['department'] as String? ?? '',
      incidentCategory: map['incidentCategory'] as String? ?? 'Misbehavior & Disrespect',
      severity: map['severity'] as String? ?? 'Medium',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      reportedBy: map['reportedBy'] as String? ?? '',
      reportedByName: map['reportedByName'] as String? ?? 'Representative',
      reportedByRole: map['reportedByRole'] as String? ?? 'representative',
      reportedByPhone: map['reportedByPhone'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      wardenAction: map['wardenAction'] as String?,
      wardenRemarks: map['wardenRemarks'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.tryParse(map['resolvedAt'] as String)
          : null,
    );
  }

  factory StudentComplaintModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentComplaintModel(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      rollNumber: data['rollNumber'] as String? ?? '',
      registerNumber: data['registerNumber'] as String? ?? '',
      roomNumber: data['roomNumber'] as String? ?? '',
      block: data['block'] as String? ?? 'Main Block',
      department: data['department'] as String? ?? '',
      incidentCategory: data['incidentCategory'] as String? ?? 'Misbehavior & Disrespect',
      severity: data['severity'] as String? ?? 'Medium',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      reportedBy: data['reportedBy'] as String? ?? '',
      reportedByName: data['reportedByName'] as String? ?? 'Representative',
      reportedByRole: data['reportedByRole'] as String? ?? 'representative',
      reportedByPhone: data['reportedByPhone'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      wardenAction: data['wardenAction'] as String?,
      wardenRemarks: data['wardenRemarks'] as String?,
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
    );
  }

  StudentComplaintModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? rollNumber,
    String? registerNumber,
    String? roomNumber,
    String? block,
    String? department,
    String? incidentCategory,
    String? severity,
    String? title,
    String? description,
    String? reportedBy,
    String? reportedByName,
    String? reportedByRole,
    String? reportedByPhone,
    String? status,
    String? wardenAction,
    String? wardenRemarks,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return StudentComplaintModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      registerNumber: registerNumber ?? this.registerNumber,
      roomNumber: roomNumber ?? this.roomNumber,
      block: block ?? this.block,
      department: department ?? this.department,
      incidentCategory: incidentCategory ?? this.incidentCategory,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByName: reportedByName ?? this.reportedByName,
      reportedByRole: reportedByRole ?? this.reportedByRole,
      reportedByPhone: reportedByPhone ?? this.reportedByPhone,
      status: status ?? this.status,
      wardenAction: wardenAction ?? this.wardenAction,
      wardenRemarks: wardenRemarks ?? this.wardenRemarks,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
