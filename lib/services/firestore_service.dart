import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/room_model.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../models/complaint_model.dart';
import '../models/student_complaint_model.dart';
import '../utils/constants.dart';
import 'sample_data_service.dart';

class FirestoreService {
  final FirebaseFirestore? _firestore;
  static const _uuid = Uuid();

  // In-memory collections for local/demo state
  List<RoomModel> _localRooms = SampleDataService.getInitialRooms();
  List<StudentModel> _localStudents = SampleDataService.getInitialStudents();
  List<AppUser> _localUsers = SampleDataService.getInitialUsers();
  List<ComplaintModel> _localComplaints = [];
  List<StudentComplaintModel> _localStudentComplaints = [];

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  bool get isFirebaseAvailable => _firestore != null;

  // =========================================================================
  // BLOCK MANAGEMENT
  // =========================================================================

  Stream<List<String>> streamBlocks() {
    if (isFirebaseAvailable) {
      return _firestore!
          .collection(AppConstants.colBlocks)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((d) => d.id).toList();
            final all = {...AppConstants.defaultBlocks, ...list}.toList();
            all.sort();
            return all;
          });
    } else {
      return Stream.value(List<String>.from(AppConstants.defaultBlocks));
    }
  }

  Future<void> addBlock(String blockName) async {
    final name = blockName.trim();
    if (name.isEmpty) return;
    if (isFirebaseAvailable) {
      await _firestore!.collection(AppConstants.colBlocks).doc(name).set({'name': name});
    }
  }

  Future<void> deleteBlock(String blockName) async {
    if (isFirebaseAvailable) {
      await _firestore!.collection(AppConstants.colBlocks).doc(blockName.trim()).delete();
    }
  }

  // =========================================================================
  // ROOM MANAGEMENT
  // =========================================================================

  /// Stream of all hostel rooms
  Stream<List<RoomModel>> streamRooms() {
    if (isFirebaseAvailable) {
      return _firestore!
          .collection(AppConstants.colRooms)
          .orderBy('roomNumber')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
              .toList());
    } else {
      return Stream.value(List<RoomModel>.from(_localRooms));
    }
  }

  /// Get rooms list
  Future<List<RoomModel>> getRooms() async {
    if (isFirebaseAvailable) {
      try {
        final snap = await _firestore!
            .collection(AppConstants.colRooms)
            .orderBy('roomNumber')
            .get();
        return snap.docs
            .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (_) {
        return List<RoomModel>.from(_localRooms);
      }
    }
    return List<RoomModel>.from(_localRooms);
  }

  /// Add new room with duplicate roomNumber check
  Future<RoomModel> addRoom({
    required String roomNumber,
    required String block,
    required int capacity,
  }) async {
    final cleanRoomNum = roomNumber.trim();
    final cleanBlock = block.trim();

    // Check duplicate room number
    final existingRooms = await getRooms();
    final isDuplicate = existingRooms.any(
      (r) => r.roomNumber.toLowerCase() == cleanRoomNum.toLowerCase() &&
             r.block.toLowerCase() == cleanBlock.toLowerCase(),
    );

    if (isDuplicate) {
      throw Exception('Room $cleanRoomNum in $cleanBlock already exists.');
    }

    final newId = isFirebaseAvailable
        ? _firestore!.collection(AppConstants.colRooms).doc().id
        : 'room_${_uuid.v4().substring(0, 8)}';

    final newRoom = RoomModel(
      id: newId,
      roomNumber: cleanRoomNum,
      block: cleanBlock,
      capacity: capacity,
      studentCount: 0,
      createdAt: DateTime.now(),
    );

    if (isFirebaseAvailable) {
      await _firestore!
          .collection(AppConstants.colRooms)
          .doc(newId)
          .set(newRoom.toMap());
    } else {
      _localRooms.add(newRoom);
    }

    return newRoom;
  }

  /// Edit existing room
  Future<void> updateRoom({
    required String roomId,
    required String roomNumber,
    required String block,
    required int capacity,
  }) async {
    final cleanRoomNum = roomNumber.trim();
    final cleanBlock = block.trim();

    // Check duplicate room number excluding current room
    final existingRooms = await getRooms();
    final isDuplicate = existingRooms.any(
      (r) => r.id != roomId &&
             r.roomNumber.toLowerCase() == cleanRoomNum.toLowerCase() &&
             r.block.toLowerCase() == cleanBlock.toLowerCase(),
    );

    if (isDuplicate) {
      throw Exception('Another room with number $cleanRoomNum in $cleanBlock already exists.');
    }

    final room = existingRooms.firstWhere((r) => r.id == roomId);
    if (capacity < room.studentCount) {
      throw Exception('Capacity cannot be less than current student count (${room.studentCount}).');
    }

    if (isFirebaseAvailable) {
      await _firestore!.collection(AppConstants.colRooms).doc(roomId).update({
        'roomNumber': cleanRoomNum,
        'block': cleanBlock,
        'capacity': capacity,
      });
    } else {
      final index = _localRooms.indexWhere((r) => r.id == roomId);
      if (index >= 0) {
        _localRooms[index] = _localRooms[index].copyWith(
          roomNumber: cleanRoomNum,
          block: cleanBlock,
          capacity: capacity,
        );
      }
    }
  }

  /// Delete room
  Future<void> deleteRoom(String roomId) async {
    final students = await getStudentsByRoom(roomId);
    if (students.isNotEmpty) {
      throw Exception('Cannot delete room because it still contains ${students.length} students. Please reassign or delete students first.');
    }

    if (isFirebaseAvailable) {
      await _firestore!.collection(AppConstants.colRooms).doc(roomId).delete();
    } else {
      _localRooms.removeWhere((r) => r.id == roomId);
    }
  }

  // =========================================================================
  // STUDENT MANAGEMENT
  // =========================================================================

  /// Stream of all students
  Stream<List<StudentModel>> streamStudents() {
    if (isFirebaseAvailable) {
      return _firestore!
          .collection(AppConstants.colStudents)
          .orderBy('name')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
              .toList());
    } else {
      return Stream.value(List<StudentModel>.from(_localStudents));
    }
  }

  /// Get all students
  Future<List<StudentModel>> getAllStudents() async {
    if (isFirebaseAvailable) {
      try {
        final snap = await _firestore!
            .collection(AppConstants.colStudents)
            .orderBy('name')
            .get();
        return snap.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (_) {
        return List<StudentModel>.from(_localStudents);
      }
    }
    return List<StudentModel>.from(_localStudents);
  }

  /// Get students for a specific room
  Future<List<StudentModel>> getStudentsByRoom(String roomId) async {
    final all = await getAllStudents();
    return all.where((s) => s.roomId == roomId).toList();
  }

  /// Add student with capacity & unique registerNumber checks
  Future<StudentModel> addStudent({
    required String name,
    required String registerNumber,
    required String rollNumber,
    required String department,
    required String year,
    required String phone,
    required String roomId,
    String? photoUrl,
  }) async {
    final cleanReg = registerNumber.trim().toUpperCase();
    final cleanName = name.trim();

    // 1. Check unique register number
    final allStudents = await getAllStudents();
    final isDuplicateReg = allStudents.any(
      (s) => s.registerNumber.toUpperCase() == cleanReg,
    );
    if (isDuplicateReg) {
      throw Exception('A student with Register Number $cleanReg already exists.');
    }

    // 2. Validate room and capacity
    final rooms = await getRooms();
    final roomIndex = rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) {
      throw Exception('Selected room not found.');
    }
    final targetRoom = rooms[roomIndex];
    if (targetRoom.studentCount >= targetRoom.capacity) {
      throw Exception('Room ${targetRoom.roomNumber} is already at full capacity (${targetRoom.capacity}/${targetRoom.capacity}).');
    }

    final newStudentId = isFirebaseAvailable
        ? _firestore!.collection(AppConstants.colStudents).doc().id
        : 'stud_${_uuid.v4().substring(0, 8)}';

    final student = StudentModel(
      id: newStudentId,
      name: cleanName,
      registerNumber: cleanReg,
      rollNumber: rollNumber.trim().toUpperCase(),
      department: department,
      year: year,
      phone: phone.trim(),
      roomId: roomId,
      roomNumber: targetRoom.roomNumber,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );

    if (isFirebaseAvailable) {
      // Run batch write to add student and increment room studentCount
      final batch = _firestore!.batch();
      final studentRef = _firestore!.collection(AppConstants.colStudents).doc(newStudentId);
      final roomRef = _firestore!.collection(AppConstants.colRooms).doc(roomId);

      batch.set(studentRef, student.toMap());
      batch.update(roomRef, {'studentCount': FieldValue.increment(1)});
      await batch.commit();
    } else {
      _localStudents.add(student);
      final rIndex = _localRooms.indexWhere((r) => r.id == roomId);
      if (rIndex >= 0) {
        _localRooms[rIndex] = _localRooms[rIndex].copyWith(
          studentCount: _localRooms[rIndex].studentCount + 1,
        );
      }
    }

    return student;
  }

  /// Update student info (including possible room change)
  Future<void> updateStudent({
    required String studentId,
    required String name,
    required String registerNumber,
    required String rollNumber,
    required String department,
    required String year,
    required String phone,
    required String newRoomId,
    String? photoUrl,
  }) async {
    final cleanReg = registerNumber.trim().toUpperCase();
    final allStudents = await getAllStudents();

    // Check unique register number
    final isDuplicateReg = allStudents.any(
      (s) => s.id != studentId && s.registerNumber.toUpperCase() == cleanReg,
    );
    if (isDuplicateReg) {
      throw Exception('Another student with Register Number $cleanReg already exists.');
    }

    final currentStudent = allStudents.firstWhere((s) => s.id == studentId);
    final isRoomChanged = currentStudent.roomId != newRoomId;

    final rooms = await getRooms();
    final targetRoom = rooms.firstWhere((r) => r.id == newRoomId);

    if (isRoomChanged && targetRoom.studentCount >= targetRoom.capacity) {
      throw Exception('Target Room ${targetRoom.roomNumber} is at full capacity.');
    }

    if (isFirebaseAvailable) {
      final batch = _firestore!.batch();
      final studentRef = _firestore!.collection(AppConstants.colStudents).doc(studentId);

      batch.update(studentRef, {
        'name': name.trim(),
        'registerNumber': cleanReg,
        'rollNumber': rollNumber.trim().toUpperCase(),
        'department': department,
        'year': year,
        'phone': phone.trim(),
        'roomId': newRoomId,
        'roomNumber': targetRoom.roomNumber,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });

      if (isRoomChanged) {
        final oldRoomRef = _firestore!.collection(AppConstants.colRooms).doc(currentStudent.roomId);
        final newRoomRef = _firestore!.collection(AppConstants.colRooms).doc(newRoomId);
        batch.update(oldRoomRef, {'studentCount': FieldValue.increment(-1)});
        batch.update(newRoomRef, {'studentCount': FieldValue.increment(1)});
      }

      await batch.commit();
    } else {
      final sIndex = _localStudents.indexWhere((s) => s.id == studentId);
      if (sIndex >= 0) {
        _localStudents[sIndex] = _localStudents[sIndex].copyWith(
          name: name.trim(),
          registerNumber: cleanReg,
          rollNumber: rollNumber.trim().toUpperCase(),
          department: department,
          year: year,
          phone: phone.trim(),
          roomId: newRoomId,
          roomNumber: targetRoom.roomNumber,
          photoUrl: photoUrl ?? _localStudents[sIndex].photoUrl,
        );
      }

      if (isRoomChanged) {
        final oldRIndex = _localRooms.indexWhere((r) => r.id == currentStudent.roomId);
        if (oldRIndex >= 0) {
          _localRooms[oldRIndex] = _localRooms[oldRIndex].copyWith(
            studentCount: (_localRooms[oldRIndex].studentCount - 1).clamp(0, 999),
          );
        }
        final newRIndex = _localRooms.indexWhere((r) => r.id == newRoomId);
        if (newRIndex >= 0) {
          _localRooms[newRIndex] = _localRooms[newRIndex].copyWith(
            studentCount: _localRooms[newRIndex].studentCount + 1,
          );
        }
      }
    }
  }

  /// Delete student and decrement room count
  Future<void> deleteStudent(String studentId) async {
    final allStudents = await getAllStudents();
    final student = allStudents.firstWhere((s) => s.id == studentId);

    if (isFirebaseAvailable) {
      final batch = _firestore!.batch();
      final studentRef = _firestore!.collection(AppConstants.colStudents).doc(studentId);
      final roomRef = _firestore!.collection(AppConstants.colRooms).doc(student.roomId);

      batch.delete(studentRef);
      batch.update(roomRef, {'studentCount': FieldValue.increment(-1)});
      await batch.commit();
    } else {
      _localStudents.removeWhere((s) => s.id == studentId);
      final rIndex = _localRooms.indexWhere((r) => r.id == student.roomId);
      if (rIndex >= 0) {
        _localRooms[rIndex] = _localRooms[rIndex].copyWith(
          studentCount: (_localRooms[rIndex].studentCount - 1).clamp(0, 999),
        );
      }
    }
  }

  // =========================================================================
  // REPRESENTATIVE MANAGEMENT (ADMIN ONLY)
  // =========================================================================

  Stream<List<AppUser>> streamRepresentatives() {
    if (isFirebaseAvailable) {
      return _firestore!
          .collection(AppConstants.colUsers)
          .where('role', isEqualTo: AppConstants.roleRepresentative)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data(), doc.id))
              .toList());
    } else {
      return Stream.value(_localUsers.where((u) => u.isRepresentative).toList());
    }
  }

  Future<List<AppUser>> getRepresentatives() async {
    if (isFirebaseAvailable) {
      try {
        final snap = await _firestore!
            .collection(AppConstants.colUsers)
            .where('role', isEqualTo: AppConstants.roleRepresentative)
            .get();
        return snap.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).toList();
      } catch (_) {
        return _localUsers.where((u) => u.isRepresentative).toList();
      }
    }
    return _localUsers.where((u) => u.isRepresentative).toList();
  }

  Future<void> addRepresentative({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> assignedRoomIds,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final reps = await getRepresentatives();
    if (reps.any((r) => r.email.toLowerCase() == cleanEmail)) {
      throw Exception('A representative with email $cleanEmail already exists.');
    }

    final newId = isFirebaseAvailable
        ? _firestore!.collection(AppConstants.colUsers).doc().id
        : 'rep_${_uuid.v4().substring(0, 8)}';

    final rep = AppUser(
      id: newId,
      name: name.trim(),
      email: cleanEmail,
      password: password.trim(),
      phone: phone.trim(),
      role: AppConstants.roleRepresentative,
      assignedRoomIds: assignedRoomIds,
      isActive: true,
      createdAt: DateTime.now(),
    );

    if (isFirebaseAvailable) {
      await _firestore!.collection(AppConstants.colUsers).doc(newId).set(rep.toMap());
    } else {
      _localUsers.add(rep);
    }
  }

  Future<void> updateRepresentative({
    required String userId,
    required String name,
    String? email,
    String? password,
    required String phone,
    required List<String> assignedRoomIds,
    required bool isActive,
  }) async {
    if (isFirebaseAvailable) {
      final data = <String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
        'assignedRoomIds': assignedRoomIds,
        'isActive': isActive,
      };
      if (email != null && email.trim().isNotEmpty) {
        data['email'] = email.trim().toLowerCase();
      }
      if (password != null && password.trim().isNotEmpty) {
        data['password'] = password.trim();
      }
      await _firestore!.collection(AppConstants.colUsers).doc(userId).update(data);
    } else {
      final index = _localUsers.indexWhere((u) => u.id == userId);
      if (index >= 0) {
        _localUsers[index] = _localUsers[index].copyWith(
          name: name.trim(),
          email: email?.trim().toLowerCase() ?? _localUsers[index].email,
          password: password?.trim() ?? _localUsers[index].password,
          phone: phone.trim(),
          assignedRoomIds: assignedRoomIds,
          isActive: isActive,
        );
      }
    }
  }

  Future<void> deleteRepresentative(String userId) async {
    if (isFirebaseAvailable) {
      await _firestore!.collection(AppConstants.colUsers).doc(userId).delete();
    } else {
      _localUsers.removeWhere((u) => u.id == userId);
    }
  }

  Future<void> toggleRepresentativeStatus(String userId, bool isActive) async {
    if (isFirebaseAvailable) {
      await _firestore!.collection(AppConstants.colUsers).doc(userId).update({
        'isActive': isActive,
      });
    } else {
      final index = _localUsers.indexWhere((u) => u.id == userId);
      if (index >= 0) {
        _localUsers[index] = _localUsers[index].copyWith(isActive: isActive);
      }
    }
  }

  Future<AppUser?> getUserProfile(String userId) async {
    if (isFirebaseAvailable) {
      try {
        final doc = await _firestore!.collection(AppConstants.colUsers).doc(userId).get();
        if (doc.exists) {
          return AppUser.fromSnapshot(doc);
        }
      } catch (_) {}
    }
    return _localUsers.firstWhere(
      (u) => u.id == userId,
      orElse: () => _localUsers.first,
    );
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (isFirebaseAvailable) {
      try {
        final snap = await _firestore!
            .collection(AppConstants.colUsers)
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          return AppUser.fromSnapshot(snap.docs.first);
        }
      } catch (_) {}
    }
    try {
      return _localUsers.firstWhere((u) => u.email.toLowerCase() == cleanEmail);
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // COMPLAINTS MANAGEMENT
  // =========================================================================

  Stream<List<ComplaintModel>> streamComplaints({String? roomId, String? createdBy}) {
    if (isFirebaseAvailable) {
      Query query = _firestore!.collection(AppConstants.colComplaints);
      if (roomId != null && roomId.isNotEmpty) {
        query = query.where('roomId', isEqualTo: roomId);
      }
      if (createdBy != null && createdBy.isNotEmpty) {
        query = query.where('createdBy', isEqualTo: createdBy);
      }
      return query.snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) => ComplaintModel.fromSnapshot(doc)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } else {
      return Stream.value(_localComplaints);
    }
  }

  Future<List<ComplaintModel>> getComplaints() async {
    if (isFirebaseAvailable) {
      try {
        final snapshot = await _firestore!
            .collection(AppConstants.colComplaints)
            .get();
        final list = snapshot.docs.map((doc) => ComplaintModel.fromSnapshot(doc)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (e) {
        return _localComplaints;
      }
    }
    return _localComplaints;
  }

  Future<ComplaintModel> addComplaint({
    required String roomId,
    required String roomNumber,
    required String block,
    required String category,
    required String title,
    required String description,
    required String createdBy,
    required String createdByName,
    required String createdByPhone,
  }) async {
    final complaint = ComplaintModel(
      id: _uuid.v4(),
      roomId: roomId,
      roomNumber: roomNumber,
      block: block,
      category: category,
      title: title,
      description: description,
      status: AppConstants.complaintPending,
      createdBy: createdBy,
      createdByName: createdByName,
      createdByPhone: createdByPhone,
      createdAt: DateTime.now(),
    );

    if (isFirebaseAvailable) {
      await _firestore!
          .collection(AppConstants.colComplaints)
          .doc(complaint.id)
          .set(complaint.toMap());
    } else {
      _localComplaints.insert(0, complaint);
    }

    return complaint;
  }

  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? wardenRemarks,
  }) async {
    final now = status == AppConstants.complaintResolved ? DateTime.now() : null;
    final updateData = <String, dynamic>{
      'status': status,
      if (wardenRemarks != null) 'wardenRemarks': wardenRemarks,
      if (now != null) 'resolvedAt': now.toIso8601String(),
    };

    if (isFirebaseAvailable) {
      await _firestore!
          .collection(AppConstants.colComplaints)
          .doc(complaintId)
          .update(updateData);
    } else {
      final index = _localComplaints.indexWhere((c) => c.id == complaintId);
      if (index >= 0) {
        _localComplaints[index] = _localComplaints[index].copyWith(
          status: status,
          wardenRemarks: wardenRemarks,
          resolvedAt: now,
        );
      }
    }
  }

  Future<void> deleteComplaint(String complaintId) async {
    if (isFirebaseAvailable) {
      await _firestore!
          .collection(AppConstants.colComplaints)
          .doc(complaintId)
          .delete();
    } else {
      _localComplaints.removeWhere((c) => c.id == complaintId);
    }
  }

  // =========================================================================
  // STUDENT COMPLAINTS MANAGEMENT (DISCIPLINARY / CONDUCT)
  // =========================================================================

  Stream<List<StudentComplaintModel>> streamStudentComplaints({String? studentId, String? reportedBy}) {
    if (isFirebaseAvailable) {
      Query query = _firestore!.collection(AppConstants.colStudentComplaints);
      if (studentId != null && studentId.isNotEmpty) {
        query = query.where('studentId', isEqualTo: studentId);
      }
      if (reportedBy != null && reportedBy.isNotEmpty) {
        query = query.where('reportedBy', isEqualTo: reportedBy);
      }
      return query.snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) => StudentComplaintModel.fromSnapshot(doc)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } else {
      return Stream.value(_localStudentComplaints);
    }
  }

  Future<List<StudentComplaintModel>> getStudentComplaints() async {
    if (isFirebaseAvailable) {
      try {
        final snapshot = await _firestore!
            .collection(AppConstants.colStudentComplaints)
            .get();
        final list = snapshot.docs.map((doc) => StudentComplaintModel.fromSnapshot(doc)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (e) {
        return _localStudentComplaints;
      }
    }
    return _localStudentComplaints;
  }

  Future<StudentComplaintModel> addStudentComplaint({
    required String studentId,
    required String studentName,
    required String rollNumber,
    String registerNumber = '',
    required String roomNumber,
    String block = 'Main Block',
    String department = 'Engineering',
    required String incidentCategory,
    String severity = 'Medium',
    required String title,
    required String description,
    required String reportedBy,
    required String reportedByName,
    String reportedByRole = 'representative',
    String reportedByPhone = '',
  }) async {
    final complaint = StudentComplaintModel(
      id: _uuid.v4(),
      studentId: studentId,
      studentName: studentName,
      rollNumber: rollNumber,
      registerNumber: registerNumber,
      roomNumber: roomNumber,
      block: block,
      department: department,
      incidentCategory: incidentCategory,
      severity: severity,
      title: title,
      description: description,
      reportedBy: reportedBy,
      reportedByName: reportedByName,
      reportedByRole: reportedByRole,
      reportedByPhone: reportedByPhone,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    if (isFirebaseAvailable) {
      await _firestore!
          .collection(AppConstants.colStudentComplaints)
          .doc(complaint.id)
          .set(complaint.toMap());
    } else {
      _localStudentComplaints.insert(0, complaint);
    }

    return complaint;
  }

  Future<void> updateStudentComplaintStatus({
    required String complaintId,
    required String status,
    String? wardenAction,
    String? wardenRemarks,
  }) async {
    final now = (status == 'resolved' || status == 'action_taken' || status == 'dismissed') ? DateTime.now() : null;
    final updateData = <String, dynamic>{
      'status': status,
      if (wardenAction != null) 'wardenAction': wardenAction,
      if (wardenRemarks != null) 'wardenRemarks': wardenRemarks,
      if (now != null) 'resolvedAt': now.toIso8601String(),
    };

    if (isFirebaseAvailable) {
      await _firestore!
          .collection(AppConstants.colStudentComplaints)
          .doc(complaintId)
          .update(updateData);
    } else {
      final index = _localStudentComplaints.indexWhere((c) => c.id == complaintId);
      if (index >= 0) {
        _localStudentComplaints[index] = _localStudentComplaints[index].copyWith(
          status: status,
          wardenAction: wardenAction,
          wardenRemarks: wardenRemarks,
          resolvedAt: now,
        );
      }
    }
  }

  Future<void> deleteStudentComplaint(String complaintId) async {
    if (isFirebaseAvailable) {
      await _firestore!
          .collection(AppConstants.colStudentComplaints)
          .doc(complaintId)
          .delete();
    } else {
      _localStudentComplaints.removeWhere((c) => c.id == complaintId);
    }
  }

  /// Reset to sample initial state
  void resetDemoData() {
    _localRooms = SampleDataService.getInitialRooms();
    _localStudents = SampleDataService.getInitialStudents();
    _localUsers = SampleDataService.getInitialUsers();
    _localComplaints = [];
    _localStudentComplaints = [];
  }
}

