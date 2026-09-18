import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReminderScheduleModel {
  final String id;
  final String shiftName;
  final int scheduledHour;
  final int scheduledMinute;
  final int shiftStartHour;
  final int shiftStartMinute;
  final int shiftEndHour;
  final int shiftEndMinute;
  final String title;
  final String message;
  final bool isEnabled;
  final String updatedBy;
  final DateTime updatedAt;

  const ReminderScheduleModel({
    this.id = 'default_schedule',
    this.shiftName = 'Night Roll Call',
    this.scheduledHour = 20,
    this.scheduledMinute = 30,
    this.shiftStartHour = 20,
    this.shiftStartMinute = 0,
    this.shiftEndHour = 21,
    this.shiftEndMinute = 30,
    this.title = 'Hostel Attendance Reminder',
    this.message =
        'Dear Representative, please mark attendance for all students in your assigned rooms before shift end time.',
    this.isEnabled = true,
    this.updatedBy = 'Chief Warden',
    required this.updatedAt,
  });

  TimeOfDay get scheduledTimeOfDay =>
      TimeOfDay(hour: scheduledHour, minute: scheduledMinute);
  TimeOfDay get shiftStartTimeOfDay =>
      TimeOfDay(hour: shiftStartHour, minute: shiftStartMinute);
  TimeOfDay get shiftEndTimeOfDay =>
      TimeOfDay(hour: shiftEndHour, minute: shiftEndMinute);

  String get formattedScheduledTime =>
      formatTimeOfDay(scheduledHour, scheduledMinute);
  String get formattedShiftStart =>
      formatTimeOfDay(shiftStartHour, shiftStartMinute);
  String get formattedShiftEnd => formatTimeOfDay(shiftEndHour, shiftEndMinute);
  String get formattedShiftWindow =>
      '$formattedShiftStart - $formattedShiftEnd';

  static String formatTimeOfDay(int hour, int minute) {
    final dt = DateTime(2026, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(dt);
  }

  static ReminderScheduleModel defaultSchedule() {
    return ReminderScheduleModel(
      id: 'default_schedule',
      shiftName: 'Night Roll Call',
      scheduledHour: 20,
      scheduledMinute: 30,
      shiftStartHour: 20,
      shiftStartMinute: 0,
      shiftEndHour: 21,
      shiftEndMinute: 30,
      title: 'Hostel Attendance Reminder',
      message:
          'Dear Representative, please mark attendance for all students in your assigned rooms before 9:30 PM.',
      isEnabled: true,
      updatedBy: 'Chief Warden',
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shiftName': shiftName,
      'scheduledHour': scheduledHour,
      'scheduledMinute': scheduledMinute,
      'shiftStartHour': shiftStartHour,
      'shiftStartMinute': shiftStartMinute,
      'shiftEndHour': shiftEndHour,
      'shiftEndMinute': shiftEndMinute,
      'title': title,
      'message': message,
      'isEnabled': isEnabled,
      'updatedBy': updatedBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ReminderScheduleModel.fromMap(
      Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return ReminderScheduleModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? 'default_schedule'),
      shiftName: map['shiftName'] ?? 'Night Roll Call',
      scheduledHour: (map['scheduledHour'] as num?)?.toInt() ?? 20,
      scheduledMinute: (map['scheduledMinute'] as num?)?.toInt() ?? 30,
      shiftStartHour: (map['shiftStartHour'] as num?)?.toInt() ?? 20,
      shiftStartMinute: (map['shiftStartMinute'] as num?)?.toInt() ?? 0,
      shiftEndHour: (map['shiftEndHour'] as num?)?.toInt() ?? 21,
      shiftEndMinute: (map['shiftEndMinute'] as num?)?.toInt() ?? 30,
      title: map['title'] ?? 'Hostel Attendance Reminder',
      message: map['message'] ??
          'Dear Representative, please mark attendance for all students in your assigned rooms.',
      isEnabled: map['isEnabled'] ?? true,
      updatedBy: map['updatedBy'] ?? 'Chief Warden',
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory ReminderScheduleModel.fromSnapshot(DocumentSnapshot doc) {
    return ReminderScheduleModel.fromMap(
      doc.data() as Map<String, dynamic>? ?? {},
      doc.id,
    );
  }

  ReminderScheduleModel copyWith({
    String? id,
    String? shiftName,
    int? scheduledHour,
    int? scheduledMinute,
    int? shiftStartHour,
    int? shiftStartMinute,
    int? shiftEndHour,
    int? shiftEndMinute,
    String? title,
    String? message,
    bool? isEnabled,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return ReminderScheduleModel(
      id: id ?? this.id,
      shiftName: shiftName ?? this.shiftName,
      scheduledHour: scheduledHour ?? this.scheduledHour,
      scheduledMinute: scheduledMinute ?? this.scheduledMinute,
      shiftStartHour: shiftStartHour ?? this.shiftStartHour,
      shiftStartMinute: shiftStartMinute ?? this.shiftStartMinute,
      shiftEndHour: shiftEndHour ?? this.shiftEndHour,
      shiftEndMinute: shiftEndMinute ?? this.shiftEndMinute,
      title: title ?? this.title,
      message: message ?? this.message,
      isEnabled: isEnabled ?? this.isEnabled,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
