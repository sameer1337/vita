import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder_settings.dart';
import '../services/local_store.dart';
import '../services/notification_service.dart';

/// Holds the user's reminder preferences and keeps the scheduled local
/// notifications in sync whenever they change.
class ReminderNotifier extends Notifier<ReminderSettings> {
  late final LocalStore _store;

  @override
  ReminderSettings build() {
    _store = LocalStore.cached;
    return _store.loadReminderSettings();
  }

  /// Persist [next], request permission if anything is enabled, then reschedule.
  Future<void> update(ReminderSettings next) async {
    state = next;
    await _store.saveReminderSettings(next);
    await apply();
  }

  /// Re-apply the current settings to the OS scheduler. Safe to call on launch.
  Future<void> apply() async {
    final n = NotificationService.instance;
    final s = state;

    if (s.workoutEnabled || s.waterEnabled || s.smokingEnabled) {
      await n.requestPermission();
    }

    if (s.workoutEnabled) {
      await n.scheduleWorkout(s.workoutHour, s.workoutMinute);
    } else {
      await n.cancelWorkout();
    }

    if (s.waterEnabled) {
      await n.scheduleWater(s.waterTimesPerDay);
    } else {
      await n.cancelWater();
    }

    if (s.smokingEnabled) {
      await n.scheduleSmoking(s.smokingHour, s.smokingMinute);
    } else {
      await n.cancelSmoking();
    }
  }
}

final reminderProvider =
    NotifierProvider<ReminderNotifier, ReminderSettings>(ReminderNotifier.new);
