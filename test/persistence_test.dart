import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vita/models/daily_data.dart';
import 'package:vita/models/onboarding_draft.dart';
import 'package:vita/models/plan.dart';
import 'package:vita/models/reminder_settings.dart';
import 'package:vita/services/local_store.dart';

WellnessPlan _plan() => WellnessPlan.fromJson(const {
      'calorie_target': 2100,
      'macros': {'protein_g': 150, 'carbs_g': 200, 'fat_g': 70},
      'workout_plan': [
        {
          'day': 'Mon',
          'focus': 'Full body',
          'exercises': [
            {'name': 'Squat', 'sets': 3, 'reps': '10', 'rest_seconds': 60},
          ],
        },
      ],
      'sample_meals': [
        {'meal': 'Lunch', 'items': 'Rice + chicken', 'calories': 600},
      ],
      'mind_checkin_prompt': 'How do you feel?',
      'weekly_focus_tip': 'Consistency.',
      'refer_to_professional': false,
      'disclaimer': 'Not medical advice.',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LocalStore.resetForTest();
    await LocalStore.instance();
  });

  test('plan survives a save/load round trip', () async {
    final store = LocalStore.cached;
    await store.savePlan(_plan());
    final loaded = store.loadPlan();
    expect(loaded, isNotNull);
    expect(loaded!.calorieTarget, 2100);
    expect(loaded.macros.proteinG, 150);
    expect(loaded.workoutPlan.single.exercises.single.name, 'Squat');
  });

  test('profile (incl. workout time + smoking) round trips', () async {
    final store = LocalStore.cached;
    const draft = OnboardingDraft(
      fullName: 'Alex Lee',
      weightKg: 72,
      workoutTime: TimeOfDay(hour: 6, minute: 30),
      smokingChoice: 'quit',
      cigarettesPerDay: 12,
    );
    await store.saveProfile(draft);
    final loaded = store.loadProfile();
    expect(loaded, isNotNull);
    expect(loaded!.firstName, 'Alex');
    expect(loaded.weightKg, 72);
    expect(loaded.workoutTime, const TimeOfDay(hour: 6, minute: 30));
    expect(loaded.smokingChoice, 'quit');
    expect(loaded.cigarettesPerDay, 12);
  });

  test('reminder settings round trip', () async {
    final store = LocalStore.cached;
    const s = ReminderSettings(
      workoutEnabled: true,
      workoutHour: 18,
      waterEnabled: true,
      waterTimesPerDay: 8,
      smokingEnabled: true,
    );
    await store.saveReminderSettings(s);
    final loaded = store.loadReminderSettings();
    expect(loaded.workoutEnabled, true);
    expect(loaded.workoutHour, 18);
    expect(loaded.waterTimesPerDay, 8);
    expect(loaded.smokingEnabled, true);
  });

  test('cigarettesByDate aggregates stored days', () async {
    final store = LocalStore.cached;
    await store.saveDay(const DailyData(date: '2026-06-24', cigarettes: 5));
    await store.saveDay(const DailyData(date: '2026-06-25', cigarettes: 3));
    final byDate = store.cigarettesByDate();
    expect(byDate['2026-06-24'], 5);
    expect(byDate['2026-06-25'], 3);
  });
}
