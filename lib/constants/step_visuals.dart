import 'package:flutter/material.dart';

/// A colorful emoji "character" + accent color for each onboarding step,
/// used for the hero header and themed background.
class StepVisual {
  final String emoji;
  final Color color;
  const StepVisual(this.emoji, this.color);
}

class StepVisuals {
  StepVisuals._();

  /// Indexed by onboarding step (0..19).
  static const List<StepVisual> all = [
    StepVisual('🌱', Color(0xFF6B9080)), // 0 welcome
    StepVisual('👋', Color(0xFFE39A53)), // 1 name
    StepVisual('✉️', Color(0xFF5B8DB8)), // 2 email
    StepVisual('🎂', Color(0xFFD16BA5)), // 3 dob
    StepVisual('🎯', Color(0xFFE0566E)), // 4 goal
    StepVisual('🧑', Color(0xFF7E6CC4)), // 5 sex
    StepVisual('📏', Color(0xFF4FA3A3)), // 6 height
    StepVisual('⚖️', Color(0xFF5B8DB8)), // 7 weight
    StepVisual('🏁', Color(0xFFE39A53)), // 8 target weight
    StepVisual('🚶', Color(0xFF6BA368)), // 9 activity
    StepVisual('🏋️', Color(0xFFE0566E)), // 10 equipment
    StepVisual('📅', Color(0xFF5B8DB8)), // 11 days/week
    StepVisual('⏱️', Color(0xFFE39A53)), // 12 minutes
    StepVisual('🩹', Color(0xFFD16BA5)), // 13 limitations
    StepVisual('🥗', Color(0xFF6BA368)), // 14 diet prefs
    StepVisual('🥜', Color(0xFFE0566E)), // 15 allergies
    StepVisual('🍽️', Color(0xFFE39A53)), // 16 meals/day
    StepVisual('👩‍🍳', Color(0xFF4FA3A3)), // 17 cooking
    StepVisual('⏰', Color(0xFF7E6CC4)), // 18 workout time
    StepVisual('🧘', Color(0xFF6B9080)), // 19 mind check-in
    StepVisual('🚭', Color(0xFF4FA3A3)), // 20 smoking
  ];

  static StepVisual of(int i) =>
      (i >= 0 && i < all.length) ? all[i] : all.first;
}
