import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan.dart';
import '../providers/reminder_provider.dart';
import '../services/local_store.dart';
import 'home/home_shell.dart';
import 'onboarding/onboarding_flow.dart';

/// Decides the first screen on launch: returning users (with a saved plan) go
/// straight to the home experience; new users start onboarding.
class VitaRoot extends ConsumerStatefulWidget {
  const VitaRoot({super.key});

  @override
  ConsumerState<VitaRoot> createState() => _VitaRootState();
}

class _VitaRootState extends ConsumerState<VitaRoot> {
  WellnessPlan? _plan;

  @override
  void initState() {
    super.initState();
    _plan = LocalStore.cached.loadPlan();
    // Re-apply scheduled reminders so they survive app reinstalls / clears.
    if (_plan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(reminderProvider.notifier).apply();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return plan != null ? HomeShell(plan: plan) : const OnboardingFlow();
  }
}
