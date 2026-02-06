import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme/app_localizations.dart';

class NavigationScaffold extends StatelessWidget {
  const NavigationScaffold({required this.navigationShell, super.key});
  // Create StatefulNavigationShell settings to route the navbar properly.
  final StatefulNavigationShell navigationShell;

  // tab switch logic
  void _onTabChange(BuildContext context, int index) => navigationShell
      .goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => _onTabChange(context, index),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: AppLocalizations.of(context, 'nav_home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.search_outlined),
          selectedIcon: const Icon(Icons.search),
          label: AppLocalizations.of(context, 'nav_search'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: AppLocalizations.of(context, 'nav_settings'),
        ),
      ],
    ),
  );
}
