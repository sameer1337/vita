import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_data.dart';
import '../services/local_store.dart';

/// Today's wellness data (water, meals, workout completion), persisted to the
/// device via [LocalStore]. Read with `ref.watch(dailyProvider)`.
class DailyNotifier extends Notifier<DailyData> {
  late final LocalStore _store;

  @override
  DailyData build() {
    _store = LocalStore.cached;
    return _store.loadDay(LocalStore.dateKey(DateTime.now()));
  }

  void _persist(DailyData next) {
    state = next;
    _store.saveDay(next);
  }

  void addWater(int ml) =>
      _persist(state.copyWith(waterMl: (state.waterMl + ml).clamp(0, 100000)));

  void resetWater() => _persist(state.copyWith(waterMl: 0));

  void logMeal(FoodEntry entry) =>
      _persist(state.copyWith(meals: [...state.meals, entry]));

  void removeMeal(int index) {
    if (index < 0 || index >= state.meals.length) return;
    final next = [...state.meals]..removeAt(index);
    _persist(state.copyWith(meals: next));
  }

  void markWorkoutDone() => _persist(state.copyWith(workoutDone: true));

  void logCigarette() =>
      _persist(state.copyWith(cigarettes: state.cigarettes + 1));

  void removeCigarette() => _persist(
      state.copyWith(cigarettes: (state.cigarettes - 1).clamp(0, 100000)));

  void setMoodCheckin(int mood) =>
      _persist(state.copyWith(moodCheckin: mood));

  /// Log last night's sleep: [hours] and a 1–5 [quality] rating.
  void logSleep(double hours, int quality) => _persist(
        state.copyWith(
          sleepHours: hours.clamp(0, 24),
          sleepQuality: quality.clamp(0, 5),
        ),
      );

  /// Completed-workout dates across all history (yyyy-MM-dd), sorted.
  List<String> completedDates() => _store.completedWorkoutDates();

  /// Consecutive-day streak ending today (or yesterday, if today isn't done
  /// yet — so the streak doesn't visually break until a day is actually missed).
  int currentStreak() {
    final done = completedDates().toSet();
    var streak = 0;
    var cursor = DateTime.now();
    // Allow today to be pending: start counting from today if done, else
    // from yesterday.
    if (!done.contains(LocalStore.dateKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (done.contains(LocalStore.dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

final dailyProvider =
    NotifierProvider<DailyNotifier, DailyData>(DailyNotifier.new);
