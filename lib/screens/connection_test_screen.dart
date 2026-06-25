import 'package:flutter/material.dart';

import '../models/onboarding_answers.dart';
import '../models/plan.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// A temporary scaffold screen that proves the full stack works end to end:
/// Flutter -> Supabase Edge Function -> Groq -> structured plan.
///
/// This will be replaced by the real onboarding flow in the next prompt.
class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  final ApiService _api = ApiService();

  bool _loading = false;
  WellnessPlan? _plan;
  String? _error;

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _error = null;
      _plan = null;
    });

    try {
      final plan = await _api.generatePlan(OnboardingAnswers.sample());
      if (!mounted) return;
      setState(() => _plan = plan);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vita')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.spa_outlined, size: 56, color: AppTheme.sage),
                const SizedBox(height: 16),
                Text(
                  'Vita: AI Wellness Coach',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSage,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Backend connection test — generates a sample plan from the '
                  'live Supabase + Groq pipeline.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _loading ? null : _testConnection,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bolt_outlined),
                  label: Text(_loading ? 'Generating…' : 'Test Backend'),
                ),
                const SizedBox(height: 24),
                if (_error != null) _ErrorCard(message: _error!),
                if (_plan != null) _PlanCard(plan: _plan!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFDECEC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFC0392B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFFC0392B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final WellnessPlan plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.sage),
                const SizedBox(width: 8),
                Text(
                  'Connected — plan generated',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const Divider(height: 28),
            _statRow('Calorie target', '${plan.calorieTarget} kcal'),
            _statRow('Protein', '${plan.macros.proteinG} g'),
            _statRow('Carbs', '${plan.macros.carbsG} g'),
            _statRow('Fat', '${plan.macros.fatG} g'),
            _statRow('Workout days', '${plan.workoutPlan.length}'),
            _statRow('Sample meals', '${plan.sampleMeals.length}'),
            const SizedBox(height: 16),
            Text(
              'Weekly tip',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.sage,
                  ),
            ),
            const SizedBox(height: 4),
            Text(plan.weeklyFocusTip),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'General wellness guidance only — not medical advice.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
