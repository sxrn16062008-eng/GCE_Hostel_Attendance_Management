import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final String senderName;
  final String targetRole; // 'representative' or 'all'
  final String type; // 'attendance_reminder', 'announcement', etc.
  final DateTime createdAt;
  final bool isRead;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.senderName = 'Chief Warden',
    this.targetRole = 'representative',
    this.type = 'attendance_reminder',
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'senderName': senderName,
      'targetRole': targetRole,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return AppNotificationModel(
      id: docId,
      title: map['title'] ?? 'Hostel Notification',
      message: map['message'] ?? '',
      senderName: map['senderName'] ?? 'Chief Warden',
      targetRole: map['targetRole'] ?? 'representative',
      type: map['type'] ?? 'attendance_reminder',
      createdAt: parseDate(map['createdAt']),
      isRead: map['isRead'] ?? false,
    );
  }

  factory AppNotificationModel.fromSnapshot(DocumentSnapshot doc) {
    return AppNotificationModel.fromMap(
      doc.data() as Map<String, dynamic>? ?? {},
      doc.id,
    );
  }

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? senderName,
    String? targetRole,
    String? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      senderName: senderName ?? this.senderName,
      targetRole: targetRole ?? this.targetRole,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
