import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/home/home_screen.dart';
import '../screens/vitals/vitals_tab.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/wellness/wellness_tab.dart';
import '../screens/profile/profile_screen.dart';
import '../theme/app_colors.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    VitalsTab(),
    ActivityScreen(),
    WellnessTab(),
    ProfileScreen(),
  ];

  void _onTap(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, current: _index, onTap: _onTap),
                _NavItem(icon: Icons.favorite_rounded, label: 'Vitals', index: 1, current: _index, onTap: _onTap),
                _NavItem(icon: Icons.directions_run_rounded, label: 'Activity', index: 2, current: _index, onTap: _onTap),
                _NavItem(icon: Icons.spa_rounded, label: 'Wellness', index: 3, current: _index, onTap: _onTap),
                _NavItem(icon: Icons.person_rounded, label: 'Profile', index: 4, current: _index, onTap: _onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.teal.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? AppColors.teal : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.teal : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
