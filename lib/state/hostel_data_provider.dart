import 'dart:async';
import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../models/complaint_model.dart';
import '../models/student_complaint_model.dart';
import '../models/notification_model.dart';
import '../models/reminder_schedule_model.dart';
import '../services/local_database.dart';
import '../services/firestore_service.dart';
import '../services/attendance_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class HostelDataProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final AttendanceService _attendanceService;
  final LocalDatabase _localDb = LocalDatabase.instance;
  final NotificationService _notificationService = NotificationService.instance;

  List<String> _blocks = List.from(AppConstants.defaultBlocks);
  List<RoomModel> _rooms = [];
  List<StudentModel> _students = [];
  List<AttendanceModel> _todayAttendance = [];
  List<AppUser> _representatives = [];
  List<ComplaintModel> _complaints = [];
  List<StudentComplaintModel> _studentComplaints = [];
  List<AppNotificationModel> _notifications = [];
  ReminderScheduleModel _reminderSchedule = ReminderScheduleModel.defaultSchedule();

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _blocksSub;
  StreamSubscription? _roomsSub;
  StreamSubscription? _studentsSub;
  StreamSubscription? _attendanceSub;
  StreamSubscription? _repsSub;
  StreamSubscription? _complaintsSub;
  StreamSubscription? _studentComplaintsSub;
  StreamSubscription? _scheduleSub;
  StreamSubscription? _notificationsSub;
  Timer? _reminderHeartbeatTimer;

  HostelDataProvider({
    required FirestoreService firestoreService,
    required AttendanceService attendanceService,
  })  : _firestoreService = firestoreService,
        _attendanceService = attendanceService {
    _initDataAndStreams();
  }

  List<String> get blocks => _blocks;
  List<RoomModel> get rooms => _rooms;
  List<StudentModel> get students => _students;
  List<AttendanceModel> get todayAttendance => _todayAttendance;
  List<AppUser> get representatives => _representatives;
  List<ComplaintModel> get complaints => _complaints;
  List<StudentComplaintModel> get studentComplaints => _studentComplaints;
  List<AppNotificationModel> get notifications => _notifications;
  ReminderScheduleModel get reminderSchedule => _reminderSchedule;
  int get pendingComplaintsCount => _complaints.where((c) => c.isPending).length;
  int get pendingStudentComplaintsCount => _studentComplaints.where((c) => c.isPending || c.isUnderReview).length;
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── INITIALIZE & REAL-TIME STREAMS ──────────────────────────────────────

  Future<void> _initDataAndStreams() async {
    _isLoading = true;
    notifyListeners();

    // 1. Initial fast load from local SQLite cache
    try {
      _blocks = await _localDb.getBlocks();
      _rooms = await _localDb.getRooms();
      _students = await _localDb.getStudents();
      final today = AppDateUtils.todayStorage();
      _todayAttendance = await _localDb.getAttendanceForDate(today);
      _representatives = await _localDb.getUsers();
      _complaints = await _localDb.getAllComplaints();
      _studentComplaints = await _localDb.getAllStudentComplaints();
      _isLoading = false;
      notifyListeners();
    } catch (_) {}

    _setupFirestoreListeners();
    _notificationService.initialize();
    loadNotifications();
    loadReminderSchedule();

    // 3. Heartbeat check every 5 seconds to guarantee reminder triggers at exact scheduled minute
    _reminderHeartbeatTimer?.cancel();
    _reminderHeartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final fired = await _notificationService.checkAndTriggerDailyReminder(_reminderSchedule);
      if (fired) {
        await loadNotifications();
      }
    });
  }

  void _setupFirestoreListeners() {
    // Stream Blocks
    _blocksSub?.cancel();
    _blocksSub = _firestoreService.streamBlocks().listen(
      (blockList) {
        final merged = {...AppConstants.defaultBlocks, ...blockList}.toList();
        merged.sort();
        _blocks = merged;
        notifyListeners();
      },
      onError: (e) => debugPrint('Firestore blocks stream error: $e'),
    );

    // Stream Rooms
    _roomsSub?.cancel();
    _roomsSub = _firestoreService.streamRooms().listen(
      (roomList) async {
        _rooms = roomList;
        notifyListeners();
        // Update local cache
        for (final r in roomList) {
          await _localDb.insertRoom(r);
        }
      },
      onError: (e) => debugPrint('Firestore rooms stream error: $e'),
    );

    // Stream Students
    _studentsSub?.cancel();
    _studentsSub = _firestoreService.streamStudents().listen(
      (studentList) async {
        _students = studentList;
        notifyListeners();
        // Update local cache
        for (final s in studentList) {
          await _localDb.insertStudent(s);
        }
      },
      onError: (e) => debugPrint('Firestore students stream error: $e'),
    );

    // Stream Today's Attendance
    final today = AppDateUtils.todayStorage();
    _attendanceSub?.cancel();
    _attendanceSub = _attendanceService.streamAttendanceByDate(today).listen(
      (records) async {
        _todayAttendance = records;
        notifyListeners();
        if (records.isNotEmpty) {
          await _localDb.insertAttendanceBatch(records);
        }
      },
      onError: (e) => debugPrint('Firestore attendance stream error: $e'),
    );

    // Stream Representatives
    _repsSub?.cancel();
    _repsSub = _firestoreService.streamRepresentatives().listen(
      (repList) async {
        _representatives = repList;
        notifyListeners();
        for (final rep in repList) {
          await _localDb.insertUser(rep);
        }
      },
      onError: (e) => debugPrint('Firestore reps stream error: $e'),
    );

    // Stream Complaints (Room / Facility)
    _complaintsSub?.cancel();
    _complaintsSub = _firestoreService.streamComplaints().listen(
      (complaintList) async {
        _complaints = complaintList;
        notifyListeners();
        await _localDb.insertComplaintsBatch(complaintList);
      },
      onError: (e) => debugPrint('Firestore complaints stream error: $e'),
    );

    // Stream Student Complaints (Conduct / Disciplinary)
    _studentComplaintsSub?.cancel();
    _studentComplaintsSub = _firestoreService.streamStudentComplaints().listen(
      (list) async {
        _studentComplaints = list;
        notifyListeners();
        await _localDb.insertStudentComplaintsBatch(list);
      },
      onError: (e) => debugPrint('Firestore student complaints stream error: $e'),
    );

    // Stream Reminder Schedule
    _scheduleSub?.cancel();
    _scheduleSub = _notificationService.reminderScheduleStream().listen(
      (schedule) {
        _reminderSchedule = schedule;
        _notificationService.scheduleDailyReminder(schedule);
        notifyListeners();
      },
      onError: (e) => debugPrint('Reminder schedule stream error: $e'),
    );

    // Stream Notifications
    _notificationsSub?.cancel();
    _notificationsSub = _notificationService.notificationsStream().listen(
      (notifList) {
        _notifications = notifList;
        notifyListeners();
      },
      onError: (e) => debugPrint('Notifications stream error: $e'),
    );
  }

  Future<void> refreshData() async {
    _setupFirestoreListeners();
    try {
      _rooms = await _firestoreService.getRooms();
      _students = await _firestoreService.getAllStudents();
      final today = AppDateUtils.todayStorage();
      _todayAttendance = await _attendanceService.getAttendanceByDate(today);
      _representatives = await _firestoreService.getRepresentatives();
      _complaints = await _firestoreService.getComplaints();
      _studentComplaints = await _firestoreService.getStudentComplaints();
      await loadReminderSchedule();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // =========================================================================
  // BLOCK OPERATIONS
  // =========================================================================

  Future<void> addBlock(String blockName) async {
    final name = blockName.trim();
    if (name.isEmpty) return;
    try {
      await _firestoreService.addBlock(name);
      await _localDb.insertBlock(name);
      if (!_blocks.contains(name)) {
        _blocks.add(name);
        _blocks.sort();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteBlock(String blockName) async {
    final name = blockName.trim();
    try {
      await _firestoreService.deleteBlock(name);
      await _localDb.deleteBlock(name);
      _blocks.remove(name);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // =========================================================================
  // STATS & CALCULATIONS
  // =========================================================================

  AttendanceSummary getTodaySummary([String? roomId]) {
    final targetStudents = (roomId != null && roomId.isNotEmpty)
        ? _students.where((s) => s.roomId == roomId).toList()
        : _students;

    final total = targetStudents.length;
    if (total == 0) {
      return const AttendanceSummary(
        totalStudents: 0,
        presentCount: 0,
        absentCount: 0,
        notMarkedCount: 0,
      );
    }

    final todayMap = {for (var a in _todayAttendance) a.studentId: a.status};

    int present = 0;
    int absent = 0;
    int notMarked = 0;

    for (final s in targetStudents) {
      final status = todayMap[s.id];
      if (status == 'present') {
        present++;
      } else if (status == 'absent') {
        absent++;
      } else {
        notMarked++;
      }
    }

    return AttendanceSummary(
      totalStudents: total,
      presentCount: present,
      absentCount: absent,
      notMarkedCount: notMarked,
    );
  }

  AttendanceSummary getTodaySummaryForRooms(List<String>? roomIds) {
    if (roomIds == null || roomIds.isEmpty) {
      return getTodaySummary();
    }
    final targetStudents = _students.where((s) => roomIds.contains(s.roomId)).toList();
    final total = targetStudents.length;
    if (total == 0) {
      return const AttendanceSummary(
        totalStudents: 0,
        presentCount: 0,
        absentCount: 0,
        notMarkedCount: 0,
      );
    }

    final todayMap = {for (var a in _todayAttendance) a.studentId: a.status};

    int present = 0;
    int absent = 0;
    int notMarked = 0;

    for (final s in targetStudents) {
      final status = todayMap[s.id];
      if (status == 'present') {
        present++;
      } else if (status == 'absent') {
        absent++;
      } else {
        notMarked++;
      }
    }

    return AttendanceSummary(
      totalStudents: total,
      presentCount: present,
      absentCount: absent,
      notMarkedCount: notMarked,
    );
  }

  List<StudentModel> getTodayAbsentStudents([String? roomId]) {
    final absentIds = _todayAttendance
        .where((a) => a.isAbsent && (roomId == null || roomId.isEmpty || a.roomId == roomId))
        .map((a) => a.studentId)
        .toSet();

    return _students.where((s) => absentIds.contains(s.id)).toList();
  }

  List<StudentModel> getTodayAbsentStudentsForRooms(List<String>? roomIds) {
    if (roomIds == null || roomIds.isEmpty) {
      return getTodayAbsentStudents();
    }
    final absentIds = _todayAttendance
        .where((a) => a.isAbsent && roomIds.contains(a.roomId))
        .map((a) => a.studentId)
        .toSet();

    return _students.where((s) => absentIds.contains(s.id)).toList();
  }

  // =========================================================================
  // ROOM OPERATIONS
  // =========================================================================

  Future<RoomModel> addRoom({
    required String roomNumber,
    required String block,
    required int capacity,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await addBlock(block);
      final room = await _firestoreService.addRoom(
        roomNumber: roomNumber,
        block: block,
        capacity: capacity,
      );
      await _localDb.insertRoom(room);
      _isLoading = false;
      notifyListeners();
      return room;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRoom({
    required String roomId,
    required String roomNumber,
    required String block,
    required int capacity,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await addBlock(block);
      await _firestoreService.updateRoom(
        roomId: roomId,
        roomNumber: roomNumber,
        block: block,
        capacity: capacity,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.deleteRoom(roomId);
      await _localDb.deleteRoom(roomId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // =========================================================================
  // STUDENT OPERATIONS
  // =========================================================================

  Future<void> addStudent({
    required String name,
    required String registerNumber,
    required String rollNumber,
    required String department,
    required String year,
    required String phone,
    required String roomId,
    String? photoUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final student = await _firestoreService.addStudent(
        name: name,
        registerNumber: registerNumber,
        rollNumber: rollNumber,
        department: department,
        year: year,
        phone: phone,
        roomId: roomId,
        photoUrl: photoUrl,
      );
      await _localDb.insertStudent(student);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateStudent(
        studentId: studentId,
        name: name,
        registerNumber: registerNumber,
        rollNumber: rollNumber,
        department: department,
        year: year,
        phone: phone,
        newRoomId: newRoomId,
        photoUrl: photoUrl,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteStudent(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.deleteStudent(studentId);
      await _localDb.deleteStudent(studentId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // =========================================================================
  // ATTENDANCE OPERATIONS
  // =========================================================================

  Future<List<StudentModel>> saveAttendance({
    required String roomId,
    required String roomNumber,
    required String date,
    required String markedBy,
    required String markedByName,
    required Map<String, String> statusMap,
    required List<StudentModel> students,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<StudentModel> absentStudents = [];
      final List<AttendanceModel> attendanceRecords = [];

      for (final student in students) {
        final status = statusMap[student.id] ?? AppConstants.statusPresent;
        final record = AttendanceModel(
          id: '${date}_${student.id}',
          studentId: student.id,
          studentName: student.name,
          registerNumber: student.registerNumber,
          roomId: roomId,
          roomNumber: roomNumber,
          date: date,
          status: status,
          markedBy: markedBy,
          markedByName: markedByName,
          timestamp: DateTime.now(),
        );
        attendanceRecords.add(record);
        if (status == AppConstants.statusAbsent) {
          absentStudents.add(student);
        }
      }

      // Save to Cloud Firestore
      await _attendanceService.saveRoomAttendance(
        roomId: roomId,
        attendanceRecords: attendanceRecords,
        date: date,
        markedBy: markedBy,
      );

      // Also save to local SQLite
      await _localDb.insertAttendanceBatch(attendanceRecords);

      _isLoading = false;
      notifyListeners();
      return absentStudents;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<AttendanceModel>> fetchAttendanceHistory({
    required String date,
    String? roomId,
  }) async {
    try {
      return await _attendanceService.getAttendanceByDate(date, roomId: roomId);
    } catch (_) {
      return await _localDb.getAttendanceForDate(date);
    }
  }

  Future<List<AttendanceModel>> fetchAbsentStudentsHistory({
    required String date,
    String? roomId,
  }) async {
    try {
      return await _attendanceService.getAbsentStudents(date, roomId: roomId);
    } catch (_) {
      final all = await _localDb.getAttendanceForDate(date);
      return all.where((a) => a.status == AppConstants.statusAbsent).toList();
    }
  }

  // =========================================================================
  // REPRESENTATIVE OPERATIONS (WARDEN ONLY)
  // =========================================================================

  Future<void> addRepresentative({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> assignedRoomIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.addRepresentative(
        name: name,
        email: email,
        password: password,
        phone: phone,
        assignedRoomIds: assignedRoomIds,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateRepresentative(
        userId: userId,
        name: name,
        email: email,
        password: password,
        phone: phone,
        assignedRoomIds: assignedRoomIds,
        isActive: isActive,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRepresentative(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.deleteRepresentative(userId);
      await _localDb.deleteUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleRepresentativeStatus(String userId, bool isActive) async {
    try {
      await _firestoreService.toggleRepresentativeStatus(userId, isActive);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // =========================================================================
  // COMPLAINT OPERATIONS (REPRESENTATIVE & WARDEN)
  // =========================================================================

  List<ComplaintModel> getComplaintsForRooms(List<String>? roomIds) {
    if (roomIds == null || roomIds.isEmpty) {
      return _complaints;
    }
    return _complaints.where((c) => roomIds.contains(c.roomId)).toList();
  }

  Future<void> addComplaint({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final complaint = await _firestoreService.addComplaint(
        roomId: roomId,
        roomNumber: roomNumber,
        block: block,
        category: category,
        title: title,
        description: description,
        createdBy: createdBy,
        createdByName: createdByName,
        createdByPhone: createdByPhone,
      );
      await _localDb.insertComplaint(complaint);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? wardenRemarks,
  }) async {
    try {
      await _firestoreService.updateComplaintStatus(
        complaintId: complaintId,
        status: status,
        wardenRemarks: wardenRemarks,
      );
      final index = _complaints.indexWhere((c) => c.id == complaintId);
      if (index >= 0) {
        _complaints[index] = _complaints[index].copyWith(
          status: status,
          wardenRemarks: wardenRemarks,
          resolvedAt: status == AppConstants.complaintResolved ? DateTime.now() : null,
        );
        await _localDb.updateComplaint(_complaints[index]);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteComplaint(String complaintId) async {
    try {
      await _firestoreService.deleteComplaint(complaintId);
      await _localDb.deleteComplaint(complaintId);
      _complaints.removeWhere((c) => c.id == complaintId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // =========================================================================
  // STUDENT COMPLAINT OPERATIONS (DISCIPLINARY / CONDUCT)
  // =========================================================================

  List<StudentComplaintModel> getStudentComplaintsForStudent(String studentId) {
    return _studentComplaints.where((c) => c.studentId == studentId).toList();
  }

  Future<void> addStudentComplaint({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final complaint = await _firestoreService.addStudentComplaint(
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
      );
      await _localDb.insertStudentComplaint(complaint);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateStudentComplaintStatus({
    required String complaintId,
    required String status,
    String? wardenAction,
    String? wardenRemarks,
  }) async {
    try {
      await _firestoreService.updateStudentComplaintStatus(
        complaintId: complaintId,
        status: status,
        wardenAction: wardenAction,
        wardenRemarks: wardenRemarks,
      );
      final index = _studentComplaints.indexWhere((c) => c.id == complaintId);
      if (index >= 0) {
        final now = (status == 'resolved' || status == 'action_taken' || status == 'dismissed') ? DateTime.now() : null;
        _studentComplaints[index] = _studentComplaints[index].copyWith(
          status: status,
          wardenAction: wardenAction,
          wardenRemarks: wardenRemarks,
          resolvedAt: now,
        );
        await _localDb.updateStudentComplaint(_studentComplaints[index]);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteStudentComplaint(String complaintId) async {
    try {
      await _firestoreService.deleteStudentComplaint(complaintId);
      await _localDb.deleteStudentComplaint(complaintId);
      _studentComplaints.removeWhere((c) => c.id == complaintId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // ─── NOTIFICATION & REMINDER MANAGEMENT ─────────────────────────────────

  Future<void> loadNotifications() async {
    try {
      _notifications = await _notificationService.fetchNotifications();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> sendAttendanceReminder({
    required String title,
    required String message,
    String senderName = 'Chief Warden',
  }) async {
    try {
      final notif = await _notificationService.sendAttendanceReminder(
        title: title,
        message: message,
        senderName: senderName,
      );
      _notifications.insert(0, notif);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    try {
      await _notificationService.markAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index >= 0) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadReminderSchedule() async {
    try {
      _reminderSchedule = await _notificationService.fetchReminderSchedule();
      await _notificationService.scheduleDailyReminder(_reminderSchedule);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateReminderSchedule(ReminderScheduleModel schedule) async {
    try {
      _reminderSchedule = schedule;
      notifyListeners();
      await _notificationService.saveReminderSchedule(schedule);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleReminderSchedule(bool isEnabled) async {
    try {
      _reminderSchedule = _reminderSchedule.copyWith(
        isEnabled: isEnabled,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      await _notificationService.saveReminderSchedule(_reminderSchedule);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void resetToDemo() {
    _initDataAndStreams();
  }

  @override
  void dispose() {
    _blocksSub?.cancel();
    _roomsSub?.cancel();
    _studentsSub?.cancel();
    _attendanceSub?.cancel();
    _repsSub?.cancel();
    _complaintsSub?.cancel();
    _studentComplaintsSub?.cancel();
    _scheduleSub?.cancel();
    _notificationsSub?.cancel();
    _reminderHeartbeatTimer?.cancel();
    super.dispose();
  }
}

