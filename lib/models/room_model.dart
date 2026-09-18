import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String roomNumber;
  final String block;
  final int capacity;
  final int studentCount;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.roomNumber,
    required this.block,
    required this.capacity,
    this.studentCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isFull => studentCount >= capacity;
  int get availableBeds => (capacity - studentCount).clamp(0, capacity);
  double get occupancyRatio => capacity > 0 ? (studentCount / capacity).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'block': block,
      'capacity': capacity,
      'studentCount': studentCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return RoomModel(
      id: docId,
      roomNumber: map['roomNumber'] ?? '',
      block: map['block'] ?? '',
      capacity: (map['capacity'] is num) ? (map['capacity'] as num).toInt() : 4,
      studentCount: (map['studentCount'] is num) ? (map['studentCount'] as num).toInt() : 0,
      createdAt: parseDate(map['createdAt']),
    );
  }

  RoomModel copyWith({
    String? id,
    String? roomNumber,
    String? block,
    int? capacity,
    int? studentCount,
    DateTime? createdAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      block: block ?? this.block,
      capacity: capacity ?? this.capacity,
      studentCount: studentCount ?? this.studentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
