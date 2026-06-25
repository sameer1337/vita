import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/onboarding_draft.dart';
import '../services/local_store.dart';

/// Holds the in-progress onboarding answers. Local state only — nothing is
/// written to Supabase until the user taps "Save My Plan" on the final step.
///
/// On launch it restores any previously-saved profile so returning users keep
/// their name, weight and other details across restarts.
class OnboardingNotifier extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() =>
      LocalStore.cached.loadProfile() ?? const OnboardingDraft();

  void setFullName(String v) => state = state.copyWith(fullName: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setDob(DateTime v) => state = state.copyWith(dob: v);
  void setGoal(String v) => state = state.copyWith(goal: v);
  void setSex(String v) => state = state.copyWith(sex: v);
  void setHeightCm(double? v) => state = state.copyWith(heightCm: v);
  void setWeightKg(double? v) => state = state.copyWith(weightKg: v);
  void setTargetWeightKg(double? v) =>
      state = state.copyWith(targetWeightKg: v);
  void setActivityLevel(String v) => state = state.copyWith(activityLevel: v);
  void setUseImperialHeight(bool v) =>
      state = state.copyWith(useImperialHeight: v);
  void setUseImperialWeight(bool v) =>
      state = state.copyWith(useImperialWeight: v);
  void setDaysPerWeek(int v) => state = state.copyWith(daysPerWeek: v);
  void setMinutesPerSession(int v) =>
      state = state.copyWith(minutesPerSession: v);
  void setAllergies(String v) => state = state.copyWith(allergies: v);
  void setMealsPerDay(String v) => state = state.copyWith(mealsPerDay: v);
  void setCookingFrequency(String v) =>
      state = state.copyWith(cookingFrequency: v);
  void setWorkoutTime(TimeOfDay v) => state = state.copyWith(workoutTime: v);
  void setStressLevel(int v) => state = state.copyWith(stressLevel: v);
  void setSleepQuality(int v) => state = state.copyWith(sleepQuality: v);
  void setMood(int v) => state = state.copyWith(mood: v);
  void setSmokingChoice(String v) => state = state.copyWith(smokingChoice: v);
  void setCigarettesPerDay(int v) =>
      state = state.copyWith(cigarettesPerDay: v.clamp(1, 60));

  /// Toggle membership of [value] in a multi-select list.
  void toggleEquipment(String value) =>
      state = state.copyWith(equipment: _toggle(state.equipment, value));
  void toggleLimitation(String value) =>
      state = state.copyWith(limitations: _toggle(state.limitations, value));
  void toggleDietPref(String value) =>
      state = state.copyWith(dietPrefs: _toggle(state.dietPrefs, value));

  List<String> _toggle(List<String> list, String value) {
    final next = [...list];
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    return next;
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingDraft>(
  OnboardingNotifier.new,
);
