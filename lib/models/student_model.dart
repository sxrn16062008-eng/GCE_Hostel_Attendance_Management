import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String name;
  final String registerNumber;
  final String rollNumber;
  final String department;
  final String year;
  final String phone;
  final String roomId;
  final String roomNumber;
  final String? photoUrl;
  final DateTime createdAt;

  StudentModel({
    required this.id,
    required this.name,
    required this.registerNumber,
    required this.rollNumber,
    required this.department,
    required this.year,
    required this.phone,
    required this.roomId,
    required this.roomNumber,
    this.photoUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'registerNumber': registerNumber,
      'rollNumber': rollNumber,
      'department': department,
      'year': year,
      'phone': phone,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return StudentModel(
      id: docId,
      name: map['name'] ?? '',
      registerNumber: map['registerNumber'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      department: map['department'] ?? '',
      year: map['year'] ?? '',
      phone: map['phone'] ?? '',
      roomId: map['roomId'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: parseDate(map['createdAt']),
    );
  }

  StudentModel copyWith({
    String? id,
    String? name,
    String? registerNumber,
    String? rollNumber,
    String? department,
    String? year,
    String? phone,
    String? roomId,
    String? roomNumber,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      registerNumber: registerNumber ?? this.registerNumber,
      rollNumber: rollNumber ?? this.rollNumber,
      department: department ?? this.department,
      year: year ?? this.year,
      phone: phone ?? this.phone,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
