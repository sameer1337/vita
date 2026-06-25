import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vita/models/plan.dart';
import 'package:vita/screens/diet/diet_plan_screen.dart';
import 'package:vita/screens/nutrition/nutrition_screen.dart';
import 'package:vita/screens/sleep/sleep_screen.dart';
import 'package:vita/services/local_store.dart';

WellnessPlan _plan() => WellnessPlan.fromJson(const {
      'calorie_target': 2100,
      'macros': {'protein_g': 150, 'carbs_g': 200, 'fat_g': 70},
      'workout_plan': [],
      'sample_meals': [],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.instance();
  });

  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('DietPlanScreen shows the generate prompt when uncached',
      (tester) async {
    await tester.pumpWidget(
        wrap(DietPlanScreen(calorieTarget: 2100, plan: _plan())));
    await tester.pumpAndSettle();
    expect(find.text('Your weekly meal plan'), findsOneWidget);
    expect(find.text('Generate my meal plan'), findsOneWidget);
  });

  testWidgets('SleepScreen renders the logger and chart', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(const SleepScreen()));
    await tester.pumpAndSettle();
    expect(find.text('How did you sleep?'), findsOneWidget);
    expect(find.text('Last 2 weeks'), findsOneWidget);
  });

  testWidgets('NutritionScreen renders macro progress + empty meals',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(NutritionScreen(plan: _plan())));
    await tester.pumpAndSettle();
    expect(find.text("Today's meals"), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
  });
}
