import 'package:flutter_test/flutter_test.dart';
import 'package:gce_boys_hostel/models/reminder_schedule_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReminderScheduleModel Tests', () {
    test('Default schedule initialization and formatting', () {
      final schedule = ReminderScheduleModel.defaultSchedule();

      expect(schedule.id, 'default_schedule');
      expect(schedule.shiftName, 'Night Roll Call');
      expect(schedule.scheduledHour, 20);
      expect(schedule.scheduledMinute, 30);
      expect(schedule.formattedScheduledTime, '08:30 PM');
      expect(schedule.formattedShiftWindow, '08:00 PM - 09:30 PM');
      expect(schedule.isEnabled, isTrue);
    });

    test('Custom timing serialization to/from map', () {
      final custom = ReminderScheduleModel(
        id: 'shift_evening_1',
        shiftName: 'Evening Roll Call',
        scheduledHour: 19,
        scheduledMinute: 45,
        shiftStartHour: 19,
        shiftStartMinute: 15,
        shiftEndHour: 20,
        shiftEndMinute: 30,
        title: 'Evening Attendance Alert',
        message: 'Please take evening attendance promptly.',
        isEnabled: true,
        updatedBy: 'Chief Warden',
        updatedAt: DateTime(2026, 9, 13, 16, 0),
      );

      expect(custom.formattedScheduledTime, '07:45 PM');
      expect(custom.formattedShiftWindow, '07:15 PM - 08:30 PM');

      final map = custom.toMap();
      final reconstructed = ReminderScheduleModel.fromMap(map, custom.id);

      expect(reconstructed.id, 'shift_evening_1');
      expect(reconstructed.shiftName, 'Evening Roll Call');
      expect(reconstructed.scheduledHour, 19);
      expect(reconstructed.scheduledMinute, 45);
      expect(reconstructed.title, 'Evening Attendance Alert');
      expect(reconstructed.message, 'Please take evening attendance promptly.');
      expect(reconstructed.isEnabled, isTrue);
    });

    test('CopyWith method modifies fields correctly', () {
      final base = ReminderScheduleModel.defaultSchedule();
      final updated = base.copyWith(
        scheduledHour: 21,
        scheduledMinute: 15,
        isEnabled: false,
        shiftName: 'Late Night Curfew',
      );

      expect(updated.scheduledHour, 21);
      expect(updated.scheduledMinute, 15);
      expect(updated.formattedScheduledTime, '09:15 PM');
      expect(updated.isEnabled, isFalse);
      expect(updated.shiftName, 'Late Night Curfew');
    });
  });
}
