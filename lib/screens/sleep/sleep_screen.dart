import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/daily_provider.dart';
import '../../services/local_store.dart';
import '../../theme/app_theme.dart';

/// Log last night's sleep (hours + quality) and see the past two weeks.
class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  static const double _idealHours = 8;

  late double _hours;
  late int _quality;

  @override
  void initState() {
    super.initState();
    final today = ref.read(dailyProvider);
    _hours = today.sleepHours > 0 ? today.sleepHours : 7.5;
    _quality = today.sleepQuality > 0 ? today.sleepQuality : 3;
  }

  void _save() {
    ref.read(dailyProvider.notifier).logSleep(_hours, _quality);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sleep logged 😴')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(dailyProvider);
    final history = _last14(LocalStore.cached.sleepByDate(), today.sleepHours);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
        title: const Text('Sleep'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            _card(
              'How did you sleep?',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hours',
                          style: TextStyle(color: Colors.white70)),
                      Text(
                        _hours.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppTheme.sageLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _hours,
                    min: 3,
                    max: 12,
                    divisions: 18,
                    activeColor: AppTheme.sage,
                    inactiveColor: AppTheme.darkSurfaceAlt,
                    label: _hours.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _hours = v),
                  ),
                  const SizedBox(height: 8),
                  const Text('Quality', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 1; i <= 5; i++)
                        _QualityDot(
                          emoji: _qualityEmoji(i),
                          selected: _quality == i,
                          onTap: () => setState(() => _quality = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.sage,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _save,
                      child: const Text('Save',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              'Last 2 weeks',
              _HistoryChart(hours: history, ideal: _idealHours),
            ),
            const SizedBox(height: 16),
            _TipCard(hours: today.sleepHours, quality: today.sleepQuality),
          ],
        ),
      ),
    );
  }

  static String _qualityEmoji(int q) =>
      const ['', '😣', '😕', '😐', '🙂', '😄'][q];

  Widget _card(String title, Widget child) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _QualityDot extends StatelessWidget {
  const _QualityDot(
      {required this.emoji, required this.selected, required this.onTap});
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? AppTheme.sage.withValues(alpha: 0.30)
              : AppTheme.darkSurfaceAlt,
          border: Border.all(
            color: selected ? AppTheme.sageLight : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

List<({String label, double hours})> _last14(
    Map<String, double> byDate, double todayHours) {
  final out = <({String label, double hours})>[];
  final now = DateTime.now();
  for (var i = 13; i >= 0; i--) {
    final d = now.subtract(Duration(days: i));
    final h = i == 0 ? todayHours : (byDate[LocalStore.dateKey(d)] ?? 0);
    out.add((label: '${d.day}', hours: h));
  }
  return out;
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.hours, required this.ideal});

  final List<({String label, double hours})> hours;
  final double ideal;

  @override
  Widget build(BuildContext context) {
    final maxH = hours.fold<double>(0, (m, e) => e.hours > m ? e.hours : m);
    final maxY = (maxH > ideal ? maxH : ideal) + 1.5;

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= hours.length || i % 3 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(hours[i].label,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: ideal,
                color: AppTheme.sageLight,
                strokeWidth: 1.5,
                dashArray: [6, 4],
              ),
            ],
          ),
          barGroups: [
            for (var i = 0; i < hours.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: hours[i].hours,
                    width: 9,
                    borderRadius: BorderRadius.circular(3),
                    color: hours[i].hours >= ideal - 1
                        ? AppTheme.sage
                        : const Color(0xFF6FA8DC),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.hours, required this.quality});
  final double hours;
  final int quality;

  @override
  Widget build(BuildContext context) {
    final String msg;
    if (hours == 0) {
      msg = 'Log last night to start tracking your sleep. Aim for 7–9 hours '
          'for recovery and a steadier mood.';
    } else if (hours < 6) {
      msg = "That's on the short side. Try winding down 30 minutes earlier "
          'tonight and keeping screens out of bed.';
    } else if (hours > 9.5) {
      msg = 'Plenty of rest. If you still feel groggy, consistent wake-up '
          'times help more than extra hours.';
    } else if (quality > 0 && quality <= 2) {
      msg = 'Decent hours but restless quality — a cooler, darker room and '
          'less caffeine after midday can help.';
    } else {
      msg = 'Nice — that\'s a healthy night\'s sleep. Keeping a regular '
          'schedule is the biggest win for recovery.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: const TextStyle(color: Colors.white70, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
