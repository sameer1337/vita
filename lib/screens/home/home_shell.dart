import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/plan.dart';
import '../../theme/app_theme.dart';
import '../account/account_screen.dart';
import '../breathing/breathing_screen.dart';
import '../coach/coach_screen.dart';
import '../dashboard_screen.dart';
import '../diet/diet_plan_screen.dart';
import '../food/meal_log_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../settings/reminders_screen.dart';
import '../sleep/sleep_screen.dart';
import '../smoking/smoking_screen.dart';
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
      drawer: _AppDrawer(
        index: _index,
        onTab: (i) => setState(() => _index = i),
        plan: widget.plan,
      ),
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

/// The side menu — switches the main tabs and links to every module.
class _AppDrawer extends StatelessWidget {
  const _AppDrawer(
      {required this.index, required this.onTab, required this.plan});

  final int index;
  final ValueChanged<int> onTab;
  final WellnessPlan plan;

  @override
  Widget build(BuildContext context) {
    void tab(int i) {
      Navigator.of(context).pop();
      onTab(i);
    }

    void open(Widget screen) {
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }

    return Drawer(
      backgroundColor: AppTheme.darkSurface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text('Vita',
                      style: TextStyle(
                          color: AppTheme.sageLight,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            _item(Icons.home_rounded, 'Home', () => tab(0), index == 0),
            _item(Icons.smart_toy_rounded, 'AI Coach', () => tab(1), index == 1),
            _item(Icons.list_alt_rounded, 'Your plan', () => tab(2), index == 2),
            const Divider(color: Colors.white12, height: 24),
            _item(Icons.restaurant_menu_rounded, 'Meal plan',
                () => open(DietPlanScreen(
                    calorieTarget: plan.calorieTarget, plan: plan))),
            _item(Icons.local_fire_department_rounded, 'Nutrition',
                () => open(NutritionScreen(plan: plan))),
            _item(Icons.bedtime_rounded, 'Sleep',
                () => open(const SleepScreen())),
            _item(Icons.air_rounded, 'Breathing',
                () => open(const BreathingScreen())),
            _item(Icons.smoke_free_rounded, 'Quit smoking',
                () => open(const SmokingScreen())),
            _item(Icons.notifications_active_rounded, 'Reminders',
                () => open(const RemindersScreen())),
            const Divider(color: Colors.white12, height: 24),
            _item(Icons.person_rounded, 'Account',
                () => open(const AccountScreen())),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap,
      [bool selected = false]) {
    return ListTile(
      leading: Icon(icon,
          color: selected ? AppTheme.sageLight : Colors.white70),
      title: Text(label,
          style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      selected: selected,
      selectedTileColor: Colors.white.withValues(alpha: 0.05),
      onTap: onTap,
    );
  }
}
