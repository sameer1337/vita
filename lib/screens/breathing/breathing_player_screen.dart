import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/breathing_pattern.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';

/// A guided breathing session: an expanding/contracting orb paces the breath,
/// with a phase label, per-second countdown, cycle progress and optional voice.
class BreathingPlayerScreen extends StatefulWidget {
  const BreathingPlayerScreen({super.key, required this.pattern});

  final BreathingPattern pattern;

  @override
  State<BreathingPlayerScreen> createState() => _BreathingPlayerScreenState();
}

class _BreathingPlayerScreenState extends State<BreathingPlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale; // 0 = small, 1 = expanded
  bool _running = false;
  bool _done = false;
  int _cycle = 0;
  int _secondsLeft = 0;
  BreathPhase? _phase;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      lowerBound: 0.45,
      upperBound: 1.0,
      value: 0.45,
    );
  }

  @override
  void dispose() {
    _running = false;
    _scale.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _running = true;
      _done = false;
      _cycle = 0;
    });
    for (var c = 0; c < widget.pattern.cycles && _running; c++) {
      if (!mounted) return;
      setState(() => _cycle = c + 1);
      for (final phase in widget.pattern.phases) {
        if (!_running) break;
        await _runPhase(phase);
      }
    }
    if (_running && mounted) {
      setState(() {
        _running = false;
        _done = true;
        _phase = null;
      });
    }
  }

  Future<void> _runPhase(BreathPhase phase) async {
    if (!mounted) return;
    setState(() {
      _phase = phase;
      _secondsLeft = phase.seconds;
    });
    TtsService.instance.speak(phase.label);

    final duration = Duration(seconds: phase.seconds);
    if (phase.type == BreathPhaseType.inhale) {
      _scale.animateTo(1.0, duration: duration, curve: Curves.easeInOut);
    } else if (phase.type == BreathPhaseType.exhale) {
      _scale.animateTo(0.45, duration: duration, curve: Curves.easeInOut);
    }

    for (var s = phase.seconds; s > 0 && _running; s--) {
      if (!mounted) return;
      setState(() => _secondsLeft = s);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void _stop() {
    setState(() {
      _running = false;
      _phase = null;
    });
    _scale.animateTo(0.45, duration: const Duration(milliseconds: 600));
    TtsService.instance.stop();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pattern;
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(p.name),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: TtsService.instance.enabled,
            builder: (context, on, _) => IconButton(
              tooltip: on ? 'Mute voice' : 'Unmute voice',
              onPressed: TtsService.instance.toggle,
              icon: Icon(on
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Breathing orb.
            Expanded(
              flex: 6,
              child: Center(
                child: AnimatedBuilder(
                  animation: _scale,
                  builder: (context, _) {
                    final size = 130 + 150 * (_scale.value - 0.45) / 0.55;
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            p.color.withValues(alpha: 0.85),
                            p.color.withValues(alpha: 0.35),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: p.color.withValues(alpha: 0.45),
                            blurRadius: 50,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _phase?.label ??
                                (_done ? 'Done' : 'Ready'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_phase != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '$_secondsLeft',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // Progress + helper text.
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_running)
                    Text('Cycle $_cycle of ${p.cycles}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 15))
                  else if (_done)
                    Column(
                      children: [
                        const Text('🌿', style: TextStyle(fontSize: 34)),
                        const SizedBox(height: 8),
                        Text(
                          'Nicely done — ${p.cycles} cycles complete.',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        p.benefit,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 15, height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
            // Controls.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: _running
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _stop,
                        child: const Text('Stop'),
                      )
                    : FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: p.color,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _start,
                        child: Text(
                          _done ? 'Go again' : 'Begin',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
