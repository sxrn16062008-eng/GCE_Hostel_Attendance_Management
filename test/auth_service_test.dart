import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gce_boys_hostel/services/auth_service.dart';
import 'package:gce_boys_hostel/state/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  SharedPreferences.setMockInitialValues({});

  group('Auth & Session Persistence Tests', () {
    test('SignIn, session persistence across restarts, and Change Password Flow', () async {
      final authService = AuthService();
      final authProvider = AuthProvider(authService);

      // 1. Sign in with default credentials
      final err = await authProvider.signIn(
        email: 'warden@gce.edu',
        password: 'password123',
      );
      expect(err, isNull);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.currentUser?.email, 'warden@gce.edu');

      // 2. Simulate app restart with a fresh AuthService/AuthProvider instance
      final restartedAuthService = AuthService();
      final restartedAuthProvider = AuthProvider(restartedAuthService);
      await restartedAuthProvider.initialize();

      // Session must be restored automatically without prompting for login
      expect(restartedAuthProvider.isLoggedIn, isTrue);
      expect(restartedAuthProvider.currentUser?.email, 'warden@gce.edu');
      expect(restartedAuthProvider.currentUser?.isAdmin, isTrue);

      // 3. Try changing password with wrong old password -> should fail
      final wrongOldErr = await restartedAuthProvider.changePassword(
        oldPassword: 'wrongOldPassword',
        newPassword: 'newSecretPass123',
      );
      expect(wrongOldErr, isNotNull);
      expect(wrongOldErr!.toLowerCase(), contains('incorrect current password'));

      // 4. Change password successfully
      final success = await restartedAuthProvider.changePassword(
        oldPassword: 'password123',
        newPassword: 'newSecretPass123',
      );
      expect(success, isNull);
      expect(restartedAuthProvider.currentUser?.password, 'newSecretPass123');

      // 5. Sign out
      await restartedAuthProvider.signOut();
      expect(restartedAuthProvider.isLoggedIn, isFalse);

      // 6. Simulate another app restart after explicit logout
      final loggedOutAuthService = AuthService();
      final loggedOutAuthProvider = AuthProvider(loggedOutAuthService);
      await loggedOutAuthProvider.initialize();

      // Must remain logged out after explicit signout
      expect(loggedOutAuthProvider.isLoggedIn, isFalse);
    });
  });
}
