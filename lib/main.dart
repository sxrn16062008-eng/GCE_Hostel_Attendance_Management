import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'state/auth_provider.dart';
import 'state/hostel_data_provider.dart';
import 'state/theme_provider.dart';
import 'services/firestore_service.dart';
import 'services/attendance_service.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

import 'services/connectivity_service.dart';
import 'state/network_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize notifications channels, timezone, and exact alarm permissions
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notification service initialization notice: $e');
  }

  runApp(const GCEBoysHostelApp());
}

class GCEBoysHostelApp extends StatelessWidget {
  const GCEBoysHostelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connectivityService = ConnectivityService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkProvider(connectivityService)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        ChangeNotifierProvider(
          create: (_) => HostelDataProvider(
            firestoreService: FirestoreService(),
            attendanceService: AttendanceService(),
          ),
        ),
      ],
      child: const AppRoot(),
    );
  }
}
