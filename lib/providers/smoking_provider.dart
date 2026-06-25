import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/smoking_profile.dart';
import '../services/local_store.dart';

/// Persisted smoking setup (asked / smokes / wants-to-quit / taper target).
class SmokingNotifier extends Notifier<SmokingProfile> {
  late final LocalStore _store;

  @override
  SmokingProfile build() {
    _store = LocalStore.cached;
    return _store.loadSmokingProfile();
  }

  void _persist(SmokingProfile next) {
    state = next;
    _store.saveSmokingProfile(next);
  }

  /// Record the answer to the first-run "do you smoke?" prompt.
  void answer({
    required bool smokes,
    required bool wantsToQuit,
    int baselinePerDay = 10,
  }) {
    _persist(state.copyWith(
      asked: true,
      smokes: smokes,
      wantsToQuit: wantsToQuit,
      baselinePerDay: baselinePerDay,
      // Start the taper one below the baseline so day one already nudges down.
      dailyLimit: (baselinePerDay - 1).clamp(1, 100),
    ));
  }

  void setDailyLimit(int limit) =>
      _persist(state.copyWith(dailyLimit: limit.clamp(0, 100)));

  void setPricePerCig(double price) =>
      _persist(state.copyWith(pricePerCig: price));

  /// Re-open the prompt (e.g. from a settings action).
  void reset() => _persist(const SmokingProfile());

  /// Consecutive days (ending today, or yesterday if today isn't logged yet)
  /// where the user stayed at or under their daily limit. [todayCount] is the
  /// live count for today so the streak updates as they log.
  int daysUnderLimit(int todayCount) {
    final byDate = _store.cigarettesByDate();
    final limit = state.dailyLimit;
    var streak = 0;
    var cursor = DateTime.now();

    // Today only counts once it's within limit; if it's already over, the
    // streak is broken now. If today has no entry yet, start from yesterday.
    final todayKey = LocalStore.dateKey(cursor);
    final hasToday = byDate.containsKey(todayKey) || todayCount > 0;
    if (hasToday) {
      if (todayCount > limit) return 0;
      streak++;
    }
    cursor = cursor.subtract(const Duration(days: 1));

    while (true) {
      final key = LocalStore.dateKey(cursor);
      if (!byDate.containsKey(key)) break; // no data → stop counting
      if (byDate[key]! > limit) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

final smokingProvider =
    NotifierProvider<SmokingNotifier, SmokingProfile>(SmokingNotifier.new);
