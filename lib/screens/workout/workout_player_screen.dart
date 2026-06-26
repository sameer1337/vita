import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/plan.dart';
import '../../providers/daily_provider.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercise_demo.dart';

enum _Kind { work, rest }

/// One timed segment of the workout (a working set, or a rest period).
class _Segment {
  final _Kind kind;
  final int seconds;
  final Exercise exercise;
  final int setNumber;
  final int totalSets;
  final int exerciseIndex;
  final int totalExercises;

  const _Segment({
    required this.kind,
    required this.seconds,
    required this.exercise,
    required this.setNumber,
    required this.totalSets,
    required this.exerciseIndex,
    required this.totalExercises,
  });
}

class WorkoutPlayerScreen extends ConsumerStatefulWidget {
  const WorkoutPlayerScreen({super.key, required this.day});

  final WorkoutDay day;

  @override
  ConsumerState<WorkoutPlayerScreen> createState() =>
      _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends ConsumerState<WorkoutPlayerScreen> {
  static const int _workSeconds = 45;

  final List<_Segment> _segments = [];
  Timer? _timer;
  int _index = 0;
  int _secondsLeft = 0;
  bool _paused = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _buildSegments();
    if (_segments.isEmpty) {
      _done = true;
    } else {
      _startSegment(0);
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  void _buildSegments() {
    final exercises = widget.day.exercises;
    for (var ei = 0; ei < exercises.length; ei++) {
      final ex = exercises[ei];
      final sets = ex.sets <= 0 ? 1 : ex.sets;
      final rest = ex.restSeconds <= 0 ? 30 : ex.restSeconds;
      for (var s = 1; s <= sets; s++) {
        _segments.add(_Segment(
          kind: _Kind.work,
          seconds: _workSeconds,
          exercise: ex,
          setNumber: s,
          totalSets: sets,
          exerciseIndex: ei,
          totalExercises: exercises.length,
        ));
        final isVeryLast = ei == exercises.length - 1 && s == sets;
        if (!isVeryLast) {
          _segments.add(_Segment(
            kind: _Kind.rest,
            seconds: rest,
            exercise: ex,
            setNumber: s,
            totalSets: sets,
            exerciseIndex: ei,
            totalExercises: exercises.length,
          ));
        }
      }
    }
  }

  void _startSegment(int i) {
    final seg = _segments[i];
    setState(() {
      _index = i;
      _secondsLeft = seg.seconds;
    });
    if (seg.kind == _Kind.work) {
      TtsService.instance.speak(
        'Set ${seg.setNumber} of ${seg.totalSets}. '
        '${seg.exercise.name}. ${seg.exercise.reps} reps.',
      );
    } else {
      TtsService.instance.speak('Nice work. Rest for ${seg.seconds} seconds.');
    }
  }

  void _tick(Timer t) {
    if (_paused || _done) return;
    if (_secondsLeft > 1) {
      setState(() => _secondsLeft--);
    } else {
      _advance();
    }
  }

  void _advance() {
    if (_index < _segments.length - 1) {
      _startSegment(_index + 1);
    } else {
      _finish();
    }
  }

  void _previous() {
    if (_index > 0) _startSegment(_index - 1);
  }

  void _finish() {
    _timer?.cancel();
    setState(() => _done = true);
    // Record completion so the dashboard streak / week ticks update.
    ref.read(dailyProvider.notifier).markWorkoutDone();
    TtsService.instance.speak('Great job! Workout complete.');
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) TtsService.instance.stop();
  }

  /// The next work segment after [_index] (for the "Up next" rest preview).
  _Segment? _nextWork() {
    for (var i = _index + 1; i < _segments.length; i++) {
      if (_segments[i].kind == _Kind.work) return _segments[i];
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _CompletionView(day: widget.day);

    final seg = _segments[_index];
    final isWork = seg.kind == _Kind.work;
    final accent = isWork ? AppTheme.sageLight : const Color(0xFF6FA8DC);
    final progress = seg.seconds == 0 ? 0.0 : _secondsLeft / seg.seconds;
    final next = _nextWork();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(focus: widget.day.focus),
            // Overall workout progress.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_index + 1) / _segments.length,
                  minHeight: 6,
                  backgroundColor: AppTheme.darkSurfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
            // Hero: the demo (work) or the "up next" preview (rest).
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: isWork
                    ? _WorkHero(seg: seg, accent: accent)
                    : _RestHero(next: next, accent: accent),
              ),
            ),
            // Exercise name + set/reps.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Column(
                children: [
                  Text(
                    isWork
                        ? seg.exercise.name
                        : (next != null ? 'Up next' : 'Final stretch'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isWork
                        ? 'Set ${seg.setNumber} of ${seg.totalSets}  ·  '
                            '${seg.exercise.reps} reps'
                        : (next != null
                            ? next.exercise.name
                            : 'Last rest — finish strong'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _TimerRing(
              secondsLeft: _secondsLeft,
              progress: progress,
              accent: accent,
              label: isWork ? 'WORK' : 'REST',
            ),
            const SizedBox(height: 14),
            _Controls(
              paused: _paused,
              accent: accent,
              onPrev: _index > 0 ? _previous : null,
              onPause: _togglePause,
              onSkip: _advance,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.focus});
  final String focus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              focus,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: TtsService.instance.enabled,
            builder: (context, on, _) => IconButton(
              tooltip: on ? 'Mute voice' : 'Unmute voice',
              icon: Icon(
                on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: Colors.white70,
              ),
              onPressed: TtsService.instance.toggle,
            ),
          ),
        ],
      ),
    );
  }
}

