import '../models/reminder_settings.dart';

/// Web: geplande push-notificaties niet beschikbaar.
/// Break-reminders werken in-app via dialogs tijdens gaming sessies.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  bool get isSupported => false;

  Future<void> init() async {}

  Future<void> scheduleReminders(ReminderSettings settings) async {}

  Future<void> showBreakReminder() async {}

  Future<void> cancelAll() async {}
}