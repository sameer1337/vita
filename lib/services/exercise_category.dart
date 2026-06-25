import 'package:flutter/material.dart';

/// Broad movement families we can show a relevant animated demo for.
enum ExerciseCategory { strength, lowerBody, core, cardio, mobility }

/// Maps an (often AI-generated) exercise name to a movement category, and
/// exposes the icon / colour / label used by the animated demo. Keyword order
/// matters: the first family with a hit wins, so the more specific families
/// (mobility, core, cardio, lower body) are checked before generic strength.
class ExerciseCategoryInfo {
  const ExerciseCategoryInfo({
    required this.category,
    required this.icon,
    required this.color,
    required this.label,
  });

  final ExerciseCategory category;
  final IconData icon;
  final Color color;
  final String label;

  static const Map<ExerciseCategory, ExerciseCategoryInfo> _info = {
    ExerciseCategory.strength: ExerciseCategoryInfo(
      category: ExerciseCategory.strength,
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF6B9080),
      label: 'Strength',
    ),
    ExerciseCategory.lowerBody: ExerciseCategoryInfo(
      category: ExerciseCategory.lowerBody,
      icon: Icons.airline_seat_legroom_extra_rounded,
      color: Color(0xFF5B8DB8),
      label: 'Lower body',
    ),
    ExerciseCategory.core: ExerciseCategoryInfo(
      category: ExerciseCategory.core,
      icon: Icons.airline_seat_flat_rounded,
      color: Color(0xFFE39A53),
      label: 'Core',
    ),
    ExerciseCategory.cardio: ExerciseCategoryInfo(
      category: ExerciseCategory.cardio,
      icon: Icons.directions_run_rounded,
      color: Color(0xFFE0566E),
      label: 'Cardio',
    ),
    ExerciseCategory.mobility: ExerciseCategoryInfo(
      category: ExerciseCategory.mobility,
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF7E6CC4),
      label: 'Mobility',
    ),
  };

  // Keyword tables, checked in this order.
  static const List<MapEntry<ExerciseCategory, List<String>>> _keywords = [
    MapEntry(ExerciseCategory.mobility, [
      'stretch', 'yoga', 'mobility', 'cobra', 'child', 'cat cow', 'cat-cow',
      'downward', 'pigeon', 'foam', 'rotation', 'circle', 'reach', 'fold',
      'warm up', 'warm-up', 'cooldown', 'cool down', 'hamstring stretch',
    ]),
    MapEntry(ExerciseCategory.cardio, [
      'run', 'jog', 'sprint', 'jump', 'jack', 'burpee', 'skater', 'high knee',
      'mountain climber', 'cardio', 'skip', 'shuffle', 'box step', 'march',
      'butt kick', 'jumping',
    ]),
    MapEntry(ExerciseCategory.core, [
      'plank', 'crunch', 'sit up', 'sit-up', 'situp', 'abs', 'core', 'twist',
      'leg raise', 'russian', 'hollow', 'dead bug', 'bicycle', 'bird dog',
      'flutter kick', 'v-up', 'v up', 'toe touch', 'oblique',
    ]),
    MapEntry(ExerciseCategory.lowerBody, [
      'squat', 'lunge', 'glute', 'calf', 'leg press', 'hip thrust', 'bridge',
      'step up', 'step-up', 'deadlift', 'wall sit', 'hamstring curl',
      'leg extension', 'leg curl', 'kickback',
    ]),
    MapEntry(ExerciseCategory.strength, [
      'press', 'curl', 'row', 'push up', 'push-up', 'pushup', 'pull up',
      'pull-up', 'pullup', 'fly', 'raise', 'extension', 'bench', 'dip',
      'shoulder', 'chest', 'back', 'bicep', 'tricep', 'lat', 'shrug',
    ]),
  ];

  /// Classify an exercise name. Defaults to [ExerciseCategory.strength].
  static ExerciseCategoryInfo of(String exerciseName) {
    final name = exerciseName.toLowerCase();
    for (final entry in _keywords) {
      for (final kw in entry.value) {
        if (name.contains(kw)) return _info[entry.key]!;
      }
    }
    return _info[ExerciseCategory.strength]!;
  }

  static ExerciseCategoryInfo get fallback => _info[ExerciseCategory.strength]!;
}

/// Convenience accessor used by the calmer "rest" colour scheme.
const Color kRestAccent = Color(0xFF5B8DB8);
