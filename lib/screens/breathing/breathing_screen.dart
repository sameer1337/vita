import 'package:flutter/material.dart';

import '../../models/breathing_pattern.dart';
import '../../theme/app_theme.dart';
import 'breathing_player_screen.dart';

/// Lists the guided breathing techniques and opens the player for each.
class BreathingScreen extends StatelessWidget {
  const BreathingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Breathing'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'A few minutes of guided breathing to calm your mind, steady your '
              'focus, or wind down for sleep. Pick a technique to begin.',
              style: TextStyle(color: Colors.white60, height: 1.45),
            ),
            const SizedBox(height: 20),
            for (final p in BreathingPattern.all) ...[
              _PatternCard(pattern: p),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.pattern});
  final BreathingPattern pattern;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BreathingPlayerScreen(pattern: pattern),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: pattern.color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    pattern.color.withValues(alpha: 0.8),
                    pattern.color.withValues(alpha: 0.3),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(pattern.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(pattern.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: pattern.color.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(pattern.subtitle,
                            style: TextStyle(
                                color: pattern.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(pattern.benefit,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13, height: 1.35)),
                  const SizedBox(height: 4),
                  Text('${pattern.totalDuration} min · tap to start',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
