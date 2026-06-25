import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/plan.dart';
import '../../theme/app_theme.dart';
import '../coach/coach_screen.dart';
import '../dashboard_screen.dart';
import '../food/meal_log_screen.dart';
import 'plan_tab.dart';

/// The post-onboarding home: a dark + sage shell hosting the dashboard, the AI
/// coach, and the plan, with a central "Log meal" action.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.plan});
  final WellnessPlan plan;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  Future<void> _logMeal() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MealLogScreen()),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal added to today 🍽️')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardScreen(plan: widget.plan),
      CoachScreen(plan: widget.plan),
      PlanTab(plan: widget.plan),
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: IndexedStack(index: _index, children: tabs),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _logMeal,
              backgroundColor: AppTheme.sage,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.restaurant_rounded),
              label: const Text('Log meal'),
            )
          : null,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppTheme.darkSurface,
          indicatorColor: AppTheme.sage.withValues(alpha: 0.30),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white54),
              selectedIcon:
                  Icon(Icons.chat_bubble_rounded, color: Colors.white),
              label: 'Coach',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_rounded, color: Colors.white54),
              selectedIcon: Icon(Icons.list_alt_rounded, color: Colors.white),
              label: 'Plan',
            ),
          ],
        ),
      ),
    );
  }
}