/// The working-set hero: a big demo GIF with overlaid phase + counter badges.
class _WorkHero extends StatelessWidget {
  const _WorkHero({required this.seg, required this.accent});
  final _Segment seg;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Full-bleed 16:9 demo, fit to whatever space the hero has.
        var w = c.maxWidth;
        var h = w * 9 / 16;
        if (h > c.maxHeight) {
          h = c.maxHeight;
          w = h * 16 / 9;
        }
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                ExerciseDemo(name: seg.exercise.name, size: w, height: h),
                Positioned(
                  left: 16,
                  top: 16,
                  child: _Badge(text: 'WORK', color: accent, filled: true),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: _Badge(
                    text: '${seg.exerciseIndex + 1}/${seg.totalExercises}',
                    color: Colors.white,
                    filled: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The rest hero: shows what's coming up next with a small demo.
class _RestHero extends StatelessWidget {
  const _RestHero({required this.next, required this.accent});
  final _Segment? next;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.darkSurfaceAlt, width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bedtime_rounded, color: accent, size: 34),
            const SizedBox(height: 10),
            const Text(
              'Catch your breath',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 18),
              ExerciseDemo(name: next!.exercise.name, size: 200, height: 112),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, required this.filled});
  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? color : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? AppTheme.darkBg : color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({
    required this.secondsLeft,
    required this.progress,
    required this.accent,
    required this.label,
  });

  final int secondsLeft;
  final double progress;
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: progress, end: progress),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 9,
                backgroundColor: AppTheme.darkSurfaceAlt,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$secondsLeft',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.paused,
    required this.accent,
    required this.onPause,
    required this.onSkip,
    this.onPrev,
  });

  final bool paused;
  final Color accent;
  final VoidCallback onPause;
  final VoidCallback onSkip;
  final VoidCallback? onPrev;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circleButton(
            icon: Icons.skip_previous_rounded,
            onTap: onPrev,
            color: AppTheme.darkSurface,
            iconColor: Colors.white,
          ),
          _circleButton(
            icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            onTap: onPause,
            color: accent,
            iconColor: AppTheme.darkBg,
            big: true,
          ),
          _circleButton(
            icon: Icons.skip_next_rounded,
            onTap: onSkip,
            color: AppTheme.darkSurface,
            iconColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
    required Color iconColor,
    bool big = false,
  }) {
    final size = big ? 76.0 : 58.0;
    return Material(
      color: onTap == null ? color.withValues(alpha: 0.5) : color,
      shape: const CircleBorder(),
      elevation: big ? 4 : 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: big ? 40 : 26),
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.day});
  final WorkoutDay day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.sage.withValues(alpha: 0.18),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 64, color: AppTheme.sageLight),
              ),
              const SizedBox(height: 24),
              const Text(
                'Workout complete!',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nice work finishing ${day.focus}. '
                'Recovery is where the progress happens.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, height: 1.4),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.sage,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
