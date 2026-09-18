import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String registerNumber;
  final String roomId;
  final String roomNumber;
  final String date; // "YYYY-MM-DD"
  final String status; // "present" or "absent"
  final String markedBy;
  final String markedByName;
  final DateTime timestamp;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.registerNumber,
    required this.roomId,
    required this.roomNumber,
    required this.date,
    required this.status,
    required this.markedBy,
    this.markedByName = 'Representative',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isPresent => status == AppConstants.statusPresent;
  bool get isAbsent => status == AppConstants.statusAbsent;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'registerNumber': registerNumber,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'date': date,
      'status': status,
      'markedBy': markedBy,
      'markedByName': markedByName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return AttendanceModel(
      id: docId,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      registerNumber: map['registerNumber'] ?? '',
      roomId: map['roomId'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      date: map['date'] ?? '',
      status: map['status'] ?? AppConstants.statusPresent,
      markedBy: map['markedBy'] ?? '',
      markedByName: map['markedByName'] ?? 'Representative',
      timestamp: parseDate(map['timestamp']),
    );
  }

  factory AttendanceModel.fromSnapshot(DocumentSnapshot doc) {
    return AttendanceModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  AttendanceModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? registerNumber,
    String? roomId,
    String? roomNumber,
    String? date,
    String? status,
    bool? isPresent,
    String? markedBy,
    String? markedByName,
    DateTime? timestamp,
  }) {
    String finalStatus = status ?? this.status;
    if (isPresent != null) {
      finalStatus = isPresent ? AppConstants.statusPresent : AppConstants.statusAbsent;
    }

    return AttendanceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      registerNumber: registerNumber ?? this.registerNumber,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      date: date ?? this.date,
      status: finalStatus,
      markedBy: markedBy ?? this.markedBy,
      markedByName: markedByName ?? this.markedByName,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class AttendanceSummary {
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int notMarkedCount;

  const AttendanceSummary({
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.notMarkedCount,
  });

  double get percentage => totalStudents == 0 ? 0.0 : (presentCount / totalStudents) * 100;
  double get attendancePercentage => percentage;
}
