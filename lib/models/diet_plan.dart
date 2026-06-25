/// A goal-based 7-day meal plan returned by the `meal-plan` Edge Function.
class WeeklyDietPlan {
  final String goalSummary;
  final int dailyCalories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final List<DietDay> days;
  final List<String> tips;
  final String disclaimer;

  /// When this plan was generated (so we can show "updated 2 days ago").
  final DateTime generatedAt;

  const WeeklyDietPlan({
    required this.goalSummary,
    required this.dailyCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.days,
    required this.tips,
    required this.disclaimer,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'goal_summary': goalSummary,
        'daily_calories': dailyCalories,
        'macros': {'protein_g': proteinG, 'carbs_g': carbsG, 'fat_g': fatG},
        'days': days.map((d) => d.toJson()).toList(),
        'tips': tips,
        'disclaimer': disclaimer,
        'generated_at': generatedAt.toIso8601String(),
      };

  factory WeeklyDietPlan.fromJson(Map<String, dynamic> j) {
    final macros = (j['macros'] as Map?)?.cast<String, dynamic>() ?? const {};
    return WeeklyDietPlan(
      goalSummary: j['goal_summary'] as String? ?? '',
      dailyCalories: (j['daily_calories'] as num?)?.toInt() ?? 0,
      proteinG: (macros['protein_g'] as num?)?.toInt() ?? 0,
      carbsG: (macros['carbs_g'] as num?)?.toInt() ?? 0,
      fatG: (macros['fat_g'] as num?)?.toInt() ?? 0,
      days: (j['days'] as List?)
              ?.map((e) => DietDay.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      tips: (j['tips'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      disclaimer: j['disclaimer'] as String? ?? '',
      generatedAt:
          DateTime.tryParse(j['generated_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}

class DietDay {
  final String day;
  final List<DietMeal> meals;
  final int totalCalories;

  const DietDay({
    required this.day,
    required this.meals,
    required this.totalCalories,
  });

  /// Computed total if the AI didn't supply one.
  int get calories =>
      totalCalories > 0 ? totalCalories : meals.fold(0, (s, m) => s + m.calories);

  Map<String, dynamic> toJson() => {
        'day': day,
        'meals': meals.map((m) => m.toJson()).toList(),
        'total_calories': totalCalories,
      };

  factory DietDay.fromJson(Map<String, dynamic> j) => DietDay(
        day: j['day'] as String? ?? '',
        meals: (j['meals'] as List?)
                ?.map((e) =>
                    DietMeal.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
        totalCalories: (j['total_calories'] as num?)?.toInt() ?? 0,
      );
}

class DietMeal {
  final String meal;
  final String items;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  const DietMeal({
    required this.meal,
    required this.items,
    required this.calories,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  Map<String, dynamic> toJson() => {
        'meal': meal,
        'items': items,
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
      };

  factory DietMeal.fromJson(Map<String, dynamic> j) => DietMeal(
        meal: j['meal'] as String? ?? '',
        items: j['items'] as String? ?? '',
        calories: (j['calories'] as num?)?.toInt() ?? 0,
        proteinG: (j['protein_g'] as num?)?.toInt() ?? 0,
        carbsG: (j['carbs_g'] as num?)?.toInt() ?? 0,
        fatG: (j['fat_g'] as num?)?.toInt() ?? 0,
      );
}
