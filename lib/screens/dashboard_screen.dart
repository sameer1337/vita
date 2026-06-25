import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan.dart';
import '../providers/daily_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/smoking_provider.dart';
import '../providers/steps_provider.dart';
import '../providers/weather_provider.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/refer_banner.dart';
import 'account/account_screen.dart';
import 'settings/reminders_screen.dart';
import 'smoking/smoking_screen.dart';
import 'workout/workout_player_screen.dart';

/// The home hub: a dark + sage dashboard that pulls together today's live
/// numbers (calories logged, water, steps), the mood check-in, weather-aware
/// hydration guidance, the week overview with completion ticks, and targets.
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

  /// Base daily water goal (ml): ~35 ml/kg, sensible default if weight unknown.
  int _baseWaterGoal(double? weightKg) {
    if (weightKg == null || weightKg <= 0) return 2500;
    return (weightKg * 35).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final daily = ref.watch(dailyProvider);
    final weatherAsync = ref.watch(weatherProvider);
    final stepsAsync = ref.watch(stepsProvider);
    final today = _today;

    final weather = weatherAsync.asData?.value;
    final smoking = ref.watch(smokingProvider);
    final waterGoal =
        _baseWaterGoal(draft.weightKg) + (weather?.hydrationBonusMl ?? 0);
    final steps = stepsAsync.asData?.value;
    final streak = ref.read(dailyProvider.notifier).currentStreak();
    final completedDates =
        ref.read(dailyProvider.notifier).completedDates().toSet();

    return Container(
      color: AppTheme.darkBg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            _Header(
              greeting: _greeting(),
              name: draft.firstName,
              streak: streak,
              onSettings: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              ),
              onAccount: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              ),
            ),
            const SizedBox(height: 20),
            if (plan.referToProfessional) ...[
              const ReferBanner(),
              const SizedBox(height: 20),
            ],
            if (daily.moodCheckin == null)
              _MoodCheckIn(
                onPick: (m) =>
                    ref.read(dailyProvider.notifier).setMoodCheckin(m),
              )
            else
              _MoodDone(mood: daily.moodCheckin!),
            const SizedBox(height: 16),
            _TodayRings(
              caloriesLogged: daily.caloriesLogged,
              calorieTarget: plan.calorieTarget,
              waterMl: daily.waterMl,
              waterGoal: waterGoal,
              steps: steps,
              stepGoal: _stepGoal,
              onAddWater: () =>
                  ref.read(dailyProvider.notifier).addWater(250),
              onResetWater: () =>
                  ref.read(dailyProvider.notifier).resetWater(),
            ),
            const SizedBox(height: 16),
            _WeatherWidget(
              state: weatherAsync,
              onRetry: () => ref.invalidate(weatherProvider),
            ),
            if (!smoking.asked) ...[
              const SizedBox(height: 16),
              _SmokingPrompt(
                onAnswer: (smokes, quit) => ref
                    .read(smokingProvider.notifier)
                    .answer(smokes: smokes, wantsToQuit: quit),
              ),
            ] else if (smoking.trackingEnabled) ...[
              const SizedBox(height: 16),
              _SmokingCard(
                today: daily.cigarettes,
                limit: smoking.dailyLimit,
                onLog: () => ref.read(dailyProvider.notifier).logCigarette(),
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SmokingScreen()),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (today != null) ...[
              _SectionTitle('Today’s workout'),
              const SizedBox(height: 12),
              _TodayCard(
                day: today,
                minutes: _estMinutes(today),
                done: completedDates.contains(
                    LocalDateKey.today()),
                onStart: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkoutPlayerScreen(day: today),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            _SectionTitle('Your week'),
            const SizedBox(height: 12),
            _WeekStrip(plan: plan, completed: completedDates),
            const SizedBox(height: 24),
            _SectionTitle('Daily targets'),
            const SizedBox(height: 12),
            _TargetsCard(plan: plan, logged: daily.caloriesLogged),
            const SizedBox(height: 20),
            _InfoCard(
              emoji: '💡',
              title: 'This week’s focus',
              body: plan.weeklyFocusTip,
              color: const Color(0xFFE39A53),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              emoji: '🧘',
              title: 'Mind check-in',
              body: plan.mindCheckinPrompt,
              color: const Color(0xFF7E6CC4),
            ),
            const SizedBox(height: 20),
            Text(
              plan.disclaimer.isNotEmpty
                  ? plan.disclaimer
                  : 'General wellness guidance only — not medical advice.',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small helper for "is this date today" comparisons in the widget tree.
class LocalDateKey {
  static String today() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static String of(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
    required this.streak,
    required this.onSettings,
    required this.onAccount,
  });
  final String greeting;
  final String name;
  final int streak;
  final VoidCallback onSettings;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: const TextStyle(color: Colors.white54, fontSize: 15)),
              const SizedBox(height: 2),
              Text(
                name.isEmpty ? 'Welcome 👋' : '$name 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE39A53).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text('$streak day${streak == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: Color(0xFFE7B07A),
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        IconButton(
          onPressed: onSettings,
          tooltip: 'Reminders',
          icon: const Icon(Icons.notifications_none_rounded,
              color: Colors.white70),
        ),
        IconButton(
          onPressed: onAccount,
          tooltip: 'Account & sync',
          icon: const Icon(Icons.account_circle_outlined,
              color: Colors.white70),
        ),
      ],
    );
  }
}

class _MoodCheckIn extends StatelessWidget {
  const _MoodCheckIn({required this.onPick});
  final void Function(int) onPick;

  static const _emojis = ['😞', '😕', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How are you feeling today?',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _emojis.length; i++)
                GestureDetector(
                  onTap: () => onPick(i + 1),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(_emojis[i],
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodDone extends StatelessWidget {
  const _MoodDone({required this.mood});
  final int mood;

  static const _emojis = ['😞', '😕', '😐', '🙂', '😄'];
  static const _replies = [
    'Thanks for checking in. Be gentle with yourself today. 💚',
    'Noted. A short walk or some water can lift a low mood.',
    'Steady is good. Let’s make today count.',
    'Love that. Channel it into your session today!',
    'Amazing energy — let’s ride it. 🚀',
  ];

  @override
  Widget build(BuildContext context) {
    final i = (mood - 1).clamp(0, 4);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.sage.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(_emojis[i], style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(_replies[i],
                style: const TextStyle(color: Colors.white, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

class _TodayRings extends StatelessWidget {
  const _TodayRings({
    required this.caloriesLogged,
    required this.calorieTarget,
    required this.waterMl,
    required this.waterGoal,
    required this.steps,
    required this.stepGoal,
    required this.onAddWater,
    required this.onResetWater,
  });

  final int caloriesLogged;
  final int calorieTarget;
  final int waterMl;
  final int waterGoal;
  final int? steps;
  final int stepGoal;
  final VoidCallback onAddWater;
  final VoidCallback onResetWater;

  @override
  Widget build(BuildContext context) {
    final glasses = (waterMl / 250).floor();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.darkSurface, AppTheme.darkSurfaceAlt],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatRing(
                label: 'Calories',
                value: caloriesLogged.toDouble(),
                goal: calorieTarget.toDouble(),
                centerTop: '$caloriesLogged',
                centerBottom: '/ $calorieTarget',
                color: const Color(0xFF6B9080),
                icon: Icons.local_fire_department_rounded,
              ),
              _StatRing(
                label: 'Water',
                value: waterMl.toDouble(),
                goal: waterGoal.toDouble(),
                centerTop: '$glasses',
                centerBottom: 'glasses',
                color: const Color(0xFF5B8DB8),
                icon: Icons.water_drop_rounded,
              ),
              _StatRing(
                label: 'Steps',
                value: (steps ?? 0).toDouble(),
                goal: stepGoal.toDouble(),
                centerTop: steps == null ? '—' : '$steps',
                centerBottom: steps == null ? 'mobile' : '/ $stepGoal',
                color: const Color(0xFFE39A53),
                icon: Icons.directions_walk_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5B8DB8).withValues(
                      alpha: 0.22,
                    ),
                    foregroundColor: const Color(0xFF9CC6E6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onAddWater,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('250 ml water'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Reset water',
                onPressed: onResetWater,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRing extends StatelessWidget {
  const _StatRing({
    required this.label,
    required this.value,
    required this.goal,
    required this.centerTop,
    required this.centerBottom,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final double goal;
  final String centerTop;
  final String centerBottom;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final pct = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 86,
          height: 86,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 86,
                height: 86,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(centerTop,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  Text(centerBottom,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

/// Weather widget that always renders: loading shimmer, an "enable location"
/// state when unavailable, or the live conditions + hydration advice.
class _WeatherWidget extends StatelessWidget {
  const _WeatherWidget({required this.state, required this.onRetry});

  final AsyncValue<WeatherInfo?> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => _shell(
        child: Row(
          children: const [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF9CC6E6)),
            ),
            SizedBox(width: 14),
            Text('Checking the weather…',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
      error: (_, _) => _unavailable(),
      data: (w) => w == null ? _unavailable() : _content(w),
    );
  }

  Widget _unavailable() => _shell(
        child: Row(
          children: [
            const Text('🌍', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Enable location to get weather-based hydration tips.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Enable',
                  style: TextStyle(color: Color(0xFF9CC6E6))),
            ),
          ],
        ),
      );

  Widget _content(WeatherInfo w) => _shell(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(w.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 2),
                Text('${w.feelsLikeC.round()}°',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
                Text(w.description,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hydration & weather',
                      style: TextStyle(
                          color: Color(0xFF9CC6E6),
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(w.advice,
                      style: const TextStyle(
                          color: Colors.white70, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _shell({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: const Color(0xFF5B8DB8).withValues(alpha: 0.3)),
        ),
        child: child,
      );
}

/// First-run prompt: do you smoke, and do you want help quitting?
class _SmokingPrompt extends StatelessWidget {
  const _SmokingPrompt({required this.onAnswer});

  /// (smokes, wantsToQuit)
  final void Function(bool smokes, bool wantsToQuit) onAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.sage.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🚭  Do you smoke?',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Vita can help you cut down with a daily tracker — log each '
            'cigarette and watch the number fall over time.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.sage,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => onAnswer(true, true),
              child: const Text('Yes — help me quit'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  onPressed: () => onAnswer(true, false),
                  child: const Text('I smoke, not now'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  onPressed: () => onAnswer(false, false),
                  child: const Text("I don't smoke"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dashboard quit-smoking card: today's count, quick log, and a warning when
/// over the daily limit. Tap to open the full tracker.
class _SmokingCard extends StatelessWidget {
  const _SmokingCard({
    required this.today,
    required this.limit,
    required this.onLog,
    required this.onOpen,
  });

  final int today;
  final int limit;
  final VoidCallback onLog;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final over = today > limit;
    final accent = over ? const Color(0xFFE0566E) : AppTheme.sage;
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🚭  Quit smoking',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  over
                      ? '$today today · over your limit of $limit'
                      : '$today today · limit $limit',
                  style: TextStyle(
                      color: over ? const Color(0xFFE89AA6) : Colors.white54,
                      fontSize: 13),
                ),
              ],
            ),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onLog,
              child: const Text('+1'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.day,
    required this.minutes,
    required this.done,
    required this.onStart,
  });

  final WorkoutDay day;
  final int minutes;
  final bool done;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B9080), Color(0xFF3E5F53)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sage.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(done ? 'COMPLETED' : 'TODAY',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  )),
              const Spacer(),
              Icon(done ? Icons.check_circle_rounded : Icons.bolt,
                  color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(day.focus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 4),
          Text('${day.exercises.length} exercises  ·  ~$minutes min',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.deepSage,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onStart,
              icon: Icon(done
                  ? Icons.replay_rounded
                  : Icons.play_arrow_rounded),
              label: Text(done ? 'Do it again' : 'Start workout',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.plan, required this.completed});
  final WellnessPlan plan;
  final Set<String> completed;

  static const List<Color> _accents = [
    Color(0xFF6B9080),
    Color(0xFF5B8DB8),
    Color(0xFFE39A53),
    Color(0xFFD16BA5),
    Color(0xFF7E6CC4),
    Color(0xFF6BA368),
    Color(0xFFE0566E),
  ];

  @override
  Widget build(BuildContext context) {
    if (plan.workoutPlan.isEmpty) {
      return const Text('No workouts scheduled.',
          style: TextStyle(color: Colors.white54));
    }
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: plan.workoutPlan.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final day = plan.workoutPlan[i];
          final color = _accents[i % _accents.length];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WorkoutPlayerScreen(day: day),
              ),
            ),
            child: Container(
              width: 128,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.18),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.fitness_center, color: color, size: 18),
                  ),
                  const Spacer(),
                  Text(day.day,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(day.focus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TargetsCard extends StatelessWidget {
  const _TargetsCard({required this.plan, required this.logged});
  final WellnessPlan plan;
  final int logged;

  @override
  Widget build(BuildContext context) {
    final p = plan.macros.proteinG.toDouble();
    final c = plan.macros.carbsG.toDouble();
    final f = plan.macros.fatG.toDouble();
    final pc = p * 4, cc = c * 4, fc = f * 9;
    final remaining = (plan.calorieTarget - logged).clamp(0, plan.calorieTarget);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 38,
                    sections: [
                      PieChartSectionData(
                          value: pc,
                          color: const Color(0xFF6B9080),
                          radius: 14,
                          showTitle: false),
                      PieChartSectionData(
                          value: cc,
                          color: const Color(0xFF5B8DB8),
                          radius: 14,
                          showTitle: false),
                      PieChartSectionData(
                          value: fc,
                          color: const Color(0xFFD9A86C),
                          radius: 14,
                          showTitle: false),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$remaining',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                    const Text('kcal left',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _macroRow('Protein', '${plan.macros.proteinG} g',
                    const Color(0xFF6B9080)),
                const SizedBox(height: 12),
                _macroRow('Carbs', '${plan.macros.carbsG} g',
                    const Color(0xFF5B8DB8)),
                const SizedBox(height: 12),
                _macroRow(
                    'Fat', '${plan.macros.fatG} g', const Color(0xFFD9A86C)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.emoji,
    required this.title,
    required this.body,
    required this.color,
  });

  final String emoji;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(body,
                    style:
                        const TextStyle(color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}
