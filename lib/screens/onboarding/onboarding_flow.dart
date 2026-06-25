import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/onboarding_options.dart';
import '../../constants/step_visuals.dart';
import '../../models/onboarding_draft.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/smoking_provider.dart';
import '../../services/api_service.dart';
import '../../services/local_store.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/labeled_slider.dart';
import '../../widgets/measurement_inputs.dart';
import '../../widgets/select_group.dart';
import '../home/home_shell.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  static const int _totalSteps = 21; // steps 0..20

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  final PageController _pageController = PageController();
  final TtsService _tts = TtsService.instance;
  int _index = 0;
  bool _submitting = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _allergiesCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _allergiesCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakStep(0));
  }

  @override
  void dispose() {
    _tts.stop();
    _pageController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _allergiesCtrl.dispose();
    super.dispose();
  }

  void _speakStep(int i) {
    final draft = ref.read(onboardingProvider);
    final text = i == 0
        ? "Welcome to Vita. Let's build a wellness plan that fits your life."
        : _stepTitle(i, draft);
    _tts.speak(text);
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_index < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_index > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _pickDob() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(onboardingProvider).dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Select your date of birth',
    );
    if (picked != null) {
      ref.read(onboardingProvider.notifier).setDob(picked);
    }
  }

  Future<void> _pickWorkoutTime() async {
    FocusScope.of(context).unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: ref.read(onboardingProvider).workoutTime ??
          const TimeOfDay(hour: 7, minute: 0),
      helpText: 'When do you want to work out?',
    );
    if (picked != null) {
      ref.read(onboardingProvider.notifier).setWorkoutTime(picked);
    }
  }

  Future<void> _savePlan() async {
    final draft = ref.read(onboardingProvider);
    _tts.stop();
    setState(() => _submitting = true);
    try {
      final plan = await ApiService().generatePlan(draft.toAnswers());

      // Persist the plan + profile locally so the app opens straight to the
      // home experience on the next launch instead of re-onboarding.
      final store = LocalStore.cached;
      await store.savePlan(plan);
      await store.saveProfile(draft);

      // Persist the smoking answer captured during onboarding so the quit
      // tracker is ready (and the dashboard first-run prompt is skipped).
      final wantsToQuit = draft.smokingChoice == 'quit';
      if (draft.smokingChoice != null) {
        ref.read(smokingProvider.notifier).answer(
              smokes: draft.smokingChoice != 'no',
              wantsToQuit: wantsToQuit,
              baselinePerDay: draft.cigarettesPerDay,
            );
      }

      // Schedule reminders: a workout nudge at the chosen time, gentle
      // hydration reminders on by default, and a quit check-in if they're
      // tapering. Users can tune all of these in Settings.
      final wt = draft.workoutTime;
      await ref.read(reminderProvider.notifier).update(
            ref.read(reminderProvider).copyWith(
                  workoutEnabled: wt != null,
                  workoutHour: wt?.hour ?? 7,
                  workoutMinute: wt?.minute ?? 0,
                  waterEnabled: true,
                  smokingEnabled: wantsToQuit,
                ),
          );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeShell(plan: plan)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate your plan: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final isLast = _index == _totalSteps - 1;
    final canContinue = _isStepValid(_index, draft);
    final visual = StepVisuals.of(_index);

    return Scaffold(
      body: _AnimatedBackground(
        color: visual.color,
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                index: _index,
                total: _totalSteps,
                accent: visual.color,
                onBack: _index > 0 ? _back : null,
                onToggleVoice: () {
                  _tts.toggle();
                  if (_tts.enabled.value) _speakStep(_index);
                },
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _totalSteps,
                      onPageChanged: (i) {
                        setState(() => _index = i);
                        _speakStep(i);
                      },
                      itemBuilder: (context, i) {
                        final v = StepVisuals.of(i);
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeIn(
                                key: ValueKey('hero_$i'),
                                child: _StepHero(emoji: v.emoji, color: v.color),
                              ),
                              const SizedBox(height: 20),
                              FadeIn(
                                key: ValueKey('title_$i'),
                                delay: const Duration(milliseconds: 60),
                                child: Text(
                                  _stepTitle(i, draft),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.deepSage,
                                      ),
                                ),
                              ),
                              if (_stepSubtitle(i) != null) ...[
                                const SizedBox(height: 8),
                                FadeIn(
                                  key: ValueKey('sub_$i'),
                                  delay: const Duration(milliseconds: 120),
                                  child: Text(
                                    _stepSubtitle(i)!,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _buildStep(i, draft),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              _BottomBar(
                label: isLast ? 'Save My Plan' : 'Continue',
                accent: visual.color,
                enabled: canContinue && !_submitting,
                loading: _submitting,
                onPressed: isLast ? _savePlan : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Step content -------------------------------------------------------

  Widget _buildStep(int i, OnboardingDraft draft) {
    final n = ref.read(onboardingProvider.notifier);
    switch (i) {
      case 0:
        return const _WelcomeStep();
      case 1:
        return _TextEntry(
          controller: _nameCtrl,
          hint: 'e.g. Alex Johnson',
          initial: draft.fullName,
          textCapitalization: TextCapitalization.words,
          onChanged: n.setFullName,
        );
      case 2:
        return _TextEntry(
          controller: _emailCtrl,
          hint: 'you@example.com',
          initial: draft.email,
          keyboardType: TextInputType.emailAddress,
          onChanged: n.setEmail,
        );
      case 3:
        return _DobPicker(dob: draft.dob, age: draft.age, onTap: _pickDob);
      case 4:
        return SingleSelectGroup(
          options: OnboardingOptions.goals,
          selected: draft.goal,
          onSelected: n.setGoal,
        );
      case 5:
        return SingleSelectGroup(
          options: OnboardingOptions.sexes,
          selected: draft.sex,
          onSelected: n.setSex,
        );
      case 6:
        return HeightInput(
          cm: draft.heightCm,
          imperial: draft.useImperialHeight,
          onCm: n.setHeightCm,
          onUnitChanged: n.setUseImperialHeight,
        );
      case 7:
        return WeightInput(
          kg: draft.weightKg,
          imperial: draft.useImperialWeight,
          onKg: n.setWeightKg,
          onUnitChanged: n.setUseImperialWeight,
        );
      case 8:
        return WeightInput(
          kg: draft.targetWeightKg,
          imperial: draft.useImperialWeight,
          onKg: n.setTargetWeightKg,
          onUnitChanged: n.setUseImperialWeight,
          hint: 'optional',
        );
      case 9:
        return SingleSelectGroup(
          options: OnboardingOptions.activityLevels,
          selected: draft.activityLevel,
          onSelected: n.setActivityLevel,
        );
      case 10:
        return MultiSelectGroup(
          options: OnboardingOptions.equipment,
          selected: draft.equipment,
          onToggle: n.toggleEquipment,
        );
      case 11:
        return _ChipNumberRow(
          values: const [1, 2, 3, 4, 5, 6, 7],
          selected: draft.daysPerWeek,
          accent: StepVisuals.of(i).color,
          onSelected: n.setDaysPerWeek,
        );
      case 12:
        return _ChipNumberRow(
          values: OnboardingOptions.sessionMinutes,
          selected: draft.minutesPerSession,
          suffix: 'min',
          accent: StepVisuals.of(i).color,
          onSelected: n.setMinutesPerSession,
        );
      case 13:
        return MultiSelectGroup(
          options: OnboardingOptions.limitations,
          selected: draft.limitations,
          onToggle: n.toggleLimitation,
        );
      case 14:
        return MultiSelectGroup(
          options: OnboardingOptions.dietPrefs,
          selected: draft.dietPrefs,
          onToggle: n.toggleDietPref,
        );
      case 15:
        return _TextEntry(
          controller: _allergiesCtrl,
          hint: 'e.g. peanuts, shellfish (or leave blank)',
          initial: draft.allergies,
          onChanged: n.setAllergies,
        );
      case 16:
        return SingleSelectGroup(
          options: OnboardingOptions.mealsPerDay,
          selected: draft.mealsPerDay,
          onSelected: n.setMealsPerDay,
        );
      case 17:
        return SingleSelectGroup(
          options: OnboardingOptions.cookingFrequency,
          selected: draft.cookingFrequency,
          onSelected: n.setCookingFrequency,
        );
      case 18:
        return _WorkoutTimePicker(
          time: draft.workoutTime,
          onTap: _pickWorkoutTime,
        );
      case 19:
        return Column(
          children: [
            LabeledSlider(
              label: 'Stress level',
              value: draft.stressLevel,
              lowLabel: 'Relaxed',
              highLabel: 'Very stressed',
              onChanged: n.setStressLevel,
            ),
            LabeledSlider(
              label: 'Sleep quality',
              value: draft.sleepQuality,
              lowLabel: 'Poor',
              highLabel: 'Excellent',
              onChanged: n.setSleepQuality,
            ),
            LabeledSlider(
              label: 'Mood today',
              value: draft.mood,
              lowLabel: 'Low',
              highLabel: 'Great',
              onChanged: n.setMood,
            ),
          ],
        );
      case 20:
        return _SmokingStep(
          choice: draft.smokingChoice,
          cigarettesPerDay: draft.cigarettesPerDay,
          accent: StepVisuals.of(i).color,
          onChoice: n.setSmokingChoice,
          onCigarettes: n.setCigarettesPerDay,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _stepTitle(int i, OnboardingDraft d) {
    final hi = d.firstName.isNotEmpty ? ', ${d.firstName}' : '';
    switch (i) {
      case 0:
        return 'Welcome to Vita';
      case 1:
        return "What's your name?";
      case 2:
        return "What's your email?";
      case 3:
        return 'When were you born?';
      case 4:
        return "What's your main goal$hi?";
      case 5:
        return 'How do you identify?';
      case 6:
        return 'How tall are you?';
      case 7:
        return "What's your current weight?";
      case 8:
        return 'Any target weight?';
      case 9:
        return 'How active are you day to day?';
      case 10:
        return 'What equipment can you use?';
      case 11:
        return 'How many days a week can you train?';
      case 12:
        return 'How long per session?';
      case 13:
        return 'Any physical limitations?';
      case 14:
        return 'Any dietary preferences?';
      case 15:
        return 'Any allergies?';
      case 16:
        return 'How many meals a day?';
      case 17:
        return 'How often do you cook?';
      case 18:
        return 'What time do you want to work out?';
      case 19:
        return 'A quick mind check-in';
      case 20:
        return 'One last thing — do you smoke?';
      default:
        return '';
    }
  }

  String? _stepSubtitle(int i) {
    switch (i) {
      case 2:
        return "We'll use this to save your plan and progress.";
      case 8:
        return 'Leave blank if you just want to feel better — no number needed.';
      case 10:
        return 'Select all that apply.';
      case 13:
        return 'Pick "None" if you have no restrictions. Select all that apply.';
      case 14:
        return 'Select all that apply.';
      case 18:
        return "We'll remind you at this time each workout day.";
      case 19:
        return 'This helps Vita tailor tone and intensity. There are no wrong answers.';
      case 20:
        return 'Optional — if you want to quit, Vita adds a gentle daily tracker '
            'to help you taper down. You can change this anytime.';
      default:
        return null;
    }
  }

  bool _isStepValid(int i, OnboardingDraft d) {
    switch (i) {
      case 0:
        return true;
      case 1:
        return (d.fullName ?? '').trim().length >= 2;
      case 2:
        return _emailRegex.hasMatch((d.email ?? '').trim());
      case 3:
        return d.age != null && d.age! >= 13 && d.age! <= 100;
      case 4:
        return d.goal != null;
      case 5:
        return d.sex != null;
      case 6:
        return d.heightCm != null && d.heightCm! >= 100 && d.heightCm! <= 250;
      case 7:
        return d.weightKg != null && d.weightKg! >= 30 && d.weightKg! <= 300;
      case 8:
        return true; // target weight optional
      case 9:
        return d.activityLevel != null;
      case 10:
        return d.equipment.isNotEmpty;
      case 11:
        return d.daysPerWeek != null;
      case 12:
        return d.minutesPerSession != null;
      case 13:
        return d.limitations.isNotEmpty;
      case 14:
        return d.dietPrefs.isNotEmpty;
      case 15:
        return true; // allergies optional
      case 16:
        return d.mealsPerDay != null;
      case 17:
        return d.cookingFrequency != null;
      case 18:
        return d.workoutTime != null;
      case 19:
        return true;
      case 20:
        return d.smokingChoice != null;
      default:
        return false;
    }
  }
}

// ---- Background -----------------------------------------------------------

/// A gradient backdrop with soft, color-shifting blobs that animate to the
/// current step's accent color.
class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEDF3F0), Color(0xFFF8FAF9)],
        ),
      ),
      child: Stack(
        children: [
          _blob(top: -60, left: -40, size: 220, color: color, opacity: 0.18),
          _blob(top: 120, right: -70, size: 180, color: color, opacity: 0.12),
          _blob(bottom: -50, left: -30, size: 200, color: color, opacity: 0.14),
          child,
        ],
      ),
    );
  }

  Widget _blob({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

// ---- Sub-widgets ----------------------------------------------------------

class _StepHero extends StatelessWidget {
  const _StepHero({required this.emoji, required this.color});

  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.10)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 38)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.index,
    required this.total,
    required this.accent,
    required this.onToggleVoice,
    this.onBack,
  });

  final int index;
  final int total;
  final Color accent;
  final VoidCallback onToggleVoice;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final progress = (index + 1) / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            color: onBack == null ? Colors.transparent : AppTheme.deepSage,
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8E5),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${index + 1}/$total',
            style: const TextStyle(
              color: Colors.black45,
              fontWeight: FontWeight.w600,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: TtsService.instance.enabled,
            builder: (context, on, _) => IconButton(
              tooltip: on ? 'Mute voice' : 'Unmute voice',
              onPressed: onToggleVoice,
              icon: Icon(on ? Icons.volume_up_rounded : Icons.volume_off_rounded),
              color: on ? accent : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.label,
    required this.accent,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            disabledBackgroundColor: accent.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: enabled ? onPressed : null,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeIn(
          delay: Duration(milliseconds: 200),
          child: Text(
            'Answer a few quick questions and Vita will craft a personalized '
            'fitness, nutrition, and mindfulness plan — adjusting it as you go. '
            'Your answers stay on this device until you choose to save.',
            style: TextStyle(color: Colors.black54, fontSize: 15, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),
        FadeIn(
          delay: const Duration(milliseconds: 320),
          child: Row(
            children: const [
              _PerkChip(emoji: '💪', label: 'Workouts'),
              SizedBox(width: 10),
              _PerkChip(emoji: '🥗', label: 'Nutrition'),
              SizedBox(width: 10),
              _PerkChip(emoji: '🧘', label: 'Mindfulness'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FadeIn(
          delay: const Duration(milliseconds: 440),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'General wellness guidance only — not medical advice.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _PerkChip extends StatelessWidget {
  const _PerkChip({required this.emoji, required this.label});
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8E5)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.deepSage)),
        ],
      ),
    );
  }
}

class _DobPicker extends StatelessWidget {
  const _DobPicker({required this.dob, required this.age, required this.onTap});

  final DateTime? dob;
  final int? age;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDate = dob != null;
    final label = hasDate
        ? '${dob!.day.toString().padLeft(2, '0')}/'
            '${dob!.month.toString().padLeft(2, '0')}/${dob!.year}'
        : 'Tap to select your date of birth';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PickerCard(
          icon: Icons.cake_outlined,
          label: label,
          filled: hasDate,
          onTap: onTap,
        ),
        if (age != null)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 4),
            child: Text(
              "You're $age years old.",
              style: const TextStyle(
                  color: AppTheme.sage, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _WorkoutTimePicker extends StatelessWidget {
  const _WorkoutTimePicker({required this.time, required this.onTap});

  final TimeOfDay? time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = time != null;
    final label = has ? time!.format(context) : 'Tap to pick a workout time';
    return _PickerCard(
      icon: Icons.alarm,
      label: label,
      filled: has,
      onTap: onTap,
    );
  }
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? AppTheme.sage : const Color(0xFFE2E8E5),
            width: filled ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.sage),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
                  color: filled ? AppTheme.deepSage : Colors.black45,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _TextEntry extends StatelessWidget {
  const _TextEntry({
    required this.controller,
    required this.onChanged,
    this.hint,
    this.initial,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hint;
  final String? initial;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    if (controller.text.isEmpty && (initial != null && initial!.isNotEmpty)) {
      controller.text = initial!;
    }
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      decoration: _fieldDecoration(hint: hint),
      onChanged: onChanged,
    );
  }
}

InputDecoration _fieldDecoration({String? hint, String? suffix}) {
  return InputDecoration(
    hintText: hint,
    suffixText: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.sage, width: 2),
    ),
  );
}

class _ChipNumberRow extends StatelessWidget {
  const _ChipNumberRow({
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.accent,
    this.suffix,
  });

  final List<int> values;
  final int? selected;
  final ValueChanged<int> onSelected;
  final Color accent;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(suffix == null ? '$v' : '$v $suffix'),
            selected: selected == v,
            onSelected: (_) => onSelected(v),
            selectedColor: accent,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected == v ? Colors.white : AppTheme.deepSage,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected == v ? accent : const Color(0xFFE2E8E5),
              ),
            ),
          ),
      ],
    );
  }
}

