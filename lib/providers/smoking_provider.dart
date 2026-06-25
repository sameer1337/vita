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
}

final smokingProvider =
    NotifierProvider<SmokingNotifier, SmokingProfile>(SmokingNotifier.new);
