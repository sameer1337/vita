import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vita/models/plan.dart';
import 'package:vita/providers/steps_provider.dart';
import 'package:vita/providers/weather_provider.dart';
import 'package:vita/screens/home/home_shell.dart';
import 'package:vita/services/local_store.dart';
import 'package:vita/services/weather_service.dart';
import 'package:vita/widgets/exercise_demo.dart';

WellnessPlan _samplePlan() => WellnessPlan.fromJson(const {
      'calorie_target': 2200,
      'macros': {'protein_g': 165, 'carbs_g': 220, 'fat_g': 73},
      'workout_plan': [
        {
          'day': 'Mon',
          'focus': 'Full body',
          'exercises': [
            {'name': 'Goblet Squat', 'sets': 3, 'reps': '10', 'rest_seconds': 60},
            {'name': 'Push Up', 'sets': 3, 'reps': '12', 'rest_seconds': 45},
          ],
        },
        {
          'day': 'Wed',
          'focus': 'Cardio',
          'exercises': [
            {'name': 'Jumping Jacks', 'sets': 3, 'reps': '30s', 'rest_seconds': 30},
          ],
        },
      ],
      'sample_meals': [
        {'meal': 'Breakfast', 'items': '2 eggs, toast', 'calories': 380},
      ],
      'mind_checkin_prompt': 'What made you smile today?',
      'weekly_focus_tip': 'Stay consistent.',
      'refer_to_professional': false,
      'disclaimer': 'Not medical advice.',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.instance();
  });

  Widget wrap(Widget child) => ProviderScope(
        overrides: [
          // Avoid hitting device plugins (geolocator / pedometer) in tests.
          weatherProvider.overrideWith((ref) async => const WeatherInfo(
                tempC: 24,
                feelsLikeC: 24,
                humidity: 50,
                code: 0,
                description: 'Clear sky',
                emoji: '☀️',
                hydrationBonusMl: 0,
                advice: 'Comfortable conditions — a good day to move.',
              )),
          stepsProvider.overrideWith((ref) => Stream.value(3200)),
        ],
        child: MaterialApp(home: child),
      );

  testWidgets('HomeShell builds and switches tabs', (tester) async {
    // Tall viewport so the whole scrollable dashboard is laid out.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(HomeShell(plan: _samplePlan())));
    await tester.pumpAndSettle();

    // Dashboard (Home tab) renders core sections.
    expect(find.text('Today’s workout'), findsOneWidget);
    expect(find.text('Your week'), findsOneWidget);
    expect(find.text('How are you feeling today?'), findsOneWidget);

    // Bottom nav present.
    expect(find.text('Coach'), findsWidgets);
    expect(find.text('Plan'), findsWidgets);

    // Switch to the Coach tab.
    await tester.tap(find.text('Coach').first);
    await tester.pumpAndSettle();
    expect(find.text('Vita Coach'), findsOneWidget);

    // Switch to the Plan tab.
    await tester.tap(find.text('Plan').first);
    await tester.pumpAndSettle();
    expect(find.text('Your plan'), findsOneWidget);
  });

  testWidgets('ExerciseDemo renders an animated category demo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: ExerciseDemo(name: 'Push Up')))),
    );
    await tester.pump(const Duration(milliseconds: 200));
    // Push Up maps to the Strength family.
    expect(find.text('Strength'), findsOneWidget);
    // Dispose the animating widget cleanly.
    await tester.pumpWidget(const SizedBox());
  });
}
