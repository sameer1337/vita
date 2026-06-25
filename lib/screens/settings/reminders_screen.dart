import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/reminder_provider.dart';
import '../../theme/app_theme.dart';

/// Lets the user turn workout / hydration / quit-smoking reminders on or off
/// and choose when they fire. Changes are persisted and re-scheduled instantly.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(reminderProvider);
    final notifier = ref.read(reminderProvider.notifier);

    Future<void> pickTime(int hour, int minute, void Function(TimeOfDay) set) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: hour, minute: minute),
      );
      if (picked != null) set(picked);
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Reminders'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Vita can nudge you at the right moments. Reminders run on your '
              'device — no internet needed.',
              style: TextStyle(color: Colors.white60, height: 1.4),
            ),
            const SizedBox(height: 20),
            _ReminderCard(
              emoji: '💪',
              title: 'Workout reminder',
              subtitle: 'A daily nudge at your workout time',
              enabled: s.workoutEnabled,
              onToggle: (v) => notifier.update(s.copyWith(workoutEnabled: v)),
              trailing: s.workoutEnabled
                  ? _TimeChip(
                      label: _fmt(context, s.workoutHour, s.workoutMinute),
                      onTap: () => pickTime(
                        s.workoutHour,
                        s.workoutMinute,
                        (t) => notifier.update(s.copyWith(
                            workoutHour: t.hour, workoutMinute: t.minute)),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            _ReminderCard(
              emoji: '💧',
              title: 'Hydration reminders',
              subtitle: 'Spread evenly through your day (09:00–21:00)',
              enabled: s.waterEnabled,
              onToggle: (v) => notifier.update(s.copyWith(waterEnabled: v)),
              trailing: s.waterEnabled
                  ? _CountStepper(
                      value: s.waterTimesPerDay,
                      onChanged: (v) =>
                          notifier.update(s.copyWith(waterTimesPerDay: v)),
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            _ReminderCard(
              emoji: '🚭',
              title: 'Quit-smoking check-in',
              subtitle: 'A daily moment to log and reflect',
              enabled: s.smokingEnabled,
              onToggle: (v) => notifier.update(s.copyWith(smokingEnabled: v)),
              trailing: s.smokingEnabled
                  ? _TimeChip(
                      label: _fmt(context, s.smokingHour, s.smokingMinute),
                      onTap: () => pickTime(
                        s.smokingHour,
                        s.smokingMinute,
                        (t) => notifier.update(s.copyWith(
                            smokingHour: t.hour, smokingMinute: t.minute)),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            const Text(
              'Tip: if reminders don’t arrive, allow notifications for Vita in '
              'your phone’s settings.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(BuildContext context, int h, int m) =>
      TimeOfDay(hour: h, minute: m).format(context);
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    this.trailing,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? AppTheme.sage.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12, height: 1.3)),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.sage,
              ),
            ],
          ),
          if (trailing != null) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: trailing!),
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.darkSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded,
                size: 16, color: AppTheme.sageLight),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, color: Colors.white70, size: 18),
          ),
          Text('$value× a day',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value < 12 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }
}
