import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/plan.dart';
import '../../providers/daily_provider.dart';
import '../../theme/app_theme.dart';
import '../food/meal_log_screen.dart';

/// Today's nutrition in detail: calories + macro progress against the plan's
/// targets, and the list of meals logged today (with remove).
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key, required this.plan});
  final WellnessPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyProvider);
    final left = (plan.calorieTarget - daily.caloriesLogged).clamp(0, 100000);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
        title: const Text('Nutrition'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.sage,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log meal'),
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const MealLogScreen()),
          );
          if (saved == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Meal added 🍽️')),
            );
          }
        },
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _big('${daily.caloriesLogged}', 'eaten'),
                      _big('$left', 'left'),
                      _big('${plan.calorieTarget}', 'target'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _MacroBar(
                    label: 'Protein',
                    value: daily.proteinG,
                    target: plan.macros.proteinG.round(),
                    color: AppTheme.sage,
                  ),
                  const SizedBox(height: 12),
                  _MacroBar(
                    label: 'Carbs',
                    value: daily.carbsG,
                    target: plan.macros.carbsG.round(),
                    color: const Color(0xFFE39A53),
                  ),
                  const SizedBox(height: 12),
                  _MacroBar(
                    label: 'Fat',
                    value: daily.fatG,
                    target: plan.macros.fatG.round(),
                    color: const Color(0xFF6FA8DC),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Today's meals",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (daily.meals.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Text('🍽️', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No meals logged yet today. Tap "Log meal" to add one '
                        'by photo or description.',
                        style: TextStyle(color: Colors.white60, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < daily.meals.length; i++)
                _MealRow(
                  label: daily.meals[i].label,
                  calories: daily.meals[i].calories,
                  proteinG: daily.meals[i].proteinG,
                  carbsG: daily.meals[i].carbsG,
                  fatG: daily.meals[i].fatG,
                  onRemove: () =>
                      ref.read(dailyProvider.notifier).removeMeal(i),
                ),
          ],
        ),
      ),
    );
  }

  Widget _big(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      );
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });
  final String label;
  final int value;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              '${value}g / ${target}g',
              style: const TextStyle(color: Colors.white54, fontSize: 12.5),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppTheme.darkSurfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.label,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.onRemove,
  });
  final String label;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  'P ${proteinG}g · C ${carbsG}g · F ${fatG}g',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Text('$calories',
              style: const TextStyle(
                  color: AppTheme.sageLight, fontWeight: FontWeight.w700)),
          const Text(' kcal',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: Colors.white38, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
