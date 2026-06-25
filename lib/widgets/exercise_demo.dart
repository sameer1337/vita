import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/exercise_category.dart';
import '../theme/app_theme.dart';

/// A fully-offline animated exercise demo: a little figure performing a
/// rep-style movement (squat → reach), tinted by the movement family and
/// paced faster for cardio. Always renders, never fails, costs nothing.
class ExerciseDemo extends StatefulWidget {
  const ExerciseDemo({super.key, required this.name, this.size = 220});

  final String name;
  final double size;

  @override
  State<ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<ExerciseDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ExerciseCategoryInfo _info;

  @override
  void initState() {
    super.initState();
    _info = ExerciseCategoryInfo.of(widget.name);
    _controller = AnimationController(vsync: this, duration: _durationFor(_info))
      ..repeat();
  }

  Duration _durationFor(ExerciseCategoryInfo info) {
    // Cardio reps are quick; everything else is a steady, controlled tempo.
    return Duration(
        milliseconds:
            info.category == ExerciseCategory.cardio ? 900 : 1500);
  }

  @override
  void didUpdateWidget(covariant ExerciseDemo old) {
    super.didUpdateWidget(old);
    if (old.name != widget.name) {
      _info = ExerciseCategoryInfo.of(widget.name);
      _controller.duration = _durationFor(_info);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _info.color.withValues(alpha: 0.20),
                    _info.color.withValues(alpha: 0.06),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: Size.square(widget.size),
                painter: _FigurePainter(
                  t: _controller.value,
                  category: _info.category,
                  color: _info.color,
                ),
              ),
            ),
            // Family label chip.
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_info.icon, size: 13, color: _info.color),
                      const SizedBox(width: 5),
                      Text(
                        _info.label,
                        style: const TextStyle(
                          color: AppTheme.deepSage,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
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

/// Draws an animated stick figure performing a rep, with the motion style
/// chosen by movement family.
class _FigurePainter extends CustomPainter {
  _FigurePainter({
    required this.t,
    required this.category,
    required this.color,
  });

  final double t; // 0..1, looping
  final ExerciseCategory category;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = size.shortestSide;
    final cx = w / 2;

    // m: 0 at rest → 1 at peak → 0, smooth (one rep per loop).
    final m = (1 - math.cos(t * 2 * math.pi)) / 2;

    final limb = Paint()
      ..color = color
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = color;

    // Proportions.
    final thigh = s * 0.15;
    final shin = s * 0.15;
    final torsoLen = s * 0.20;
    final upperArm = s * 0.115;
    final foreArm = s * 0.105;
    final headR = s * 0.062;
    final shoulderW = s * 0.075;
    final hipW = s * 0.05;

    final footY = h * 0.80;

    // Per-family motion parameters.
    double legFold = 0; // how much the legs fold (squat depth) 0..1
    double armAngle = 0.15; // shoulder angle from vertical-down (rad), per side
    double elbow = 0.1; // elbow flex (rad)
    double legSpread = 0; // extra outward angle for legs (jumping jacks)
    double torsoLean = 0; // forward lean (rad)

    switch (category) {
      case ExerciseCategory.lowerBody:
        legFold = m; // deep squat
        armAngle = 0.2 + m * 0.5; // arms reach forward for balance
        break;
      case ExerciseCategory.strength:
        legFold = m * 0.12;
        elbow = 0.1 + m * 2.0; // bicep curl
        armAngle = 0.35;
        break;
      case ExerciseCategory.core:
        legFold = m * 0.25;
        torsoLean = m * 0.5; // crunch forward
        armAngle = 0.6 + m * 0.4;
        elbow = 0.6;
        break;
      case ExerciseCategory.cardio:
        legSpread = m * 0.5; // jumping jack: legs out + arms overhead
        armAngle = 0.2 + m * 2.6;
        break;
      case ExerciseCategory.mobility:
        armAngle = 0.2 + m * 2.7; // slow overhead reach
        torsoLean = math.sin(t * 2 * math.pi) * 0.12; // gentle sway
        break;
    }

    // Leg length shrinks as legs fold (squat lowers the hip).
    final legReach = (thigh + shin) * (1 - 0.34 * legFold);
    final hipCenter = Offset(cx, footY - legReach);
    final neck = Offset(
      hipCenter.dx + math.sin(torsoLean) * torsoLen,
      hipCenter.dy - math.cos(torsoLean) * torsoLen,
    );

    // --- Legs ---
    for (final sign in [-1.0, 1.0]) {
      final foot = Offset(cx + sign * (hipW + legSpread * s * 0.18), footY);
      final hip = Offset(hipCenter.dx + sign * hipW, hipCenter.dy);
      // Knee: midpoint pushed outward/forward when folding.
      final mid = Offset.lerp(hip, foot, 0.5)!;
      final knee = mid.translate(sign * legFold * s * 0.07, -legFold * s * 0.02);
      canvas.drawLine(hip, knee, limb);
      canvas.drawLine(knee, foot, limb);
    }

    // --- Torso ---
    canvas.drawLine(hipCenter, neck, limb);

    // --- Arms ---
    // Shoulder angle a: 0 = hanging down, π/2 = straight out, π = overhead.
    for (final sign in [-1.0, 1.0]) {
      final shoulder = Offset(neck.dx + sign * shoulderW, neck.dy + s * 0.01);
      final a = armAngle;
      final ux = sign * math.sin(a);
      final uy = math.cos(a); // a=0 → down, a=π → up
      final elbowPt =
          Offset(shoulder.dx + ux * upperArm, shoulder.dy + uy * upperArm);
      // Forearm flexes by `elbow` (curl toward the shoulder).
      final fx = sign * math.sin(a - elbow);
      final fy = math.cos(a - elbow);
      final handPt =
          Offset(elbowPt.dx + fx * foreArm, elbowPt.dy + fy * foreArm);
      canvas.drawLine(shoulder, elbowPt, limb);
      canvas.drawLine(elbowPt, handPt, limb);
    }

    // --- Head ---
    final head = Offset(neck.dx, neck.dy - headR - s * 0.015);
    canvas.drawCircle(head, headR, fill);

    // --- Ground line + soft shadow ---
    final ground = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(cx - s * 0.22, footY + s * 0.02),
        Offset(cx + s * 0.22, footY + s * 0.02),
        ground);
    final shadow = Paint()..color = color.withValues(alpha: 0.12);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, footY + s * 0.03),
          width: s * (0.30 - 0.06 * m),
          height: s * 0.05),
      shadow,
    );
  }

  @override
  bool shouldRepaint(covariant _FigurePainter old) =>
      old.t != t || old.category != category || old.color != color;
}
