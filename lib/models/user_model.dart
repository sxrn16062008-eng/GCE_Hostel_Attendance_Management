import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String role; // 'representative' or 'admin'
  final List<String> assignedRoomIds;
  final bool isActive;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.password = '',
    required this.phone,
    required this.role,
    this.assignedRoomIds = const [],
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isRepresentative => role == AppConstants.roleRepresentative;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email.toLowerCase().trim(),
      'password': password,
      'phone': phone,
      'role': role,
      'assignedRoomIds': assignedRoomIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return AppUser(
      id: docId,
      name: map['name'] ?? '',
      email: (map['email'] ?? '').toString().toLowerCase().trim(),
      password: map['password'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? AppConstants.roleRepresentative,
      assignedRoomIds: List<String>.from(map['assignedRoomIds'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory AppUser.fromSnapshot(DocumentSnapshot doc) {
    return AppUser.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? role,
    List<String>? assignedRoomIds,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      assignedRoomIds: assignedRoomIds ?? this.assignedRoomIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
