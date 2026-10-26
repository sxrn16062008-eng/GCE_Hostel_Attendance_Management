import 'package:cloud_firestore/cloud_firestore.dart';

class MessComplaintModel {
  final String id;
  final String mealType; // 'Breakfast', 'Lunch', 'Snacks / Tea', 'Dinner', 'General / All Meals'
  final String category; // 'Food Quality & Taste', 'Late Food Serving / Meal Delay', 'Food Shortage / Insufficient Quantity', 'Hygiene & Mess Cleanliness', etc.
  final String severity; // 'Low', 'Medium', 'High', 'Critical'
  final String title;
  final String description;
  final String reportedBy; // User ID
  final String reportedByName;
  final String reportedByRole; // 'representative' or 'admin'
  final String reportedByPhone;
  final String status; // 'pending', 'under_review', 'action_taken', 'resolved', 'dismissed'
  final String? wardenAction; // e.g. 'Warning given to Mess Contractor', 'Food inspected', 'Fine levied', 'Kitchen hygiene inspected'
  final String? wardenRemarks;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const MessComplaintModel({
    required this.id,
    required this.mealType,
    required this.category,
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
      'mealType': mealType,
      'category': category,
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

  factory MessComplaintModel.fromMap(Map<String, dynamic> map) {
    return MessComplaintModel(
      id: map['id'] as String? ?? '',
      mealType: map['mealType'] as String? ?? 'General / All Meals',
      category: map['category'] as String? ?? 'Food Quality & Taste',
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

  factory MessComplaintModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessComplaintModel(
      id: doc.id,
      mealType: data['mealType'] as String? ?? 'General / All Meals',
      category: data['category'] as String? ?? 'Food Quality & Taste',
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

  MessComplaintModel copyWith({
    String? id,
    String? mealType,
    String? category,
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
    return MessComplaintModel(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      category: category ?? this.category,
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
