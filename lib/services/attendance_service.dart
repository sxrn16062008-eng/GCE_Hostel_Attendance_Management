import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import 'sample_data_service.dart';

class AttendanceService {
  final FirebaseFirestore? _firestore;

  // Local fallback storage for demo mode
  final List<AttendanceModel> _localAttendance = SampleDataService.getInitialAttendance();

  AttendanceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _collection => AppConstants.collectionAttendance;
  bool get isFirebaseAvailable => _firestore != null;

  /// Saves or updates attendance records for a room on a given date.
  Future<void> saveRoomAttendance({
    required String roomId,
    required List<AttendanceModel> attendanceRecords,
    required String date,
    required String markedBy,
  }) async {
    if (isFirebaseAvailable) {
      final batch = _firestore!.batch();
      for (var att in attendanceRecords) {
        final String docId = '${date}_${att.studentId}';
        final record = att.copyWith(id: docId, date: date, markedBy: markedBy);
        final docRef = _firestore!.collection(_collection).doc(docId);
        batch.set(docRef, record.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
    } else {
      for (var att in attendanceRecords) {
        final String docId = '${date}_${att.studentId}';
        final record = att.copyWith(id: docId, date: date, markedBy: markedBy);
        final index = _localAttendance.indexWhere((a) => a.id == docId);
        if (index >= 0) {
          _localAttendance[index] = record;
        } else {
          _localAttendance.add(record);
        }
      }
    }
  }

  /// Marks a single student's attendance.
  Future<void> markAttendance({
    required String studentId,
    required String studentName,
    required String registerNumber,
    required String roomId,
    required String roomNumber,
    required DateTime date,
    required bool isPresent,
    required String markedBy,
  }) async {
    final String dateStr = AppDateUtils.formatForStorage(date);
    final String docId = '${dateStr}_$studentId';
    final attendance = AttendanceModel(
      id: docId,
      studentId: studentId,
      studentName: studentName,
      registerNumber: registerNumber,
      roomId: roomId,
      roomNumber: roomNumber,
      date: dateStr,
      status: isPresent ? AppConstants.statusPresent : AppConstants.statusAbsent,
      markedBy: markedBy,
    );

    if (isFirebaseAvailable) {
      await _firestore!.collection(_collection).doc(docId).set(attendance.toMap(), SetOptions(merge: true));
    } else {
      final index = _localAttendance.indexWhere((a) => a.id == docId);
      if (index >= 0) {
        _localAttendance[index] = attendance;
      } else {
        _localAttendance.add(attendance);
      }
    }
  }

  /// Marks all students present in a room.
  Future<void> markAllPresent({
    required String roomId,
    required List<AttendanceModel> studentsAttendance,
    required DateTime date,
    required String markedBy,
  }) async {
    final String dateStr = AppDateUtils.formatForStorage(date);
    final records = studentsAttendance
        .map((att) => att.copyWith(date: dateStr, isPresent: true, markedBy: markedBy))
        .toList();
    await saveRoomAttendance(
      roomId: roomId,
      attendanceRecords: records,
      date: dateStr,
      markedBy: markedBy,
    );
  }

  /// Gets attendance by date (Future)
  Future<List<AttendanceModel>> getAttendanceByDate(String date, {String? roomId}) async {
    if (isFirebaseAvailable) {
      Query query = _firestore!.collection(_collection).where('date', isEqualTo: date);
      if (roomId != null && roomId.isNotEmpty) {
        query = query.where('roomId', isEqualTo: roomId);
      }
      final snap = await query.get();
      return snap.docs.map((doc) => AttendanceModel.fromSnapshot(doc)).toList();
    } else {
      return _localAttendance.where((a) {
        final matchesDate = a.date == date;
        final matchesRoom = roomId == null || roomId.isEmpty || a.roomId == roomId;
        return matchesDate && matchesRoom;
      }).toList();
    }
  }

  /// Streams attendance for a given date
  Stream<List<AttendanceModel>> streamAttendanceByDate(String date, {String? roomId}) async* {
    if (isFirebaseAvailable) {
      Query query = _firestore!.collection(_collection).where('date', isEqualTo: date);
      if (roomId != null && roomId.isNotEmpty) {
        query = query.where('roomId', isEqualTo: roomId);
      }
      yield* query.snapshots().map((snap) => snap.docs.map((doc) => AttendanceModel.fromSnapshot(doc)).toList());
    } else {
      yield _localAttendance.where((a) {
        final matchesDate = a.date == date;
        final matchesRoom = roomId == null || roomId.isEmpty || a.roomId == roomId;
        return matchesDate && matchesRoom;
      }).toList();
    }
  }

  /// Streams attendance by DateTime
  Stream<List<AttendanceModel>> attendanceStream({DateTime? date}) {
    final String dateStr = AppDateUtils.formatForStorage(date ?? DateTime.now());
    return streamAttendanceByDate(dateStr);
  }

  /// Gets absent students for a given date and optional room
  Future<List<AttendanceModel>> getAbsentStudents(String date, {String? roomId}) async {
    if (isFirebaseAvailable) {
      Query query = _firestore!
          .collection(_collection)
          .where('date', isEqualTo: date)
          .where('status', isEqualTo: AppConstants.statusAbsent);
      if (roomId != null && roomId.isNotEmpty) {
        query = query.where('roomId', isEqualTo: roomId);
      }
      final snap = await query.get();
      return snap.docs.map((doc) => AttendanceModel.fromSnapshot(doc)).toList();
    } else {
      return _localAttendance.where((a) {
        final matchesDate = a.date == date;
        final matchesRoom = roomId == null || roomId.isEmpty || a.roomId == roomId;
        return matchesDate && matchesRoom && a.isAbsent;
      }).toList();
    }
  }

  /// Student attendance history
  Stream<List<AttendanceModel>> studentHistory(String studentId) async* {
    if (isFirebaseAvailable) {
      final query = _firestore!
          .collection(_collection)
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true);
      yield* query.snapshots().map((snap) => snap.docs.map((doc) => AttendanceModel.fromSnapshot(doc)).toList());
    } else {
      yield _localAttendance.where((a) => a.studentId == studentId).toList();
    }
  }

  /// Resets demo data
  Future<void> resetDemoData() async {
    _localAttendance.clear();
    _localAttendance.addAll(SampleDataService.getInitialAttendance());
  }
}
