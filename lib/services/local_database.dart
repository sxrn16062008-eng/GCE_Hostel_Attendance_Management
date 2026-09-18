import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/room_model.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../models/complaint_model.dart';
import '../models/student_complaint_model.dart';
import '../utils/constants.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gce_hostel_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      return await databaseFactoryFfiWeb.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
          onOpen: _onOpenDB,
        ),
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: _onOpenDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT,
        phone TEXT,
        role TEXT NOT NULL,
        assignedRoomIds TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS blocks (
        name TEXT PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS rooms (
        id TEXT PRIMARY KEY,
        roomNumber TEXT NOT NULL,
        block TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        studentCount INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS students (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        registerNumber TEXT NOT NULL,
        rollNumber TEXT NOT NULL,
        department TEXT NOT NULL,
        year TEXT NOT NULL,
        phone TEXT NOT NULL,
        roomId TEXT NOT NULL,
        roomNumber TEXT NOT NULL,
        photoUrl TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id TEXT PRIMARY KEY,
        studentId TEXT NOT NULL,
        studentName TEXT NOT NULL,
        registerNumber TEXT NOT NULL,
        roomId TEXT NOT NULL,
        roomNumber TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        markedBy TEXT,
        markedByName TEXT,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS complaints (
        id TEXT PRIMARY KEY,
        roomId TEXT NOT NULL,
        roomNumber TEXT NOT NULL,
        block TEXT NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        createdBy TEXT NOT NULL,
        createdByName TEXT NOT NULL,
        createdByPhone TEXT,
        createdAt TEXT NOT NULL,
        resolvedAt TEXT,
        wardenRemarks TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS student_complaints (
        id TEXT PRIMARY KEY,
        studentId TEXT NOT NULL,
        studentName TEXT NOT NULL,
        rollNumber TEXT NOT NULL,
        registerNumber TEXT,
        roomNumber TEXT NOT NULL,
        block TEXT,
        department TEXT,
        incidentCategory TEXT NOT NULL,
        severity TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        reportedBy TEXT NOT NULL,
        reportedByName TEXT NOT NULL,
        reportedByRole TEXT,
        reportedByPhone TEXT,
        status TEXT NOT NULL,
        wardenAction TEXT,
        wardenRemarks TEXT,
        createdAt TEXT NOT NULL,
        resolvedAt TEXT
      )
    ''');

    // Seed default blocks
    for (final b in AppConstants.defaultBlocks) {
      await db.insert(
        'blocks',
        {'name': b},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future _onOpenDB(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT,
        phone TEXT,
        role TEXT NOT NULL,
        assignedRoomIds TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS blocks (
        name TEXT PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS rooms (
        id TEXT PRIMARY KEY,
        roomNumber TEXT NOT NULL,
        block TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        studentCount INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS students (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        registerNumber TEXT NOT NULL,
        rollNumber TEXT NOT NULL,
        department TEXT NOT NULL,
        year TEXT NOT NULL,
        phone TEXT NOT NULL,
        roomId TEXT NOT NULL,
        roomNumber TEXT NOT NULL,
        photoUrl TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id TEXT PRIMARY KEY,
        studentId TEXT NOT NULL,
        studentName TEXT NOT NULL,
        registerNumber TEXT NOT NULL,
        roomId TEXT NOT NULL,
        roomNumber TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        markedBy TEXT,
        markedByName TEXT,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS complaints (
        id TEXT PRIMARY KEY,
        roomId TEXT NOT NULL,
        roomNumber TEXT NOT NULL,
        block TEXT NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        createdBy TEXT NOT NULL,
        createdByName TEXT NOT NULL,
        createdByPhone TEXT,
        createdAt TEXT NOT NULL,
        resolvedAt TEXT,
        wardenRemarks TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS student_complaints (
        id TEXT PRIMARY KEY,
        studentId TEXT NOT NULL,
        studentName TEXT NOT NULL,
        rollNumber TEXT NOT NULL,
        registerNumber TEXT,
        roomNumber TEXT NOT NULL,
        block TEXT,
        department TEXT,
        incidentCategory TEXT NOT NULL,
        severity TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        reportedBy TEXT NOT NULL,
        reportedByName TEXT NOT NULL,
        reportedByRole TEXT,
        reportedByPhone TEXT,
        status TEXT NOT NULL,
        wardenAction TEXT,
        wardenRemarks TEXT,
        createdAt TEXT NOT NULL,
        resolvedAt TEXT
      )
    ''');

    // Ensure default blocks
    for (final b in AppConstants.defaultBlocks) {
      await db.insert(
        'blocks',
        {'name': b},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ─── USERS / REPRESENTATIVES ──────────────────────────────────────────────

  Future<void> insertUser(AppUser user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'id': user.id,
        'name': user.name,
        'email': user.email.toLowerCase().trim(),
        'password': user.password,
        'phone': user.phone,
        'role': user.role,
        'assignedRoomIds': jsonEncode(user.assignedRoomIds),
        'isActive': user.isActive ? 1 : 0,
        'createdAt': user.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUser(AppUser user) async {
    final db = await database;
    await db.update(
      'users',
      {
        'name': user.name,
        'email': user.email.toLowerCase().trim(),
        'password': user.password,
        'phone': user.phone,
        'role': user.role,
        'assignedRoomIds': jsonEncode(user.assignedRoomIds),
        'isActive': user.isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AppUser>> getUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'name ASC');
    return maps.map((m) {
      List<String> assigned = [];
      try {
        if (m['assignedRoomIds'] != null) {
          assigned = List<String>.from(jsonDecode(m['assignedRoomIds'] as String));
        }
      } catch (_) {}

      return AppUser(
        id: m['id'] as String,
        name: m['name'] as String,
        email: m['email'] as String,
        password: m['password'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        role: m['role'] as String? ?? AppConstants.roleRepresentative,
        assignedRoomIds: assigned,
        isActive: (m['isActive'] as int? ?? 1) == 1,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase().trim()],
    );
    if (maps.isEmpty) return null;
    final m = maps.first;
    List<String> assigned = [];
    try {
      if (m['assignedRoomIds'] != null) {
        assigned = List<String>.from(jsonDecode(m['assignedRoomIds'] as String));
      }
    } catch (_) {}

    return AppUser(
      id: m['id'] as String,
      name: m['name'] as String,
      email: m['email'] as String,
      password: m['password'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      role: m['role'] as String? ?? AppConstants.roleRepresentative,
      assignedRoomIds: assigned,
      isActive: (m['isActive'] as int? ?? 1) == 1,
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  // ─── BLOCKS ──────────────────────────────────────────────────────────────

  Future<void> insertBlock(String name) async {
    final db = await database;
    await db.insert(
      'blocks',
      {'name': name.trim()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getBlocks() async {
    final db = await database;
    final maps = await db.query('blocks', orderBy: 'name ASC');
    if (maps.isEmpty) {
      for (final b in AppConstants.defaultBlocks) {
        await db.insert('blocks', {'name': b}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      return List.from(AppConstants.defaultBlocks);
    }
    return maps.map((m) => m['name'] as String).toList();
  }

  Future<void> deleteBlock(String name) async {
    final db = await database;
    await db.delete('blocks', where: 'name = ?', whereArgs: [name.trim()]);
  }

  // ─── ROOMS ───────────────────────────────────────────────────────────────

  Future<void> insertRoom(RoomModel room) async {
    final db = await database;
    await insertBlock(room.block);
    await db.insert(
      'rooms',
      {
        'id': room.id,
        'roomNumber': room.roomNumber,
        'block': room.block,
        'capacity': room.capacity,
        'studentCount': room.studentCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRoom(RoomModel room) async {
    final db = await database;
    await insertBlock(room.block);
    await db.update(
      'rooms',
      {
        'roomNumber': room.roomNumber,
        'block': room.block,
        'capacity': room.capacity,
        'studentCount': room.studentCount,
      },
      where: 'id = ?',
      whereArgs: [room.id],
    );
  }

  Future<void> deleteRoom(String id) async {
    final db = await database;
    await db.delete('rooms', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<RoomModel>> getRooms() async {
    final db = await database;
    final maps = await db.query('rooms', orderBy: 'block ASC, roomNumber ASC');
    return maps.map((m) => RoomModel(
      id: m['id'] as String,
      roomNumber: m['roomNumber'] as String,
      block: m['block'] as String,
      capacity: m['capacity'] as int,
      studentCount: m['studentCount'] as int? ?? 0,
    )).toList();
  }

  // ─── STUDENTS ─────────────────────────────────────────────────────────────

  Future<void> insertStudent(StudentModel s) async {
    final db = await database;
    await db.insert(
      'students',
      {
        'id': s.id,
        'name': s.name,
        'registerNumber': s.registerNumber,
        'rollNumber': s.rollNumber,
        'department': s.department,
        'year': s.year,
        'phone': s.phone,
        'roomId': s.roomId,
        'roomNumber': s.roomNumber,
        'photoUrl': s.photoUrl,
        'createdAt': s.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateStudent(StudentModel s) async {
    final db = await database;
    await db.update(
      'students',
      {
        'name': s.name,
        'registerNumber': s.registerNumber,
        'rollNumber': s.rollNumber,
        'department': s.department,
        'year': s.year,
        'phone': s.phone,
        'roomId': s.roomId,
        'roomNumber': s.roomNumber,
        'photoUrl': s.photoUrl,
      },
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  Future<void> deleteStudent(String id) async {
    final db = await database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<StudentModel>> getStudents() async {
    final db = await database;
    final maps = await db.query('students', orderBy: 'name ASC');
    return maps.map((m) => StudentModel(
      id: m['id'] as String,
      name: m['name'] as String,
      registerNumber: m['registerNumber'] as String,
      rollNumber: m['rollNumber'] as String,
      department: m['department'] as String,
      year: m['year'] as String,
      phone: m['phone'] as String,
      roomId: m['roomId'] as String,
      roomNumber: m['roomNumber'] as String,
      photoUrl: m['photoUrl'] as String?,
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    )).toList();
  }

  // ─── ATTENDANCE ──────────────────────────────────────────────────────────

  Future<void> insertAttendance(AttendanceModel a) async {
    final db = await database;
    await db.insert(
      'attendance',
      {
        'id': a.id,
        'studentId': a.studentId,
        'studentName': a.studentName,
        'registerNumber': a.registerNumber,
        'roomId': a.roomId,
        'roomNumber': a.roomNumber,
        'date': a.date,
        'status': a.status,
        'markedBy': a.markedBy,
        'markedByName': a.markedByName,
        'timestamp': a.timestamp.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertAttendanceBatch(List<AttendanceModel> list) async {
    final db = await database;
    final batch = db.batch();
    for (final a in list) {
      batch.insert(
        'attendance',
        {
          'id': a.id,
          'studentId': a.studentId,
          'studentName': a.studentName,
          'registerNumber': a.registerNumber,
          'roomId': a.roomId,
          'roomNumber': a.roomNumber,
          'date': a.date,
          'status': a.status,
          'markedBy': a.markedBy,
          'markedByName': a.markedByName,
          'timestamp': a.timestamp.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AttendanceModel>> getAttendanceForDate(String date) async {
    final db = await database;
    final maps = await db.query('attendance', where: 'date = ?', whereArgs: [date]);
    return maps.map((m) => AttendanceModel(
      id: m['id'] as String,
      studentId: m['studentId'] as String,
      studentName: m['studentName'] as String,
      registerNumber: m['registerNumber'] as String,
      roomId: m['roomId'] as String,
      roomNumber: m['roomNumber'] as String,
      date: m['date'] as String,
      status: m['status'] as String,
      markedBy: m['markedBy'] as String? ?? '',
      markedByName: m['markedByName'] as String? ?? 'Representative',
      timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ?? DateTime.now(),
    )).toList();
  }

  Future<List<AttendanceModel>> getAllAttendance() async {
    final db = await database;
    final maps = await db.query('attendance', orderBy: 'date DESC');
    return maps.map((m) => AttendanceModel(
      id: m['id'] as String,
      studentId: m['studentId'] as String,
      studentName: m['studentName'] as String,
      registerNumber: m['registerNumber'] as String,
      roomId: m['roomId'] as String,
      roomNumber: m['roomNumber'] as String,
      date: m['date'] as String,
      status: m['status'] as String,
      markedBy: m['markedBy'] as String? ?? '',
      markedByName: m['markedByName'] as String? ?? 'Representative',
      timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ?? DateTime.now(),
    )).toList();
  }

  // ─── COMPLAINTS ─────────────────────────────────────────────────────────

  Future<void> insertComplaint(ComplaintModel complaint) async {
    final db = await database;
    await db.insert(
      'complaints',
      complaint.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertComplaintsBatch(List<ComplaintModel> complaints) async {
    final db = await database;
    final batch = db.batch();
    for (final c in complaints) {
      batch.insert(
        'complaints',
        c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateComplaint(ComplaintModel complaint) async {
    final db = await database;
    await db.update(
      'complaints',
      complaint.toMap(),
      where: 'id = ?',
      whereArgs: [complaint.id],
    );
  }

  Future<void> deleteComplaint(String id) async {
    final db = await database;
    await db.delete(
      'complaints',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ComplaintModel>> getAllComplaints() async {
    final db = await database;
    final maps = await db.query('complaints', orderBy: 'createdAt DESC');
    return maps.map((m) => ComplaintModel.fromMap(m)).toList();
  }

  // ─── STUDENT COMPLAINTS (CONDUCT / DISCIPLINARY) ───────────────────────

  Future<void> insertStudentComplaint(StudentComplaintModel sc) async {
    final db = await database;
    await db.insert(
      'student_complaints',
      sc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertStudentComplaintsBatch(List<StudentComplaintModel> list) async {
    final db = await database;
    final batch = db.batch();
    for (final sc in list) {
      batch.insert(
        'student_complaints',
        sc.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateStudentComplaint(StudentComplaintModel sc) async {
    final db = await database;
    await db.update(
      'student_complaints',
      sc.toMap(),
      where: 'id = ?',
      whereArgs: [sc.id],
    );
  }

  Future<void> deleteStudentComplaint(String id) async {
    final db = await database;
    await db.delete(
      'student_complaints',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<StudentComplaintModel>> getAllStudentComplaints() async {
    final db = await database;
    final maps = await db.query('student_complaints', orderBy: 'createdAt DESC');
    return maps.map((m) => StudentComplaintModel.fromMap(m)).toList();
  }

  Future<List<StudentComplaintModel>> getStudentComplaintsByStudent(String studentId) async {
    final db = await database;
    final maps = await db.query(
      'student_complaints',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => StudentComplaintModel.fromMap(m)).toList();
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

