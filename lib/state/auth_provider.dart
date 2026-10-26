import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  AppUser? _currentUser;
  AuthStatus _status = AuthStatus.initial;
  bool _isInitialized = false;
  String? _errorMessage;

  AuthProvider(this._authService) {
    initialize();
  }

  bool get isLoggedIn => _currentUser != null;
  AppUser? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isRepresentative => _currentUser?.isRepresentative ?? true;
  AuthStatus get status => _status;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// Initializes the auth state and restores session from local storage
  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Performs sign‑in with email and password.
  Future<String?> signIn(
      {required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _authService.signIn(email, password);
      _currentUser = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return null; // success
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return _errorMessage;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Initiates password reset flow.
  Future<String?> resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Changes current user's password after verifying old password
  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _currentUser = _authService.currentUser;
      notifyListeners();
      return null; // Success
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Updates current user's profile information (Name & Phone)
  Future<String?> updateProfile({
    required String name,
    String? phone,
  }) async {
    try {
      final updated = await _authService.updateUserProfile(
        name: name,
        phone: phone,
      );
      _currentUser = updated;
      notifyListeners();
      return null; // Success
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}

// Alias for provider
typedef AppAuthProvider = AuthProvider;
