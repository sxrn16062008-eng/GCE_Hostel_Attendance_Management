import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'local_database.dart';

class AuthService {
  final FirebaseFirestore? _firestore;
  final LocalDatabase _localDb = LocalDatabase.instance;
  AppUser? _currentUser;

  static const String _sessionPrefKey = 'saved_user_session';

  AuthService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? _safeFirestore() {
    _seedDefaultUsers();
  }

  static FirebaseFirestore? _safeFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  AppUser? get currentUser => _currentUser;

  Future<void> _saveSessionUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapData = user.toMap();
      mapData['createdAt'] = user.createdAt.toIso8601String();
      await prefs.setString(_sessionPrefKey, jsonEncode(mapData));
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<void> _clearSessionUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionPrefKey);
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }

  Future<void> _seedDefaultUsers() async {
    try {
      if (_firestore != null) {
        // 1. Check if warden exists in Firestore
        final wardenDoc = await _firestore!
            .collection(AppConstants.colUsers)
            .where('role', isEqualTo: AppConstants.roleAdmin)
            .limit(1)
            .get();

        if (wardenDoc.docs.isEmpty) {
          final defaultWarden = AppUser(
            id: 'admin_warden',
            name: 'Chief Warden',
            email: 'warden@gce.edu',
            password: 'password123',
            phone: '9876543210',
            role: AppConstants.roleAdmin,
            assignedRoomIds: [],
            isActive: true,
            createdAt: DateTime.now(),
          );
          await _firestore!
              .collection(AppConstants.colUsers)
              .doc(defaultWarden.id)
              .set(defaultWarden.toMap());
          await _localDb.insertUser(defaultWarden);
        }

        // 2. Check if default rep exists in Firestore
        final repDoc = await _firestore!
            .collection(AppConstants.colUsers)
            .where('email', isEqualTo: 'rep@gce.edu')
            .limit(1)
            .get();

        if (repDoc.docs.isEmpty) {
          final defaultRep = AppUser(
            id: 'rep_default',
            name: 'Hostel Representative',
            email: 'rep@gce.edu',
            password: 'password123',
            phone: '9876543211',
            role: AppConstants.roleRepresentative,
            assignedRoomIds: [],
            isActive: true,
            createdAt: DateTime.now(),
          );
          await _firestore!
              .collection(AppConstants.colUsers)
              .doc(defaultRep.id)
              .set(defaultRep.toMap());
          await _localDb.insertUser(defaultRep);
        }
      } else {
        throw Exception('Firestore not initialized');
      }
    } catch (_) {
      final defaultWarden = AppUser(
        id: 'admin_warden',
        name: 'Chief Warden',
        email: 'warden@gce.edu',
        password: 'password123',
        phone: '9876543210',
        role: AppConstants.roleAdmin,
        assignedRoomIds: [],
        isActive: true,
      );
      final defaultRep = AppUser(
        id: 'rep_default',
        name: 'Hostel Representative',
        email: 'rep@gce.edu',
        password: 'password123',
        phone: '9876543211',
        role: AppConstants.roleRepresentative,
        assignedRoomIds: [],
        isActive: true,
      );
      await _localDb.insertUser(defaultWarden);
      await _localDb.insertUser(defaultRep);
    }
  }

  /// Sign In with Username or Email & Password checking Cloud Firestore users database
  Future<AppUser> signIn(String emailOrUsername, String password) async {
    final input = emailOrUsername.trim().toLowerCase();
    final cleanPass = password.trim();
    final possibleEmails = [
      input,
      if (!input.contains('@')) '$input@gce.edu',
    ];

    // 1. Try fetching from Cloud Firestore `users` collection
    if (_firestore != null) {
      try {
        final snap = await _firestore!
            .collection(AppConstants.colUsers)
            .where('email', whereIn: possibleEmails)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          final user = AppUser.fromSnapshot(snap.docs.first);

          if (user.password.isNotEmpty && user.password != cleanPass) {
            throw Exception('Incorrect password. Please try again.');
          }

          if (!user.isActive) {
            throw Exception(
                'Your representative account has been deactivated by the Warden.');
          }

          await _localDb.insertUser(user);
          _currentUser = user;
          await _saveSessionUser(user);
          return user;
        }
      } catch (e) {
        if (e.toString().contains('Incorrect password') ||
            e.toString().contains('deactivated')) {
          rethrow;
        }
      }
    }

    // 2. Fallback to Local SQLite database
    for (final candidate in possibleEmails) {
      final localUser = await _localDb.getUserByEmail(candidate);
      if (localUser != null) {
        if (localUser.password.isNotEmpty && localUser.password != cleanPass) {
          throw Exception('Incorrect password. Please try again.');
        }
        if (!localUser.isActive) {
          throw Exception('Your account is currently deactivated.');
        }
        _currentUser = localUser;
        await _saveSessionUser(localUser);
        return localUser;
      }
    }

    // 3. Fallback hardcoded credentials if database is initializing
    if ((input == 'warden' || input == 'warden@gce.edu') &&
        cleanPass == 'password123') {
      final warden = AppUser(
        id: 'admin_warden',
        name: 'Chief Warden',
        email: 'warden@gce.edu',
        password: 'password123',
        phone: '9876543210',
        role: AppConstants.roleAdmin,
      );
      _currentUser = warden;
      await _saveSessionUser(warden);
      return warden;
    }

    if ((input == 'rep' || input == 'rep@gce.edu') &&
        cleanPass == 'password123') {
      final rep = AppUser(
        id: 'rep_default',
        name: 'Hostel Representative',
        email: 'rep@gce.edu',
        password: 'password123',
        phone: '9876543211',
        role: AppConstants.roleRepresentative,
      );
      _currentUser = rep;
      await _saveSessionUser(rep);
      return rep;
    }

    throw Exception(
        'No account found for "$emailOrUsername". Please contact the Warden to create your representative account.');
  }

  /// Restores persisted session from device storage across app restarts
  Future<AppUser?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_sessionPrefKey);
      if (jsonStr != null) {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        final user = AppUser.fromMap(map, map['id'] ?? '');
        _currentUser = user;
        return user;
      }
    } catch (e) {
      debugPrint('Error restoring saved user session: $e');
    }
    return null;
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    final cleanOld = oldPassword.trim();
    final cleanNew = newPassword.trim();

    if (cleanOld.isEmpty) {
      throw Exception('Please enter your current password.');
    }
    if (cleanNew.isEmpty) {
      throw Exception('Please enter a new password.');
    }
    if (cleanNew.length < 6) {
      throw Exception('New password must be at least 6 characters long.');
    }
    if (cleanOld == cleanNew) {
      throw Exception(
          'New password cannot be identical to the current password.');
    }

    // 1. Verify against in-memory user
    if (user.password.isNotEmpty && user.password != cleanOld) {
      throw Exception(
          'Incorrect current password. Please check and try again.');
    }

    // 2. Verify and update in Firestore if available
    if (_firestore != null) {
      try {
        final docRef =
            _firestore!.collection(AppConstants.colUsers).doc(user.id);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          final currentDbPass =
              docSnap.data()?['password']?.toString() ?? '';
          if (currentDbPass.isNotEmpty && currentDbPass != cleanOld) {
            throw Exception(
                'Incorrect current password. Please check and try again.');
          }
          await docRef.update({'password': cleanNew});
        } else {
          final querySnap = await _firestore!
              .collection(AppConstants.colUsers)
              .where('email', isEqualTo: user.email.toLowerCase().trim())
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            final doc = querySnap.docs.first;
            final currentDbPass = doc.data()['password']?.toString() ?? '';
            if (currentDbPass.isNotEmpty && currentDbPass != cleanOld) {
              throw Exception(
                  'Incorrect current password. Please check and try again.');
            }
            await doc.reference.update({'password': cleanNew});
          }
        }
      } catch (e) {
        if (e.toString().contains('Incorrect current password')) {
          rethrow;
        }
      }
    }

    // 3. Update in Local Database & Session
    final updated = user.copyWith(password: cleanNew);
    await _localDb.updateUser(updated);
    _currentUser = updated;
    await _saveSessionUser(updated);
  }

  /// Updates user profile details (Name & Phone) across Firestore, SQLite, and Session
  Future<AppUser> updateUserProfile({
    required String name,
    String? phone,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Name cannot be empty.');
    }

    final cleanPhone = phone?.trim() ?? user.phone;

    // 1. Update Firestore if online
    if (_firestore != null) {
      try {
        final docRef =
            _firestore!.collection(AppConstants.colUsers).doc(user.id);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          await docRef.update({
            'name': cleanName,
            'phone': cleanPhone,
          });
        } else {
          final querySnap = await _firestore!
              .collection(AppConstants.colUsers)
              .where('email', isEqualTo: user.email.toLowerCase().trim())
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            await querySnap.docs.first.reference.update({
              'name': cleanName,
              'phone': cleanPhone,
            });
          }
        }

        // If user is Admin/Warden, also sync updatedBy in attendance_schedule
        if (user.isAdmin) {
          try {
            await _firestore!
                .collection('settings')
                .doc('attendance_schedule')
                .set({'updatedBy': cleanName}, SetOptions(merge: true));
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('Firestore profile update notice: $e');
      }
    }

    // 2. Update Local SQLite and Session
    final updated = user.copyWith(
      name: cleanName,
      phone: cleanPhone,
    );
    await _localDb.updateUser(updated);
    _currentUser = updated;
    await _saveSessionUser(updated);

    return updated;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    // Handled directly via Warden
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _clearSessionUser();
  }
}
