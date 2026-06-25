import 'package:flutter/material.dart';

import '../../models/plan.dart';
import '../../theme/app_theme.dart';
import '../workout/workout_player_screen.dart';

/// Read-only view of the full generated plan: targets, the week's workouts
/// (expandable), and sample meals.
class PlanTab extends StatelessWidget {
  const PlanTab({super.key, required this.plan});
  final WellnessPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkBg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            const Text(
              'Your plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _card(
              'Daily targets',
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('${plan.calorieTarget}', 'kcal'),
                  _stat('${plan.macros.proteinG}g', 'protein'),
                  _stat('${plan.macros.carbsG}g', 'carbs'),
                  _stat('${plan.macros.fatG}g', 'fat'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              'Workout week',
              Column(
                children: [
                  for (final day in plan.workoutPlan) _DayTile(day: day),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (plan.sampleMeals.isNotEmpty)
              _card(
                'Sample meals',
                Column(
                  children: [
                    for (final m in plan.sampleMeals)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.meal,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m.items,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${m.calories} kcal',
                              style: const TextStyle(
                                color: AppTheme.sageLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day});
  final WorkoutDay day;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          iconColor: AppTheme.sageLight,
          collapsedIconColor: Colors.white54,
          title: Text(
            '${day.day} · ${day.focus}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            for (final ex in day.exercises)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ex.name,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Text(
                      '${ex.sets} × ${ex.reps}',
                      style: const TextStyle(color: Colors.white38),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkoutPlayerScreen(day: day),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start workout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
