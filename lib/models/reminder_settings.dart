/// User preferences for Vita's daily reminders, persisted locally.
class ReminderSettings {
  const ReminderSettings({
    this.workoutEnabled = false,
    this.workoutHour = 7,
    this.workoutMinute = 0,
    this.waterEnabled = false,
    this.waterTimesPerDay = 6,
    this.smokingEnabled = false,
    this.smokingHour = 20,
    this.smokingMinute = 0,
  });

  final bool workoutEnabled;
  final int workoutHour;
  final int workoutMinute;

  final bool waterEnabled;
  final int waterTimesPerDay;

  final bool smokingEnabled;
  final int smokingHour;
  final int smokingMinute;

  ReminderSettings copyWith({
    bool? workoutEnabled,
    int? workoutHour,
    int? workoutMinute,
    bool? waterEnabled,
    int? waterTimesPerDay,
    bool? smokingEnabled,
    int? smokingHour,
    int? smokingMinute,
  }) =>
      ReminderSettings(
        workoutEnabled: workoutEnabled ?? this.workoutEnabled,
        workoutHour: workoutHour ?? this.workoutHour,
        workoutMinute: workoutMinute ?? this.workoutMinute,
        waterEnabled: waterEnabled ?? this.waterEnabled,
        waterTimesPerDay: waterTimesPerDay ?? this.waterTimesPerDay,
        smokingEnabled: smokingEnabled ?? this.smokingEnabled,
        smokingHour: smokingHour ?? this.smokingHour,
        smokingMinute: smokingMinute ?? this.smokingMinute,
      );

  Map<String, dynamic> toJson() => {
        'workout_enabled': workoutEnabled,
        'workout_hour': workoutHour,
        'workout_minute': workoutMinute,
        'water_enabled': waterEnabled,
        'water_times_per_day': waterTimesPerDay,
        'smoking_enabled': smokingEnabled,
        'smoking_hour': smokingHour,
        'smoking_minute': smokingMinute,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> j) => ReminderSettings(
        workoutEnabled: j['workout_enabled'] as bool? ?? false,
        workoutHour: (j['workout_hour'] as num?)?.toInt() ?? 7,
        workoutMinute: (j['workout_minute'] as num?)?.toInt() ?? 0,
        waterEnabled: j['water_enabled'] as bool? ?? false,
        waterTimesPerDay: (j['water_times_per_day'] as num?)?.toInt() ?? 6,
        smokingEnabled: j['smoking_enabled'] as bool? ?? false,
        smokingHour: (j['smoking_hour'] as num?)?.toInt() ?? 20,
        smokingMinute: (j['smoking_minute'] as num?)?.toInt() ?? 0,
      );
}
