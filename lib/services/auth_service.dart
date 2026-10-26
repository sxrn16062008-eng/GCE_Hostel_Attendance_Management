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

    // 1. Seed into SQLite database first so local/offline auth is always ready
    try {
      await _localDb.insertUser(defaultWarden);
      await _localDb.insertUser(defaultRep);
    } catch (_) {}

    // 2. Ensure users exist in Cloud Firestore
    try {
      if (_firestore != null) {
        final wardenDoc = await _firestore!
            .collection(AppConstants.colUsers)
            .where('role', isEqualTo: AppConstants.roleAdmin)
            .limit(1)
            .get();

        if (wardenDoc.docs.isEmpty) {
          await _firestore!
              .collection(AppConstants.colUsers)
              .doc(defaultWarden.id)
              .set(defaultWarden.toMap());
        }

        final repDoc = await _firestore!
            .collection(AppConstants.colUsers)
            .where('email', isEqualTo: 'rep@gce.edu')
            .limit(1)
            .get();

        if (repDoc.docs.isEmpty) {
          await _firestore!
              .collection(AppConstants.colUsers)
              .doc(defaultRep.id)
              .set(defaultRep.toMap());
        }
      }
    } catch (e) {
      debugPrint('Firestore default user seed notice: $e');
    }
  }

  /// Sign In with Username or Email & Password checking Cloud Firestore and local databases
  Future<AppUser> signIn(String emailOrUsername, String password) async {
    final input = emailOrUsername.trim().toLowerCase();
    final cleanPass = password.trim();

    if (input.isEmpty) {
      throw Exception('Please enter your username or email address.');
    }
    if (cleanPass.isEmpty) {
      throw Exception('Please enter your password.');
    }

    final isAdminAlias = [
      'warden',
      'admin',
      'chief warden',
      'chiefwarden',
      'admin_warden',
      'warden@gce.edu',
      'admin@gce.edu',
    ].contains(input);

    final isRepAlias = [
      'rep',
      'rep1',
      'representative',
      'rep_default',
      'rep@gce.edu',
    ].contains(input);

    final possibleEmails = <String>[
      input,
      if (!input.contains('@')) '$input@gce.edu',
      if (isAdminAlias) ...['warden@gce.edu', 'admin@gce.edu', 'warden', 'admin'],
      if (isRepAlias) ...['rep@gce.edu', 'rep', 'representative'],
    ];

    AppUser? foundUser;

    // 1. Try fetching from Cloud Firestore `users` collection
    if (_firestore != null) {
      try {
        const timeout = Duration(seconds: 3);
        // 1a. Direct document lookup by doc ID
        final docRef = _firestore!.collection(AppConstants.colUsers).doc(input);
        final docSnap = await docRef.get().timeout(timeout);
        if (docSnap.exists && docSnap.data() != null) {
          foundUser = AppUser.fromSnapshot(docSnap);
        }

        // 1b. If admin alias, try admin_warden doc directly
        if (foundUser == null && isAdminAlias) {
          final wardenDoc = await _firestore!
              .collection(AppConstants.colUsers)
              .doc('admin_warden')
              .get()
              .timeout(timeout);
          if (wardenDoc.exists && wardenDoc.data() != null) {
            foundUser = AppUser.fromSnapshot(wardenDoc);
          }
        }

        // 1c. Search by email candidates in Firestore
        if (foundUser == null) {
          final emailSnap = await _firestore!
              .collection(AppConstants.colUsers)
              .where('email', whereIn: possibleEmails.toSet().take(10).toList())
              .limit(1)
              .get()
              .timeout(timeout);

          if (emailSnap.docs.isNotEmpty) {
            foundUser = AppUser.fromSnapshot(emailSnap.docs.first);
          }
        }

        // 1d. If admin alias and not yet found, find user with role 'admin'
        if (foundUser == null && isAdminAlias) {
          final adminSnap = await _firestore!
              .collection(AppConstants.colUsers)
              .where('role', isEqualTo: AppConstants.roleAdmin)
              .limit(1)
              .get()
              .timeout(timeout);
          if (adminSnap.docs.isNotEmpty) {
            foundUser = AppUser.fromSnapshot(adminSnap.docs.first);
          }
        }

        // 1e. Search by 10-digit phone number if input is digits
        if (foundUser == null && RegExp(r'^[0-9]{10}$').hasMatch(input)) {
          final phoneSnap = await _firestore!
              .collection(AppConstants.colUsers)
              .where('phone', isEqualTo: input)
              .limit(1)
              .get()
              .timeout(timeout);
          if (phoneSnap.docs.isNotEmpty) {
            foundUser = AppUser.fromSnapshot(phoneSnap.docs.first);
          }
        }
      } catch (e) {
        debugPrint('Firestore authentication lookup notice: $e');
      }
    }

    // 2. Fallback to Local SQLite database
    if (foundUser == null) {
      for (final candidate in possibleEmails.toSet()) {
        final localUser = await _localDb.getUserByEmail(candidate);
        if (localUser != null) {
          foundUser = localUser;
          break;
        }
      }

      if (foundUser == null && isAdminAlias) {
        final allUsers = await _localDb.getUsers();
        for (final u in allUsers) {
          if (u.isAdmin) {
            foundUser = u;
            break;
          }
        }
      }
    }

    // 3. Fallback to default in-memory accounts if not yet created in DB
    if (foundUser == null) {
      if (isAdminAlias) {
        foundUser = AppUser(
          id: 'admin_warden',
          name: 'Chief Warden',
          email: 'warden@gce.edu',
          password: 'password123',
          phone: '9876543210',
          role: AppConstants.roleAdmin,
          assignedRoomIds: [],
          isActive: true,
        );
      } else if (isRepAlias) {
        foundUser = AppUser(
          id: 'rep_default',
          name: 'Hostel Representative',
          email: 'rep@gce.edu',
          password: 'password123',
          phone: '9876543211',
          role: AppConstants.roleRepresentative,
          assignedRoomIds: [],
          isActive: true,
        );
      }
    }

    // 4. Validate credentials and account status
    if (foundUser != null) {
      if (foundUser.password.isNotEmpty && foundUser.password != cleanPass) {
        throw Exception('Incorrect password. Please verify your password and try again.');
      }

      if (!foundUser.isActive) {
        throw Exception(
            'Your representative account has been deactivated by the Warden.');
      }

      await _localDb.insertUser(foundUser);
      _currentUser = foundUser;
      await _saveSessionUser(foundUser);
      return foundUser;
    }

    throw Exception(
        'No account found for "$emailOrUsername". For Warden login, enter username "warden" or "admin" with password "password123".');
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
