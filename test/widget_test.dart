import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vita/models/onboarding_answers.dart';
import 'package:vita/models/plan.dart';

void main() {
  test('OnboardingAnswers.sample serializes to the API schema', () {
    final json = OnboardingAnswers.sample().toJson();
    expect(json['goal'], 'Lose weight');
    expect(json['height_cm'], 178);
    expect(json['stress_level'], 5);
  });

  test('WellnessPlan parses a generate-plan response', () {
    final plan = WellnessPlan.fromJson(const {
      'calorie_target': 2200,
      'macros': {'protein_g': 165, 'carbs_g': 220, 'fat_g': 73},
      'workout_plan': [
        {
          'day': 'Mon',
          'focus': 'Chest',
          'exercises': [
            {'name': 'Bench Press', 'sets': 4, 'reps': '8-10', 'rest_seconds': 90}
          ],
        }
      ],
      'sample_meals': [
        {'meal': 'Breakfast', 'items': '2 eggs, toast', 'calories': 380}
      ],
      'mind_checkin_prompt': 'What made you smile today?',
      'weekly_focus_tip': 'Stay consistent.',
      'refer_to_professional': false,
      'disclaimer': 'Not medical advice.',
    });

    expect(plan.calorieTarget, 2200);
    expect(plan.macros.proteinG, 165);
    expect(plan.workoutPlan.single.exercises.single.name, 'Bench Press');
    expect(plan.sampleMeals.single.calories, 380);
    expect(plan.referToProfessional, isFalse);
  });

  testWidgets('A trivial widget builds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Vita'))),
    );
    expect(find.text('Vita'), findsOneWidget);
  });
}
