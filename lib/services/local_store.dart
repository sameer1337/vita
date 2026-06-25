import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_data.dart';
import '../models/onboarding_draft.dart';
import '../models/plan.dart';
import '../models/reminder_settings.dart';
import '../models/smoking_profile.dart';

/// Local, offline persistence for day-to-day wellness data.
///
/// Until auth + Supabase sync lands (Phase D), everything the user logs day to
/// day — water, meals, completed workouts — lives here on the device.
class LocalStore {
  LocalStore._(this._prefs);

  final SharedPreferences _prefs;
  static LocalStore? _instance;

  static Future<LocalStore> instance() async {
    return _instance ??= LocalStore._(await SharedPreferences.getInstance());
  }

  /// Test-only: drop the cached singleton so a fresh SharedPreferences mock can
  /// be installed between tests.
  static void resetForTest() {
    _instance = null;
  }

  /// Synchronous access once [instance] has been awaited (e.g. in `main`).
  static LocalStore get cached {
    final i = _instance;
    if (i == null) {
      throw StateError('LocalStore.instance() must be awaited before use');
    }
    return i;
  }

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _dayPrefKey(String date) => 'vita.day.$date';

  DailyData loadDay(String date) {
    final raw = _prefs.getString(_dayPrefKey(date));
    if (raw == null) return DailyData.empty(date);
    try {
      return DailyData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return DailyData.empty(date);
    }
  }

  Future<void> saveDay(DailyData data) =>
      _prefs.setString(_dayPrefKey(data.date), jsonEncode(data.toJson()));

  /// Every stored day, for backup/sync. Cheap for a personal app's history.
  List<DailyData> allDays() {
    final out = <DailyData>[];
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith('vita.day.')) continue;
      final raw = _prefs.getString(key);
      if (raw == null) continue;
      try {
        out.add(DailyData.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {/* skip */}
    }
    return out;
  }

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  // ---- Onboarding result: plan + profile (so we don't re-onboard) ---------

  static const String _planKey = 'vita.plan';
  static const String _profileKey = 'vita.profile';

  Future<void> savePlan(WellnessPlan plan) =>
      _prefs.setString(_planKey, jsonEncode(plan.toJson()));

  WellnessPlan? loadPlan() {
    final raw = _prefs.getString(_planKey);
    if (raw == null) return null;
    try {
      return WellnessPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(OnboardingDraft draft) =>
      _prefs.setString(_profileKey, jsonEncode(draft.toJson()));

  OnboardingDraft? loadProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return OnboardingDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Clear plan + profile (e.g. a "start over" action). Day logs are kept.
  Future<void> clearOnboarding() async {
    await _prefs.remove(_planKey);
    await _prefs.remove(_profileKey);
  }

  static const String _smokingKey = 'vita.smoking';

  SmokingProfile loadSmokingProfile() {
    final raw = _prefs.getString(_smokingKey);
    if (raw == null) return const SmokingProfile();
    try {
      return SmokingProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const SmokingProfile();
    }
  }

  Future<void> saveSmokingProfile(SmokingProfile p) =>
      _prefs.setString(_smokingKey, jsonEncode(p.toJson()));

  static const String _remindersKey = 'vita.reminders';

  ReminderSettings loadReminderSettings() {
    final raw = _prefs.getString(_remindersKey);
    if (raw == null) return const ReminderSettings();
    try {
      return ReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ReminderSettings();
    }
  }

  Future<void> saveReminderSettings(ReminderSettings s) =>
      _prefs.setString(_remindersKey, jsonEncode(s.toJson()));

  /// Cigarettes logged per day across stored history (yyyy-MM-dd → count).
  Map<String, int> cigarettesByDate() {
    final out = <String, int>{};
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith('vita.day.')) continue;
      final raw = _prefs.getString(key);
      if (raw == null) continue;
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        final c = (j['cigarettes'] as num?)?.toInt() ?? 0;
        out[j['date'] as String] = c;
      } catch (_) {/* skip */}
    }
    return out;
  }

  /// Returns completed-workout dates as a sorted set of yyyy-MM-dd strings,
  /// derived by scanning stored days. Cheap for a personal app's history.
  List<String> completedWorkoutDates() {
    final out = <String>[];
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith('vita.day.')) continue;
      final raw = _prefs.getString(key);
      if (raw == null) continue;
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        if (j['workout_done'] == true) out.add(j['date'] as String);
      } catch (_) {/* skip */}
    }
    out.sort();
    return out;
  }
}
