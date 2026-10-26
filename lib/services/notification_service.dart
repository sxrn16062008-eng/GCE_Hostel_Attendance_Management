import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/reminder_schedule_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FirebaseFirestore? _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int dailyReminderNotificationId = 1001;
  static const String _schedulePrefKey = 'attendance_reminder_schedule_cache';
  static const String _lastFiredDateKey = 'last_fired_daily_reminder_date';

  NotificationService._init({FirebaseFirestore? firestore})
      : _firestore = firestore ?? _safeFirestore();

  static FirebaseFirestore? _safeFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Initialize local notification channels, permissions, and timezone data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone database for scheduled recurring alerts
      tz.initializeTimeZones();
      try {
        // Set local timezone to Indian Standard Time (Asia/Kolkata)
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (e) {
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Calcutta'));
        } catch (_) {}
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      // Request notification permissions for Android 13+ & create channels with MAX priority
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        try {
          await androidPlugin.requestExactAlarmsPermission();
        } catch (_) {}

        // Explicitly create notification channels with user's ringtone and max priority
        const scheduleChannel = AndroidNotificationChannel(
          'hostel_attendance_daily_schedule_v4',
          'Scheduled Attendance Reminders',
          description:
              'Daily scheduled roll call reminder set by the Chief Warden',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('ringtone'),
          enableVibration: true,
          showBadge: true,
          enableLights: true,
        );
        await androidPlugin.createNotificationChannel(scheduleChannel);

        const reminderChannel = AndroidNotificationChannel(
          'hostel_attendance_reminders_v4',
          'Attendance Reminders',
          description:
              'Hostel attendance reminder notifications for representatives',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('ringtone'),
          enableVibration: true,
          showBadge: true,
          enableLights: true,
        );
        await androidPlugin.createNotificationChannel(reminderChannel);
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully with timezone: ${tz.local.name}');
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  /// Trigger an immediate local push notification on the device
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await initialize();

      const androidDetails = AndroidNotificationDetails(
        'hostel_attendance_reminders_v4',
        'Attendance Reminders',
        channelDescription:
            'Daily hostel attendance reminder notifications for representatives',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone'),
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error displaying local notification: $e');
    }
  }

  /// Direct test trigger for verifying sound, vibration, and banner on device immediately
  Future<void> testNotificationNow({
    String title = '🔔 Test Attendance Reminder',
    String body = 'Sound, vibration, and banner alerts are active and working!',
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      payload: 'test_notification_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Schedule a daily recurring local notification at warden-configured time
  Future<void> scheduleDailyReminder(ReminderScheduleModel schedule) async {
    try {
      await initialize();

      // Cancel previous scheduled notification
      await _localNotifications.cancel(id: dailyReminderNotificationId);

      if (!schedule.isEnabled) {
        debugPrint('Daily attendance reminder schedule is disabled.');
        return;
      }

      // Calculate next scheduled time in device local time
      final now = DateTime.now();
      var targetDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        schedule.scheduledHour,
        schedule.scheduledMinute,
        0,
      );

      // If scheduled time has already passed today, set for tomorrow
      if (targetDateTime.isBefore(now)) {
        targetDateTime = targetDateTime.add(const Duration(days: 1));
      }

      final scheduledDate = tz.TZDateTime.from(targetDateTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'hostel_attendance_daily_schedule_v4',
        'Scheduled Attendance Reminders',
        channelDescription:
            'Daily scheduled roll call reminder set by the Chief Warden',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone'),
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Use alarmClock mode first (highest priority, wakes device from doze), fall back to exactAllowWhileIdle
      try {
        await _localNotifications.zonedSchedule(
          id: dailyReminderNotificationId,
          title: schedule.title,
          body: schedule.message,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'scheduled_daily_attendance_reminder',
        );
        debugPrint(
            'Daily notification scheduled in alarmClock mode at ${schedule.formattedScheduledTime} ($scheduledDate)');
      } catch (alarmClockError) {
        debugPrint('alarmClock mode failed, falling back to exactAllowWhileIdle: $alarmClockError');
        try {
          await _localNotifications.zonedSchedule(
            id: dailyReminderNotificationId,
            title: schedule.title,
            body: schedule.message,
            scheduledDate: scheduledDate,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'scheduled_daily_attendance_reminder',
          );
        } catch (exactError) {
          debugPrint('Exact alarm fallback to inexact schedule: $exactError');
          await _localNotifications.zonedSchedule(
            id: dailyReminderNotificationId,
            title: schedule.title,
            body: schedule.message,
            scheduledDate: scheduledDate,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'scheduled_daily_attendance_reminder',
          );
        }
      }
    } catch (e) {
      debugPrint('Error scheduling daily local notification: $e');
    }
  }

  /// Checks if daily reminder time has been reached and triggers notification if not yet fired
  Future<bool> checkAndTriggerDailyReminder(
      ReminderScheduleModel schedule) async {
    if (!schedule.isEnabled) return false;

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final specificKey = '${_lastFiredDateKey}_${todayStr}_${schedule.scheduledHour}_${schedule.scheduledMinute}';

    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyFired = prefs.getBool(specificKey) ?? false;

      // If already fired for this specific configured time today, skip
      if (alreadyFired) {
        return false;
      }

      final scheduledTime =
          DateTime(now.year, now.month, now.day, schedule.scheduledHour, schedule.scheduledMinute);

      // Check if current time is within or past scheduled time today (within 15 minutes window)
      final diffInSeconds = now.difference(scheduledTime).inSeconds;
      if (diffInSeconds >= 0 && diffInSeconds <= 900) {
        await showLocalNotification(
          title: schedule.title,
          body: schedule.message,
          payload: 'daily_attendance_reminder_fired',
        );
        await prefs.setBool(specificKey, true);
        debugPrint('Daily scheduled reminder triggered in-app for $specificKey');
        return true;
      }
    } catch (e) {
      debugPrint('Error in checkAndTriggerDailyReminder: $e');
    }
    return false;
  }

  /// Cancel scheduled daily reminders
  Future<void> cancelDailyReminder() async {
    try {
      await initialize();
      await _localNotifications.cancel(id: dailyReminderNotificationId);
    } catch (e) {
      debugPrint('Error cancelling scheduled notification: $e');
    }
  }

  /// Save reminder schedule to Firestore and local cache, then reschedule on device
  Future<void> saveReminderSchedule(ReminderScheduleModel schedule) async {
    // 1. Cache locally
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapData = schedule.toMap();
      mapData['updatedAt'] = schedule.updatedAt.toIso8601String();
      await prefs.setString(_schedulePrefKey, jsonEncode(mapData));
    } catch (e) {
      debugPrint('Error caching reminder schedule locally: $e');
    }

    // 2. Save to Firestore
    if (_firestore != null) {
      try {
        await _firestore!
            .collection('settings')
            .doc('attendance_schedule')
            .set(schedule.toMap());
      } catch (e) {
        debugPrint('Firestore offline, schedule saved locally: $e');
      }
    }

    // 3. Reschedule local notification
    await scheduleDailyReminder(schedule);
  }

  /// Fetch reminder schedule from Firestore or local cache
  Future<ReminderScheduleModel> fetchReminderSchedule() async {
    // Try Firestore first
    if (_firestore != null) {
      try {
        final doc = await _firestore!
            .collection('settings')
            .doc('attendance_schedule')
            .get();
        if (doc.exists && doc.data() != null) {
          final schedule = ReminderScheduleModel.fromSnapshot(doc);
          try {
            final prefs = await SharedPreferences.getInstance();
            final mapData = schedule.toMap();
            mapData['updatedAt'] = schedule.updatedAt.toIso8601String();
            await prefs.setString(_schedulePrefKey, jsonEncode(mapData));
          } catch (_) {}
          return schedule;
        }
      } catch (e) {
        debugPrint('Error fetching reminder schedule from Firestore: $e');
      }
    }

    // Try Local Cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_schedulePrefKey);
      if (jsonStr != null) {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        return ReminderScheduleModel.fromMap(
            map, map['id'] ?? 'default_schedule');
      }
    } catch (e) {
      debugPrint('Error reading cached schedule: $e');
    }

    return ReminderScheduleModel.defaultSchedule();
  }

  /// Realtime stream for reminder schedule
  Stream<ReminderScheduleModel> reminderScheduleStream() {
    if (_firestore != null) {
      return _firestore!
          .collection('settings')
          .doc('attendance_schedule')
          .snapshots()
          .map((doc) {
        if (doc.exists && doc.data() != null) {
          return ReminderScheduleModel.fromSnapshot(doc);
        }
        return ReminderScheduleModel.defaultSchedule();
      });
    }
    return Stream.value(ReminderScheduleModel.defaultSchedule());
  }

  /// Realtime stream for notifications list
  Stream<List<AppNotificationModel>> notificationsStream() {
    if (_firestore != null) {
      return _firestore!
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AppNotificationModel.fromSnapshot(doc))
            .toList();
      });
    }
    return Stream.value([]);
  }

  /// Sends attendance reminder to Firestore and triggers local notification
  Future<AppNotificationModel> sendAttendanceReminder({
    required String title,
    required String message,
    String senderName = 'Chief Warden',
    String targetRole = 'representative',
  }) async {
    final newNotification = AppNotificationModel(
      id: const Uuid().v4(),
      title: title,
      message: message,
      senderName: senderName,
      targetRole: targetRole,
      type: 'attendance_reminder',
      createdAt: DateTime.now(),
      isRead: false,
    );

    // 1. Save to Cloud Firestore
    if (_firestore != null) {
      try {
        await _firestore!
            .collection('notifications')
            .doc(newNotification.id)
            .set(newNotification.toMap());
      } catch (e) {
        debugPrint('Firestore offline, saving notification locally: $e');
      }
    }

    // 2. Trigger instant local push notification on device
    await showLocalNotification(
      title: title,
      body: message,
      payload: newNotification.id,
    );

    return newNotification;
  }

  /// Sends mess complaint alert to Warden in Firestore and triggers instant local notification
  Future<AppNotificationModel> sendMessComplaintNotification({
    required String title,
    required String message,
    required String senderName,
  }) async {
    final newNotification = AppNotificationModel(
      id: const Uuid().v4(),
      title: title,
      message: message,
      senderName: senderName,
      targetRole: 'admin',
      type: 'mess_complaint',
      createdAt: DateTime.now(),
      isRead: false,
    );

    // 1. Save to Cloud Firestore
    if (_firestore != null) {
      try {
        await _firestore!
            .collection('notifications')
            .doc(newNotification.id)
            .set(newNotification.toMap());
      } catch (e) {
        debugPrint('Firestore offline, saving notification locally: $e');
      }
    }

    // 2. Trigger instant local push notification on device
    await showLocalNotification(
      title: title,
      body: message,
      payload: 'mess_complaint_${newNotification.id}',
    );

    return newNotification;
  }

  /// Fetches recent notifications from Firestore
  Future<List<AppNotificationModel>> fetchNotifications(
      {String role = 'representative'}) async {
    if (_firestore != null) {
      try {
        final snap = await _firestore!
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(30)
            .get();

        return snap.docs
            .map((d) => AppNotificationModel.fromSnapshot(d))
            .toList();
      } catch (e) {
        debugPrint('Error fetching notifications from Firestore: $e');
      }
    }

    // Default sample reminder if empty or offline
    return [
      AppNotificationModel(
        id: 'sample_rem_1',
        title: 'Daily Attendance Reminder',
        message:
            'Please take attendance for all hostel students in your assigned rooms before 9:00 PM.',
        senderName: 'Chief Warden',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
      ),
    ];
  }

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    if (_firestore != null) {
      try {
        await _firestore!
            .collection('notifications')
            .doc(id)
            .update({'isRead': true});
      } catch (_) {}
    }
  }
}
