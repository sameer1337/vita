/// One logged meal (from photo analysis or text lookup).
class FoodEntry {
  const FoodEntry({
    required this.label,
    required this.calories,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.photoPath,
    required this.loggedAt,
  });

  final String label;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  /// Local file path or remote URL of the meal photo, if any.
  final String? photoPath;
  final DateTime loggedAt;

  Map<String, dynamic> toJson() => {
        'label': label,
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'photo_path': photoPath,
        'logged_at': loggedAt.toIso8601String(),
      };

  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
        label: j['label'] as String? ?? 'Meal',
        calories: (j['calories'] as num?)?.toInt() ?? 0,
        proteinG: (j['protein_g'] as num?)?.toInt() ?? 0,
        carbsG: (j['carbs_g'] as num?)?.toInt() ?? 0,
        fatG: (j['fat_g'] as num?)?.toInt() ?? 0,
        photoPath: j['photo_path'] as String?,
        loggedAt: DateTime.tryParse(j['logged_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// The wellness numbers Vita tracks for a single day.
class DailyData {
  const DailyData({
    required this.date,
    this.waterMl = 0,
    this.workoutDone = false,
    this.moodCheckin,
    this.meals = const [],
    this.cigarettes = 0,
  });

  /// yyyy-MM-dd.
  final String date;
  final int waterMl;
  final bool workoutDone;

  /// 1–5 morning check-in, null if not done today.
  final int? moodCheckin;
  final List<FoodEntry> meals;

  /// Cigarettes logged today (quit-smoking module).
  final int cigarettes;

  int get caloriesLogged => meals.fold(0, (s, m) => s + m.calories);
  int get proteinG => meals.fold(0, (s, m) => s + m.proteinG);
  int get carbsG => meals.fold(0, (s, m) => s + m.carbsG);
  int get fatG => meals.fold(0, (s, m) => s + m.fatG);

  DailyData copyWith({
    int? waterMl,
    bool? workoutDone,
    int? moodCheckin,
    List<FoodEntry>? meals,
    int? cigarettes,
  }) =>
      DailyData(
        date: date,
        waterMl: waterMl ?? this.waterMl,
        workoutDone: workoutDone ?? this.workoutDone,
        moodCheckin: moodCheckin ?? this.moodCheckin,
        meals: meals ?? this.meals,
        cigarettes: cigarettes ?? this.cigarettes,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'water_ml': waterMl,
        'workout_done': workoutDone,
        'mood_checkin': moodCheckin,
        'meals': meals.map((m) => m.toJson()).toList(),
        'cigarettes': cigarettes,
      };

  factory DailyData.fromJson(Map<String, dynamic> j) => DailyData(
        date: j['date'] as String? ?? '',
        waterMl: (j['water_ml'] as num?)?.toInt() ?? 0,
        workoutDone: j['workout_done'] as bool? ?? false,
        moodCheckin: (j['mood_checkin'] as num?)?.toInt(),
        meals: (j['meals'] as List?)
                ?.map((e) =>
                    FoodEntry.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
        cigarettes: (j['cigarettes'] as num?)?.toInt() ?? 0,
      );

  factory DailyData.empty(String date) => DailyData(date: date);
}
