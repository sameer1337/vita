import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around `flutter_local_notifications` for Vita's daily reminders
/// (workout time, hydration, quit-smoking nudges).
///
/// All methods are no-ops on web — the app runs in Chrome during development and
/// the plugin has no web implementation. On Android the reminders are scheduled
/// as repeating daily local notifications via [tz.TZDateTime] + `zonedSchedule`.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // Stable notification ids so re-scheduling replaces rather than duplicates.
  static const int workoutId = 100;
  static const int smokingId = 300;
  static const int _waterBase = 200; // 200..219

  /// Channel used for all Vita reminders.
  static const AndroidNotificationDetails _android = AndroidNotificationDetails(
    'vita_reminders',
    'Vita reminders',
    channelDescription: 'Workout, hydration and quit-smoking reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _details =
      NotificationDetails(android: _android);

  /// Initialise the plugin and the timezone database. Call once from `main`.
  Future<void> init() async {
    if (kIsWeb || _ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to UTC if the device timezone can't be resolved.
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  /// Ask for notification permission (Android 13+ / iOS). Returns true if
  /// granted (or not required on this OS).
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, sound: true);
      return granted ?? true;
    }
    return true;
  }

  /// Schedule a notification that repeats every day at [hour]:[minute].
  Future<void> _scheduleDaily(
    int id,
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    if (kIsWeb || !_ready) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOf(hour, minute),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancel(int id) async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancelAll();
  }

  // ---- High-level reminder helpers ---------------------------------------

  Future<void> scheduleWorkout(int hour, int minute) => _scheduleDaily(
        workoutId,
        hour,
        minute,
        'Time to move 💪',
        "Your workout is scheduled now. Let's get it done!",
      );

  Future<void> cancelWorkout() => cancel(workoutId);

  Future<void> scheduleSmoking(int hour, int minute) => _scheduleDaily(
        smokingId,
        hour,
        minute,
        'Quit-smoking check-in 🚭',
        'How are you doing today? Log your count and keep stretching the gap.',
      );

  Future<void> cancelSmoking() => cancel(smokingId);

  /// Spread [count] hydration reminders evenly across the waking day
  /// (09:00–21:00) and schedule them. Cancels any beyond [count] first.
  Future<void> scheduleWater(int count) async {
    for (var i = 0; i < 20; i++) {
      await cancel(_waterBase + i);
    }
    final n = count.clamp(1, 12);
    const startMin = 9 * 60;
    const endMin = 21 * 60;
    final step = (endMin - startMin) ~/ n;
    for (var i = 0; i < n; i++) {
      final mins = startMin + step * i;
      await _scheduleDaily(
        _waterBase + i,
        mins ~/ 60,
        mins % 60,
        'Hydrate 💧',
        'Time for a glass of water. Small sips add up!',
      );
    }
  }

  Future<void> cancelWater() async {
    for (var i = 0; i < 20; i++) {
      await cancel(_waterBase + i);
    }
  }
}
