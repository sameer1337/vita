import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan.dart';
import '../providers/reminder_provider.dart';
import '../services/local_store.dart';
import 'home/home_shell.dart';
import 'onboarding/intro_carousel.dart';
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
  bool _introSeen = true;

  @override
  void initState() {
    super.initState();
    _plan = LocalStore.cached.loadPlan();
    _introSeen = LocalStore.cached.introSeen;
    // Re-apply scheduled reminders so they survive app reinstalls / clears.
    if (_plan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(reminderProvider.notifier).apply();
      });
    }
  }

  void _finishIntro() {
    LocalStore.cached.setIntroSeen(true);
    setState(() => _introSeen = true);
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    if (plan != null) return HomeShell(plan: plan);
    // First launch: show the walkthrough once, then onboarding.
    if (!_introSeen) return IntroCarousel(onDone: _finishIntro);
    return const OnboardingFlow();
  }
}
