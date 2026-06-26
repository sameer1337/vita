import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan.dart';
import '../providers/daily_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/smoking_provider.dart';
import '../providers/steps_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/refer_banner.dart';
import 'account/account_screen.dart';
import 'breathing/breathing_screen.dart';
import 'coach/coach_screen.dart';
import 'diet/diet_plan_screen.dart';
import 'nutrition/nutrition_screen.dart';
import 'settings/reminders_screen.dart';
import 'sleep/sleep_screen.dart';
import 'smoking/smoking_screen.dart';
import 'workout/workout_player_screen.dart';

/// The home hub — a compact, colorful dashboard: a greeting header (with the
/// side-menu button), today's workout, the live rings, and a grid of module
/// tiles that link to every part of the app. Designed to fit with little
/// scrolling.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.plan});

  final WellnessPlan plan;

  static const int _stepGoal = 8000;

  WorkoutDay? get _today {
    if (plan.workoutPlan.isEmpty) return null;
    final weekday = _weekdayName(DateTime.now().weekday).toLowerCase();
    for (final d in plan.workoutPlan) {
      if (d.day.toLowerCase().startsWith(weekday.substring(0, 3))) return d;
    }
    return plan.workoutPlan.first;
  }

  static String _weekdayName(int w) => const [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday',
      ][(w - 1) % 7];

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  int _estMinutes(WorkoutDay day) {
    var secs = 0;
    for (final ex in day.exercises) {
      final sets = ex.sets <= 0 ? 1 : ex.sets;
      final rest = ex.restSeconds <= 0 ? 30 : ex.restSeconds;
      secs += sets * 45 + (sets - 1) * rest;
    }
    return (secs / 60).ceil();
  }

  int _baseWaterGoal(double? weightKg) {
    if (weightKg == null || weightKg <= 0) return 2500;
    return (weightKg * 35).round();
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final daily = ref.watch(dailyProvider);
    final weatherAsync = ref.watch(weatherProvider);
    final stepsAsync = ref.watch(stepsProvider);
    final smoking = ref.watch(smokingProvider);
    final today = _today;

    final weather = weatherAsync.asData?.value;
    final waterGoal =
        _baseWaterGoal(draft.weightKg) + (weather?.hydrationBonusMl ?? 0);
    final steps = stepsAsync.asData?.value;
    final streak = ref.read(dailyProvider.notifier).currentStreak();
    final completed =
        ref.read(dailyProvider.notifier).completedDates().toSet();

    final tiles = <Widget>[
      _ModuleTile(
        icon: Icons.smart_toy_rounded,
        title: 'AI Coach',
        subtitle: 'Ask anything',
        colors: const [Color(0xFF7E6CC4), Color(0xFF9C8AE0)],
        onTap: () => _open(context, CoachScreen(plan: plan)),
      ),
      _ModuleTile(
        icon: Icons.restaurant_menu_rounded,
        title: 'Meal plan',
        subtitle: '7-day plan',
        colors: const [Color(0xFFE39A53), Color(0xFFEFB877)],
        onTap: () => _open(context,
            DietPlanScreen(calorieTarget: plan.calorieTarget, plan: plan)),
      ),
      _ModuleTile(
        icon: Icons.local_fire_department_rounded,
        title: 'Nutrition',
        subtitle: '${daily.caloriesLogged} kcal today',
        colors: const [Color(0xFF4FA37A), Color(0xFF6FC79A)],
        onTap: () => _open(context, NutritionScreen(plan: plan)),
      ),
      _ModuleTile(
        icon: Icons.bedtime_rounded,
        title: 'Sleep',
        subtitle: daily.sleepHours > 0
            ? '${daily.sleepHours.toStringAsFixed(1)} h'
            : 'Log last night',
        colors: const [Color(0xFF4C6BC4), Color(0xFF6F8DDC)],
        onTap: () => _open(context, const SleepScreen()),
      ),
      _ModuleTile(
        icon: Icons.air_rounded,
        title: 'Breathe',
        subtitle: 'Calm & focus',
        colors: const [Color(0xFF3FA3A3), Color(0xFF5FC4C0)],
        onTap: () => _open(context, const BreathingScreen()),
      ),
      if (smoking.trackingEnabled)
        _ModuleTile(
          icon: Icons.smoke_free_rounded,
          title: 'Quit smoking',
          subtitle: '${daily.cigarettes}/${smoking.dailyLimit} today',
          colors: const [Color(0xFFD06A78), Color(0xFFE68A97)],
          onTap: () => _open(context, const SmokingScreen()),
        ),
      _ModuleTile(
        icon: Icons.notifications_active_rounded,
        title: 'Reminders',
        subtitle: 'Stay on track',
        colors: const [Color(0xFFE0A14E), Color(0xFFEFC17C)],
        onTap: () => _open(context, const RemindersScreen()),
      ),
      _ModuleTile(
        icon: Icons.person_rounded,
        title: 'Account',
        subtitle: 'Back up & sync',
        colors: const [Color(0xFF5B7A70), Color(0xFF7E9C90)],
        onTap: () => _open(context, const AccountScreen()),
      ),
    ];

    return Container(
      color: AppTheme.darkBg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            _Header(
              greeting: _greeting(),
              name: draft.firstName,
              streak: streak,
              onMenu: () => Scaffold.of(context).openDrawer(),
              onAccount: () => _open(context, const AccountScreen()),
            ),
            const SizedBox(height: 16),
            if (plan.referToProfessional) ...[
              const ReferBanner(),
              const SizedBox(height: 14),
            ],
            if (daily.moodCheckin == null) ...[
              _MoodRow(
                onPick: (m) =>
                    ref.read(dailyProvider.notifier).setMoodCheckin(m),
              ),
              const SizedBox(height: 14),
            ],
            _WorkoutHero(
              day: today,
              minutes: today == null ? 0 : _estMinutes(today),
              done: today != null &&
                  completed.contains(LocalDateKey.today()),
              onStart: today == null
                  ? null
                  : () => _open(context, WorkoutPlayerScreen(day: today)),
            ),
            const SizedBox(height: 14),
            _Rings(
              caloriesLogged: daily.caloriesLogged,
              calorieTarget: plan.calorieTarget,
              waterMl: daily.waterMl,
              waterGoal: waterGoal,
              steps: steps,
              stepGoal: _stepGoal,
              weatherEmoji: weather?.emoji,
              feelsLike: weather?.feelsLikeC,
              onAddWater: () => ref.read(dailyProvider.notifier).addWater(250),
              onCalories: () => _open(context, NutritionScreen(plan: plan)),
            ),
            const SizedBox(height: 22),
            const Text(
              'Explore',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: tiles,
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper for "is this date today" comparisons in the widget tree.
class LocalDateKey {
  static String today() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
    required this.streak,
    required this.onMenu,
    required this.onAccount,
  });
  final String greeting;
  final String name;
  final int streak;
  final VoidCallback onMenu;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _circleButton(Icons.menu_rounded, onMenu),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
              Text(
                name.isEmpty ? 'Welcome' : name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE0566E).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('$streak',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onAccount,
          child: CircleAvatar(
            radius: 21,
            backgroundColor: AppTheme.sage,
            child: Text(
              name.isEmpty ? '🌱' : name.characters.first.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) => Material(
        color: AppTheme.darkSurface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      );
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({required this.onPick});
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    const faces = ['😞', '😕', '😐', '🙂', '😄'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('How are you feeling?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          for (var i = 0; i < faces.length; i++)
            GestureDetector(
              onTap: () => onPick(i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(faces[i], style: const TextStyle(fontSize: 22)),
              ),
            ),
        ],
      ),
    );
  }
}

/// The headline "today's workout" card — the dashboard's main call to action.
class _WorkoutHero extends StatelessWidget {
  const _WorkoutHero({
    required this.day,
    required this.minutes,
    required this.done,
    required this.onStart,
  });

  final WorkoutDay? day;
  final int minutes;
  final bool done;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          children: [
            Text('🌿', style: TextStyle(fontSize: 30)),
            SizedBox(width: 14),
            Expanded(
              child: Text('Rest day — recover and come back strong.',
                  style: TextStyle(color: Colors.white70, height: 1.35)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D5B), Color(0xFF6B9080)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("TODAY'S WORKOUT",
                  style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 11)),
              const Spacer(),
              if (done)
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            day!.focus,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${day!.exercises.length} exercises · ~$minutes min',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.deepSage,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onStart,
              icon: Icon(done
                  ? Icons.replay_rounded
                  : Icons.play_arrow_rounded),
              label: Text(done ? 'Do it again' : 'Start workout',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rings extends StatelessWidget {
  const _Rings({
    required this.caloriesLogged,
    required this.calorieTarget,
    required this.waterMl,
    required this.waterGoal,
    required this.steps,
    required this.stepGoal,
    required this.weatherEmoji,
    required this.feelsLike,
    required this.onAddWater,
    required this.onCalories,
  });

  final int caloriesLogged;
  final int calorieTarget;
  final int waterMl;
  final int waterGoal;
  final int? steps;
  final int stepGoal;
  final String? weatherEmoji;
  final double? feelsLike;
  final VoidCallback onAddWater;
  final VoidCallback onCalories;

  @override
  Widget build(BuildContext context) {
    final glasses = (waterMl / 250).floor();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkSurface, AppTheme.darkSurfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: onCalories,
            child: _Ring(
              value: caloriesLogged.toDouble(),
              goal: calorieTarget.toDouble(),
              center: '$caloriesLogged',
              label: 'kcal',
              color: const Color(0xFF6FC79A),
              icon: Icons.local_fire_department_rounded,
            ),
          ),
          GestureDetector(
            onTap: onAddWater,
            child: _Ring(
              value: waterMl.toDouble(),
              goal: waterGoal.toDouble(),
              center: '$glasses',
              label: '+ water',
              color: const Color(0xFF5FA8E6),
              icon: Icons.water_drop_rounded,
            ),
          ),
          _Ring(
            value: (steps ?? 0).toDouble(),
            goal: stepGoal.toDouble(),
            center: steps == null ? '—' : '$steps',
            label: weatherEmoji != null && feelsLike != null
                ? '$weatherEmoji ${feelsLike!.round()}°'
                : 'steps',
            color: const Color(0xFFE0A14E),
            icon: Icons.directions_walk_rounded,
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.value,
    required this.goal,
    required this.center,
    required this.label,
    required this.color,
    required this.icon,
  });

  final double value;
  final double goal;
  final String center;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final pct = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 78,
          height: 78,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 16),
                  Text(center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
