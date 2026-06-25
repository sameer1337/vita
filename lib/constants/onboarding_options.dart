/// Static option lists used by the onboarding steps.
class OnboardingOptions {
  OnboardingOptions._();

  static const List<String> goals = [
    'Lose weight',
    'Build muscle',
    'Maintain weight',
    'Improve fitness',
    'Reduce stress',
  ];

  static const List<String> sexes = [
    'Male',
    'Female',
    'Prefer not to say',
  ];

  static const List<String> activityLevels = [
    'Sedentary',
    'Lightly active',
    'Moderately active',
    'Very active',
  ];

  static const List<String> equipment = [
    'Bodyweight only',
    'Dumbbells',
    'Resistance bands',
    'Home gym',
    'Full gym access',
  ];

  static const List<String> limitations = [
    'None',
    'Knee',
    'Back',
    'Shoulder',
    'Wrist',
    'Hip',
  ];

  static const List<String> dietPrefs = [
    'No restrictions',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'High protein',
    'Low carb',
    'Mediterranean',
  ];

  static const List<String> mealsPerDay = [
    '2',
    '3',
    '4',
    '5+',
  ];

  static const List<String> cookingFrequency = [
    'Rarely cook',
    'Cook some meals',
    'Cook most meals',
  ];

  static const List<int> sessionMinutes = [15, 30, 45, 60, 90];
}
