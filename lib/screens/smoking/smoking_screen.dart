import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/daily_provider.dart';
import '../../providers/smoking_provider.dart';
import '../../services/local_store.dart';
import '../../theme/app_theme.dart';

/// Full quit-smoking tracker: today's count vs the taper limit, one-tap
/// logging, gentle warnings when over, money saved vs the old baseline, and a
/// control to lower the daily allowance.
class SmokingScreen extends ConsumerWidget {
  const SmokingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyProvider);
    final profile = ref.watch(smokingProvider);
    final today = daily.cigarettes;
    final limit = profile.dailyLimit;
    final over = today > limit;
    final saved = (profile.baselinePerDay - today).clamp(0, 1000) *
        profile.pricePerCig;

    final accent = over ? const Color(0xFFE0566E) : AppTheme.sage;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Quit smoking'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Today's count vs limit.
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent.withValues(alpha: 0.9), accent.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text('TODAY',
                      style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('$today',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          height: 1)),
                  Text('of $limit cigarette${limit == 1 ? '' : 's'} allowed',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: limit == 0 ? (today > 0 ? 1 : 0) : (today / limit).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Status message.
            _StatusCard(today: today, limit: limit, over: over),
            const SizedBox(height: 16),
            // Log + undo.
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () =>
                        ref.read(dailyProvider.notifier).logCigarette(),
                    icon: const Icon(Icons.smoking_rooms_rounded),
                    label: const Text('I smoked one'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: today > 0
                      ? () => ref.read(dailyProvider.notifier).removeCigarette()
                      : null,
                  icon: const Icon(Icons.undo_rounded, color: Colors.white70),
                  tooltip: 'Undo',
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Money saved + baseline.
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Saved today',
                    value:
                        '${profile.currency}${saved.toStringAsFixed(saved >= 10 ? 0 : 2)}',
                    icon: Icons.savings_rounded,
                    color: const Color(0xFF6BA368),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Old daily avg',
                    value: '${profile.baselinePerDay}',
                    icon: Icons.history_rounded,
                    color: const Color(0xFF5B8DB8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StreakBanner(
              days: ref.read(smokingProvider.notifier).daysUnderLimit(today),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Last 14 days'),
            const SizedBox(height: 8),
            _HistoryChart(
              counts: _last14Days(LocalStore.cached.cigarettesByDate(), today),
              limit: limit,
            ),
            const SizedBox(height: 24),
            _SectionTitle('Your taper goal'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lower your daily limit a little each week. Slow, steady '
                    'cuts stick better than going cold turkey.',
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Daily limit',
                          style: TextStyle(color: Colors.white)),
                      const Spacer(),
                      IconButton(
                        onPressed: limit > 0
                            ? () => ref
                                .read(smokingProvider.notifier)
                                .setDailyLimit(limit - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.white70),
                      ),
                      Text('$limit',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      IconButton(
                        onPressed: () => ref
                            .read(smokingProvider.notifier)
                            .setDailyLimit(limit + 1),
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Not medical advice. If you want structured support, a doctor or '
              'a quitline can help with cravings and withdrawal.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small banner celebrating consecutive days at or under the daily limit.
class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final msg = days <= 0
        ? 'Stay at or under your limit today to start a streak.'
        : '$days day${days == 1 ? '' : 's'} at or under your limit — keep it going!';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.sage.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Text(days > 0 ? '🔥' : '🎯', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: const TextStyle(color: Colors.white, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

/// Build the last 14 days of cigarette counts (oldest→newest), substituting the
/// live [todayCount] for today so the chart updates as the user logs.
List<({String label, int count})> _last14Days(
    Map<String, int> byDate, int todayCount) {
  final out = <({String label, int count})>[];
  final now = DateTime.now();
  for (var i = 13; i >= 0; i--) {
    final d = now.subtract(Duration(days: i));
    final count = i == 0 ? todayCount : (byDate[LocalStore.dateKey(d)] ?? 0);
    out.add((label: '${d.day}', count: count));
  }
  return out;
}

/// A small bar chart of recent daily cigarette counts, with the taper limit
/// drawn as a reference line. Bars over the limit turn red.
class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.counts, required this.limit});

  final List<({String label, int count})> counts;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final maxCount =
        counts.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    final maxY = (maxCount > limit ? maxCount : limit).toDouble() + 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
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
                    if (i < 0 || i >= counts.length || i % 3 != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(counts[i].label,
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
                  y: limit.toDouble(),
                  color: const Color(0xFFE7B07A),
                  strokeWidth: 1.5,
                  dashArray: [6, 4],
                ),
              ],
            ),
            barGroups: [
              for (var i = 0; i < counts.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: counts[i].count.toDouble(),
                      width: 9,
                      borderRadius: BorderRadius.circular(3),
                      color: counts[i].count > limit
                          ? const Color(0xFFE0566E)
                          : AppTheme.sage,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.today, required this.limit, required this.over});
  final int today;
  final int limit;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final String msg;
    final String emoji;
    if (today == 0) {
      emoji = '🌱';
      msg = "Smoke-free so far today — every hour without one is a win.";
    } else if (over) {
      emoji = '⚠️';
      msg = "You've had $today today — that's over your limit of $limit. "
          "Try to ride out the next craving; it usually passes in a few minutes.";
    } else if (today == limit) {
      emoji = '✋';
      msg = "You've hit today's limit of $limit. Aim to make this the last one.";
    } else {
      emoji = '💪';
      msg = "$today today — still under your limit of $limit. Keep stretching "
          "the gap between cigarettes.";
    }
    final color = over
        ? const Color(0xFFE0566E)
        : (today == 0 ? const Color(0xFF6BA368) : AppTheme.sage);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: const TextStyle(color: Colors.white, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800));
}