/// Final onboarding step: smoking status, with a taper-baseline stepper that
/// appears only when the user wants help quitting.
class _SmokingStep extends StatelessWidget {
  const _SmokingStep({
    required this.choice,
    required this.cigarettesPerDay,
    required this.accent,
    required this.onChoice,
    required this.onCigarettes,
  });

  final String? choice;
  final int cigarettesPerDay;
  final Color accent;
  final ValueChanged<String> onChoice;
  final ValueChanged<int> onCigarettes;

  static const _options = [
    ('quit', '🚭', 'Yes — help me quit'),
    ('smokes', '🚬', 'I smoke, not ready yet'),
    ('no', '🌿', "I don't smoke"),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (value, emoji, label) in _options) ...[
          _ChoiceCard(
            emoji: emoji,
            label: label,
            selected: choice == value,
            accent: accent,
            onTap: () => onChoice(value),
          ),
          const SizedBox(height: 12),
        ],
        if (choice == 'quit') ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8E5)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Cigarettes a day now',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSage)),
                ),
                IconButton(
                  onPressed: cigarettesPerDay > 1
                      ? () => onCigarettes(cigarettesPerDay - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: accent,
                ),
                SizedBox(
                  width: 28,
                  child: Text('$cigarettesPerDay',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.deepSage)),
                ),
                IconButton(
                  onPressed: () => onCigarettes(cigarettesPerDay + 1),
                  icon: const Icon(Icons.add_circle_outline),
                  color: accent,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : const Color(0xFFE2E8E5),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppTheme.deepSage : Colors.black54,
                  )),
            ),
            if (selected) Icon(Icons.check_circle, color: accent),
          ],
        ),
      ),
    );
  }
}
