import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/daily_data.dart';
import '../models/onboarding_draft.dart';
import '../models/plan.dart';
import '../models/reminder_settings.dart';
import '../models/smoking_profile.dart';
import 'local_store.dart';

/// Two-way (explicit) backup/restore of all locally-stored Vita data to
/// Supabase, scoped to the signed-in user via row-level security.
///
/// Two tables back this (see the `phase_d_sync` migration):
///   * `user_state` — one row per user: plan, profile, smoking, reminders.
///   * `daily_logs` — one row per (user, date): water, meals, workout, etc.
///
/// Sync is deliberately last-write-wins and user-initiated (Back up / Restore)
/// rather than a silent background merge, which keeps behaviour predictable.
class SyncService {
  SyncService([SupabaseClient? client, LocalStore? store])
      : _injectedClient = client,
        _injectedStore = store;

  final SupabaseClient? _injectedClient;
  final LocalStore? _injectedStore;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;
  LocalStore get _store => _injectedStore ?? LocalStore.cached;

  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const SyncException('You need to be signed in to sync.');
    }
    return user.id;
  }

  /// Push everything on this device up to the cloud, overwriting the server.
  Future<void> backup() async {
    final uid = _uid;
    try {
      await _client.from('user_state').upsert({
        'user_id': uid,
        'plan': _store.loadPlan()?.toJson(),
        'profile': _store.loadProfile()?.toJson(),
        'smoking': _store.loadSmokingProfile().toJson(),
        'reminders': _store.loadReminderSettings().toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      final rows = _store
          .allDays()
          .map((d) => {'user_id': uid, 'date': d.date, 'data': d.toJson()})
          .toList();
      if (rows.isNotEmpty) {
        await _client.from('daily_logs').upsert(rows);
      }
    } on PostgrestException catch (e) {
      throw SyncException(e.message);
    }
  }

  /// Pull everything from the cloud down to this device, overwriting local
  /// state. Returns the restored plan (if any) so the caller can route home.
  Future<WellnessPlan?> restore() async {
    final uid = _uid;
    WellnessPlan? plan;
    try {
      final state = await _client
          .from('user_state')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (state != null) {
        final planJson = state['plan'];
        if (planJson is Map) {
          plan = WellnessPlan.fromJson(planJson.cast<String, dynamic>());
          await _store.savePlan(plan);
        }
        final profileJson = state['profile'];
        if (profileJson is Map) {
          await _store
              .saveProfile(OnboardingDraft.fromJson(profileJson.cast()));
        }
        final smokingJson = state['smoking'];
        if (smokingJson is Map) {
          await _store
              .saveSmokingProfile(SmokingProfile.fromJson(smokingJson.cast()));
        }
        final remindersJson = state['reminders'];
        if (remindersJson is Map) {
          await _store.saveReminderSettings(
              ReminderSettings.fromJson(remindersJson.cast()));
        }
      }

      final days = await _client.from('daily_logs').select().eq('user_id', uid);
      for (final row in days as List) {
        final data = (row as Map)['data'];
        if (data is Map) {
          await _store.saveDay(DailyData.fromJson(data.cast<String, dynamic>()));
        }
      }
    } on PostgrestException catch (e) {
      throw SyncException(e.message);
    }
    return plan;
  }
}

class SyncException implements Exception {
  const SyncException(this.message);
  final String message;
  @override
  String toString() => message;
}
