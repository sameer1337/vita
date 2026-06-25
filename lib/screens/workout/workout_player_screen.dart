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
    final accent = isWork ? AppTheme.sage : const Color(0xFF5B8DB8);
    final progress = seg.seconds == 0 ? 0.0 : _secondsLeft / seg.seconds;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.day.focus),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: TtsService.instance.enabled,
            builder: (context, on, _) => IconButton(
              tooltip: on ? 'Mute voice' : 'Unmute voice',
              icon: Icon(
                  on ? Icons.volume_up_rounded : Icons.volume_off_rounded),
              onPressed: () => setState(TtsService.instance.toggle),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_index + 1) / _segments.length,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8E5),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _PhaseChip(isWork: isWork, accent: accent),
                      const SizedBox(height: 16),
                      Text(
                        'Exercise ${seg.exerciseIndex + 1} of '
                        '${seg.totalExercises}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      ExerciseDemo(name: seg.exercise.name),
                      const SizedBox(height: 20),
                      Text(
                        seg.exercise.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.deepSage,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isWork
                            ? 'Set ${seg.setNumber} of ${seg.totalSets}  ·  '
                                '${seg.exercise.reps} reps'
                            : 'Rest before set ${_nextSetLabel(seg)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _TimerRing(
                        secondsLeft: _secondsLeft,
                        progress: progress,
                        accent: accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

  String _nextSetLabel(_Segment seg) {
    if (seg.setNumber < seg.totalSets) return '${seg.setNumber + 1}';
    return '1 of the next exercise';
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.isWork, required this.accent});
  final bool isWork;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isWork ? 'WORK' : 'REST',
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
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
  });

  final int secondsLeft;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: progress, end: progress),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 12,
                backgroundColor: const Color(0xFFE9EEEC),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$secondsLeft',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.deepSage,
                ),
              ),
              const Text('seconds', style: TextStyle(color: Colors.black45)),
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circleButton(
            icon: Icons.skip_previous_rounded,
            onTap: onPrev,
            color: Colors.white,
            iconColor: AppTheme.deepSage,
          ),
          _circleButton(
            icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            onTap: onPause,
            color: accent,
            iconColor: Colors.white,
            big: true,
          ),
          _circleButton(
            icon: Icons.skip_next_rounded,
            onTap: onSkip,
            color: Colors.white,
            iconColor: AppTheme.deepSage,
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
    final size = big ? 76.0 : 60.0;
    return Material(
      color: onTap == null ? color.withValues(alpha: 0.5) : color,
      shape: const CircleBorder(),
      elevation: big ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: big ? 40 : 28),
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
                  color: AppTheme.sage.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 64, color: AppTheme.sage),
              ),
              const SizedBox(height: 24),
              Text(
                'Workout complete!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.deepSage,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nice work finishing ${day.focus}. '
                'Recovery is where the progress happens.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4),
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
