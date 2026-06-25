import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'local_store.dart';

/// Streams today's step count from the device's hardware step counter.
///
/// The sensor reports steps cumulative since boot, so we store a per-day
/// baseline and report `current - baseline`. Only works on a physical device
/// or an emulator with sensors — never on web/desktop, where the stream errors
/// and we simply emit nothing.
class StepService {
  StepService._();

  /// Emits the running step total for today. Completes silently (no events)
  /// if permission is denied or the sensor is unavailable.
  static Stream<int> todaySteps() async* {
    // ACTIVITY_RECOGNITION is required on Android 10+.
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) return;

    final store = LocalStore.cached;
    final date = LocalStore.dateKey(DateTime.now());
    final baselineKey = 'vita.steps.baseline.$date';

    await for (final event in Pedometer.stepCountStream) {
      final cumulative = event.steps;
      var baseline = store.getInt(baselineKey);

      // First reading today, or a device reboot reset the counter below our
      // baseline — (re)anchor to the current cumulative value.
      if (baseline == null || cumulative < baseline) {
        baseline = cumulative;
        await store.setInt(baselineKey, baseline);
      }

      yield (cumulative - baseline).clamp(0, 1000000);
    }
  }
}
