/// The full set of answers collected during onboarding (screens 0–16).
///
/// Held in local state until the user taps "Save My Plan"; serialized with
/// [toJson] to call the `generate-plan` Edge Function.
class OnboardingAnswers {
  final String goal;
  final String sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final double? targetWeightKg;
  final String activityLevel;
  final List<String> equipment;
  final int daysPerWeek;
  final int minutesPerSession;
  final List<String> limitations;
  final List<String> dietPrefs;
  final String? allergies;
  final String mealsPerDay;
  final String cookingFrequency;
  final int stressLevel;
  final int sleepQuality;
  final int mood;

  const OnboardingAnswers({
    required this.goal,
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    this.targetWeightKg,
    required this.activityLevel,
    required this.equipment,
    required this.daysPerWeek,
    required this.minutesPerSession,
    required this.limitations,
    required this.dietPrefs,
    this.allergies,
    required this.mealsPerDay,
    required this.cookingFrequency,
    required this.stressLevel,
    required this.sleepQuality,
    required this.mood,
  });

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'sex': sex,
        'age': age,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
        'activity_level': activityLevel,
        'equipment': equipment,
        'days_per_week': daysPerWeek,
        'minutes_per_session': minutesPerSession,
        'limitations': limitations,
        'diet_prefs': dietPrefs,
        'allergies': allergies ?? '',
        'meals_per_day': mealsPerDay,
        'cooking_frequency': cookingFrequency,
        'stress_level': stressLevel,
        'sleep_quality': sleepQuality,
        'mood': mood,
      };

  /// A representative set of answers used to smoke-test the backend wiring.
  factory OnboardingAnswers.sample() => const OnboardingAnswers(
        goal: 'Lose weight',
        sex: 'Male',
        age: 30,
        heightCm: 178,
        weightKg: 85,
        targetWeightKg: 75,
        activityLevel: 'Moderately active',
        equipment: ['Dumbbells'],
        daysPerWeek: 4,
        minutesPerSession: 45,
        limitations: [],
        dietPrefs: ['High protein'],
        allergies: '',
        mealsPerDay: '3',
        cookingFrequency: 'Cook most meals',
        stressLevel: 5,
        sleepQuality: 6,
        mood: 7,
      );
}
