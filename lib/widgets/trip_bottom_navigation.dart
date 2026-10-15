import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TripBottomNavigation extends StatelessWidget {
  const TripBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onHome,
    required this.onExplore,
    required this.onCourses,
  });

  final int selectedIndex;
  final VoidCallback onHome;
  final VoidCallback onExplore;
  final VoidCallback onCourses;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.line)),
        ),
        child: Row(
          children: [
            _Tab(
              icon: Icons.home_outlined,
              label: '홈',
              selected: selectedIndex == 0,
              onTap: onHome,
            ),
            _Tab(
              icon: Icons.explore_outlined,
              label: '둘러보기',
              selected: selectedIndex == 1,
              onTap: onExplore,
            ),
            _Tab(
              icon: Icons.route_outlined,
              label: '내 코스',
              selected: selectedIndex == 2,
              onTap: onCourses,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.accent : AppTheme.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
