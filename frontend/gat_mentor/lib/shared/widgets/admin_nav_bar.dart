import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class AdminScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const AdminScaffoldWithNavBar({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/admin' || location == '/admin/') return 0;
    if (location.startsWith('/admin/questions')) return 1;
    if (location.startsWith('/admin/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/admin');
            case 1:
              context.go('/admin/questions');
            case 2:
              context.go('/admin/profile');
          }
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: s.adminDashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt_outlined),
            activeIcon: const Icon(Icons.list_alt),
            label: s.adminQuestions,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outlined),
            activeIcon: const Icon(Icons.person),
            label: s.profile,
          ),
        ],
      ),
    );
  }
}
