import '../models/reminder_settings.dart';

/// Stub — overridden door platform-specifieke implementatie.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  Future<void> init() async {}
  Future<void> scheduleReminders(ReminderSettings settings) async {}
  Future<void> showBreakReminder() async {}
  Future<void> cancelAll() async {}
  bool get isSupported => false;
}