import 'package:flutter/material.dart';

import '../../models/diet_plan.dart';
import '../../models/plan.dart';
import '../../services/api_service.dart';
import '../../services/local_store.dart';
import '../../theme/app_theme.dart';

/// A goal-based weekly meal plan. Generated on demand via the `meal-plan` Edge
/// Function and cached locally, so it persists and can be regenerated.
class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key, required this.calorieTarget, this.plan});

  /// Daily calorie target, shown in the header.
  final int calorieTarget;

  /// The full wellness plan (used when (re)generating).
  final WellnessPlan? plan;

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  WeeklyDietPlan? _plan;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _plan = LocalStore.cached.loadDietPlan();
  }

  Future<void> _generate() async {
    final profile = LocalStore.cached.loadProfile();
    final wellnessPlan = widget.plan;
    if (profile == null || wellnessPlan == null) {
      setState(() => _error =
          'Finish setting up your plan first so we can tailor your meals.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await ApiService().generateMealPlan(profile, wellnessPlan);
      await LocalStore.cached.saveDietPlan(plan);
      if (mounted) setState(() => _plan = plan);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            "Couldn't build your meal plan just now. Please try again.");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
        title: const Text('Meal plan'),
        actions: [
          if (plan != null && !_loading)
            IconButton(
              tooltip: 'Regenerate',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _generate,
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const _LoadingView()
            : plan == null
                ? _EmptyView(error: _error, onGenerate: _generate)
                : _PlanView(plan: plan, target: widget.calorieTarget),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.sageLight),
          SizedBox(height: 18),
          Text(
            'Cooking up your week…',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.error, required this.onGenerate});
  final String? error;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_menu_rounded,
                size: 64, color: AppTheme.sageLight),
            const SizedBox(height: 20),
            const Text(
              'Your weekly meal plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'A 7-day plan built around your goal, calories, and food '
              'preferences — breakfast to dinner.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, height: 1.4),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFE0817C)),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.sage,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onGenerate,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Generate my meal plan',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanView extends StatelessWidget {
  const _PlanView({required this.plan, required this.target});
  final WeeklyDietPlan plan;
  final int target;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        // Strategy + targets.
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.darkSurfaceAlt, AppTheme.darkSurface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan.goalSummary.isNotEmpty)
                Text(
                  plan.goalSummary,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _macro('${plan.dailyCalories}', 'kcal/day'),
                  _macro('${plan.proteinG}g', 'protein'),
                  _macro('${plan.carbsG}g', 'carbs'),
                  _macro('${plan.fatG}g', 'fat'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final day in plan.days) _DayCard(day: day),
        if (plan.tips.isNotEmpty) ...[
          const SizedBox(height: 8),
          _TipsCard(tips: plan.tips),
        ],
        if (plan.disclaimer.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            plan.disclaimer,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _macro(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});
  final DietDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          iconColor: AppTheme.sageLight,
          collapsedIconColor: Colors.white54,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18),
          title: Text(
            day.day,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            '${day.calories} kcal',
            style: const TextStyle(color: AppTheme.sageLight, fontSize: 12.5),
          ),
          children: [
            for (final m in day.meals)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
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
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${m.calories}',
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
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.tips});
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tips for your goal',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          for (final t in tips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 8),
                    child: Icon(Icons.eco_rounded,
                        size: 15, color: AppTheme.sageLight),
                  ),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
