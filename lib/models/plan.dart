/// The AI-generated wellness plan returned by the `generate-plan` Edge Function.
class WellnessPlan {
  final int calorieTarget;
  final Macros macros;
  final List<WorkoutDay> workoutPlan;
  final List<SampleMeal> sampleMeals;
  final String mindCheckinPrompt;
  final String weeklyFocusTip;
  final bool referToProfessional;
  final String disclaimer;

  const WellnessPlan({
    required this.calorieTarget,
    required this.macros,
    required this.workoutPlan,
    required this.sampleMeals,
    required this.mindCheckinPrompt,
    required this.weeklyFocusTip,
    required this.referToProfessional,
    required this.disclaimer,
  });

  Map<String, dynamic> toJson() => {
        'calorie_target': calorieTarget,
        'macros': macros.toJson(),
        'workout_plan': workoutPlan.map((d) => d.toJson()).toList(),
        'sample_meals': sampleMeals.map((m) => m.toJson()).toList(),
        'mind_checkin_prompt': mindCheckinPrompt,
        'weekly_focus_tip': weeklyFocusTip,
        'refer_to_professional': referToProfessional,
        'disclaimer': disclaimer,
      };

  factory WellnessPlan.fromJson(Map<String, dynamic> json) {
    return WellnessPlan(
      calorieTarget: (json['calorie_target'] as num?)?.toInt() ?? 0,
      macros: Macros.fromJson(
        (json['macros'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      workoutPlan: (json['workout_plan'] as List?)
              ?.map((e) =>
                  WorkoutDay.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      sampleMeals: (json['sample_meals'] as List?)
              ?.map((e) =>
                  SampleMeal.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      mindCheckinPrompt: json['mind_checkin_prompt'] as String? ?? '',
      weeklyFocusTip: json['weekly_focus_tip'] as String? ?? '',
      referToProfessional: json['refer_to_professional'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

class Macros {
  final num proteinG;
  final num carbsG;
  final num fatG;

  const Macros({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  Map<String, dynamic> toJson() =>
      {'protein_g': proteinG, 'carbs_g': carbsG, 'fat_g': fatG};

  factory Macros.fromJson(Map<String, dynamic> json) => Macros(
        proteinG: json['protein_g'] as num? ?? 0,
        carbsG: json['carbs_g'] as num? ?? 0,
        fatG: json['fat_g'] as num? ?? 0,
      );
}

class WorkoutDay {
  final String day;
  final String focus;
  final List<Exercise> exercises;

  const WorkoutDay({
    required this.day,
    required this.focus,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'focus': focus,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => WorkoutDay(
        day: json['day'] as String? ?? '',
        focus: json['focus'] as String? ?? '',
        exercises: (json['exercises'] as List?)
                ?.map((e) =>
                    Exercise.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
      );
}

class Exercise {
  final String name;
  final int sets;
  final String reps;
  final int restSeconds;

  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'rest_seconds': restSeconds,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        name: json['name'] as String? ?? '',
        sets: (json['sets'] as num?)?.toInt() ?? 0,
        reps: json['reps']?.toString() ?? '',
        restSeconds: (json['rest_seconds'] as num?)?.toInt() ?? 0,
      );
}

class SampleMeal {
  final String meal;
  final String items;
  final int calories;

  const SampleMeal({
    required this.meal,
    required this.items,
    required this.calories,
  });

  Map<String, dynamic> toJson() =>
      {'meal': meal, 'items': items, 'calories': calories};

  factory SampleMeal.fromJson(Map<String, dynamic> json) => SampleMeal(
        meal: json['meal'] as String? ?? '',
        items: json['items'] as String? ?? '',
        calories: (json['calories'] as num?)?.toInt() ?? 0,
      );
}
