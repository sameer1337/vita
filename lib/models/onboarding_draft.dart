import 'package:flutter/material.dart' show TimeOfDay;

import 'onboarding_answers.dart';

/// A mutable, partially-filled set of onboarding answers used while the user
/// moves through the flow. All fields are nullable / empty until answered.
/// Nothing is persisted to the backend until the final step.
class OnboardingDraft {
  final String? fullName;
  final String? email;
  final DateTime? dob;
  final String? goal;
  final String? sex;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final String? activityLevel;
  final bool useImperialHeight;
  final bool useImperialWeight;
  final List<String> equipment;
  final int? daysPerWeek;
  final int? minutesPerSession;
  final List<String> limitations;
  final List<String> dietPrefs;
  final String? allergies;
  final String? mealsPerDay;
  final String? cookingFrequency;
  final TimeOfDay? workoutTime;
  final int stressLevel;
  final int sleepQuality;
  final int mood;

  /// Smoking answer: 'quit' (smokes, wants help), 'smokes' (smokes, not now),
  /// or 'no' (doesn't smoke). Null until answered.
  final String? smokingChoice;

  /// Typical cigarettes/day before quitting (taper baseline).
  final int cigarettesPerDay;

  const OnboardingDraft({
    this.fullName,
    this.email,
    this.dob,
    this.goal,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.activityLevel,
    this.useImperialHeight = false,
    this.useImperialWeight = false,
    this.equipment = const [],
    this.daysPerWeek,
    this.minutesPerSession,
    this.limitations = const [],
    this.dietPrefs = const [],
    this.allergies,
    this.mealsPerDay,
    this.cookingFrequency,
    this.workoutTime,
    this.stressLevel = 5,
    this.sleepQuality = 5,
    this.mood = 5,
    this.smokingChoice,
    this.cigarettesPerDay = 10,
  });

  OnboardingDraft copyWith({
    String? fullName,
    String? email,
    DateTime? dob,
    String? goal,
    String? sex,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    String? activityLevel,
    bool? useImperialHeight,
    bool? useImperialWeight,
    List<String>? equipment,
    int? daysPerWeek,
    int? minutesPerSession,
    List<String>? limitations,
    List<String>? dietPrefs,
    String? allergies,
    String? mealsPerDay,
    String? cookingFrequency,
    TimeOfDay? workoutTime,
    int? stressLevel,
    int? sleepQuality,
    int? mood,
    String? smokingChoice,
    int? cigarettesPerDay,
  }) {
    return OnboardingDraft(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      goal: goal ?? this.goal,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      useImperialHeight: useImperialHeight ?? this.useImperialHeight,
      useImperialWeight: useImperialWeight ?? this.useImperialWeight,
      equipment: equipment ?? this.equipment,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      minutesPerSession: minutesPerSession ?? this.minutesPerSession,
      limitations: limitations ?? this.limitations,
      dietPrefs: dietPrefs ?? this.dietPrefs,
      allergies: allergies ?? this.allergies,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      cookingFrequency: cookingFrequency ?? this.cookingFrequency,
      workoutTime: workoutTime ?? this.workoutTime,
      stressLevel: stressLevel ?? this.stressLevel,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      mood: mood ?? this.mood,
      smokingChoice: smokingChoice ?? this.smokingChoice,
      cigarettesPerDay: cigarettesPerDay ?? this.cigarettesPerDay,
    );
  }

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'dob': dob?.toIso8601String(),
        'goal': goal,
        'sex': sex,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'target_weight_kg': targetWeightKg,
        'activity_level': activityLevel,
        'use_imperial_height': useImperialHeight,
        'use_imperial_weight': useImperialWeight,
        'equipment': equipment,
        'days_per_week': daysPerWeek,
        'minutes_per_session': minutesPerSession,
        'limitations': limitations,
        'diet_prefs': dietPrefs,
        'allergies': allergies,
        'meals_per_day': mealsPerDay,
        'cooking_frequency': cookingFrequency,
        'workout_hour': workoutTime?.hour,
        'workout_minute': workoutTime?.minute,
        'stress_level': stressLevel,
        'sleep_quality': sleepQuality,
        'mood': mood,
        'smoking_choice': smokingChoice,
        'cigarettes_per_day': cigarettesPerDay,
      };

  factory OnboardingDraft.fromJson(Map<String, dynamic> j) {
    final wh = (j['workout_hour'] as num?)?.toInt();
    final wm = (j['workout_minute'] as num?)?.toInt();
    return OnboardingDraft(
      fullName: j['full_name'] as String?,
      email: j['email'] as String?,
      dob: DateTime.tryParse(j['dob'] as String? ?? ''),
      goal: j['goal'] as String?,
      sex: j['sex'] as String?,
      heightCm: (j['height_cm'] as num?)?.toDouble(),
      weightKg: (j['weight_kg'] as num?)?.toDouble(),
      targetWeightKg: (j['target_weight_kg'] as num?)?.toDouble(),
      activityLevel: j['activity_level'] as String?,
      useImperialHeight: j['use_imperial_height'] as bool? ?? false,
      useImperialWeight: j['use_imperial_weight'] as bool? ?? false,
      equipment:
          (j['equipment'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      daysPerWeek: (j['days_per_week'] as num?)?.toInt(),
      minutesPerSession: (j['minutes_per_session'] as num?)?.toInt(),
      limitations:
          (j['limitations'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      dietPrefs:
          (j['diet_prefs'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      allergies: j['allergies'] as String?,
      mealsPerDay: j['meals_per_day'] as String?,
      cookingFrequency: j['cooking_frequency'] as String?,
      workoutTime:
          (wh != null && wm != null) ? TimeOfDay(hour: wh, minute: wm) : null,
      stressLevel: (j['stress_level'] as num?)?.toInt() ?? 5,
      sleepQuality: (j['sleep_quality'] as num?)?.toInt() ?? 5,
      mood: (j['mood'] as num?)?.toInt() ?? 5,
      smokingChoice: j['smoking_choice'] as String?,
      cigarettesPerDay: (j['cigarettes_per_day'] as num?)?.toInt() ?? 10,
    );
  }

  /// Age in whole years derived from [dob].
  int? get age {
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob!.year;
    if (now.month < dob!.month ||
        (now.month == dob!.month && now.day < dob!.day)) {
      years--;
    }
    return years;
  }

  /// First name, for friendly greetings.
  String get firstName =>
      (fullName ?? '').trim().split(RegExp(r'\s+')).first;

  /// Whether the goal implies a target-weight question is relevant.
  bool get goalUsesTargetWeight =>
      goal == 'Lose weight' || goal == 'Build muscle';

  /// Convert the completed draft into the `generate-plan` API payload.
  /// Call only once all required steps are valid.
  OnboardingAnswers toAnswers() {
    return OnboardingAnswers(
      goal: goal!,
      sex: sex!,
      age: age!,
      heightCm: heightCm!,
      weightKg: weightKg!,
      targetWeightKg: goalUsesTargetWeight ? targetWeightKg : null,
      activityLevel: activityLevel!,
      equipment: equipment,
      daysPerWeek: daysPerWeek!,
      minutesPerSession: minutesPerSession!,
      limitations: limitations,
      dietPrefs: dietPrefs,
      allergies: allergies,
      mealsPerDay: mealsPerDay!,
      cookingFrequency: cookingFrequency!,
      stressLevel: stressLevel,
      sleepQuality: sleepQuality,
      mood: mood,
    );
  }
}
