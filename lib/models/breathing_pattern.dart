import 'package:flutter/material.dart';

/// One phase within a breathing cycle.
enum BreathPhaseType { inhale, hold, exhale }

class BreathPhase {
  const BreathPhase(this.type, this.seconds);
  final BreathPhaseType type;
  final int seconds;

  String get label => switch (type) {
        BreathPhaseType.inhale => 'Breathe in',
        BreathPhaseType.hold => 'Hold',
        BreathPhaseType.exhale => 'Breathe out',
      };
}

/// A guided breathing technique — a repeating sequence of phases.
class BreathingPattern {
  const BreathingPattern({
    required this.name,
    required this.subtitle,
    required this.benefit,
    required this.emoji,
    required this.color,
    required this.phases,
    required this.cycles,
  });

  final String name;
  final String subtitle;
  final String benefit;
  final String emoji;
  final Color color;
  final List<BreathPhase> phases;
  final int cycles;

  /// Seconds in one full cycle.
  int get cycleSeconds => phases.fold(0, (s, p) => s + p.seconds);

  /// Total session length, formatted as "m:ss".
  String get totalDuration {
    final total = cycleSeconds * cycles;
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static const List<BreathingPattern> all = [
    BreathingPattern(
      name: 'Box breathing',
      subtitle: '4 · 4 · 4 · 4',
      benefit: 'Steadies focus and calms the nervous system',
      emoji: '🧊',
      color: Color(0xFF5B8DB8),
      cycles: 6,
      phases: [
        BreathPhase(BreathPhaseType.inhale, 4),
        BreathPhase(BreathPhaseType.hold, 4),
        BreathPhase(BreathPhaseType.exhale, 4),
        BreathPhase(BreathPhaseType.hold, 4),
      ],
    ),
    BreathingPattern(
      name: '4-7-8 relaxing',
      subtitle: '4 · 7 · 8',
      benefit: 'Eases anxiety and helps you fall asleep',
      emoji: '🌙',
      color: Color(0xFF7E6CC4),
      cycles: 4,
      phases: [
        BreathPhase(BreathPhaseType.inhale, 4),
        BreathPhase(BreathPhaseType.hold, 7),
        BreathPhase(BreathPhaseType.exhale, 8),
      ],
    ),
    BreathingPattern(
      name: 'Coherent breathing',
      subtitle: '5 · 5',
      benefit: 'Balances heart rate and reduces stress',
      emoji: '🌊',
      color: Color(0xFF6B9080),
      cycles: 12,
      phases: [
        BreathPhase(BreathPhaseType.inhale, 5),
        BreathPhase(BreathPhaseType.exhale, 5),
      ],
    ),
    BreathingPattern(
      name: 'Deep belly',
      subtitle: '4 · 6',
      benefit: 'Longer exhales switch on “rest and digest”',
      emoji: '🌿',
      color: Color(0xFF6BA368),
      cycles: 8,
      phases: [
        BreathPhase(BreathPhaseType.inhale, 4),
        BreathPhase(BreathPhaseType.exhale, 6),
      ],
    ),
  ];
}
