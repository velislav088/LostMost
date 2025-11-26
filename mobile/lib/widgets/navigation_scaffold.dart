import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/app_localizations.dart';

class NavigationScaffold extends StatelessWidget {
  // Create StatefulNavigationShell settings to route the navbar properly.
  final StatefulNavigationShell navigationShell;

  const NavigationScaffold({super.key, required this.navigationShell});

  // tab switch logic
  void _onTabChange(BuildContext context, int index) => navigationShell
      .goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        color: context.bgLight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: GNav(
            backgroundColor: context.bgLight,
            color: context.textMuted,
            activeColor: context.bgLight,
            tabBackgroundColor: context.primary,
            gap: 8,
            onTabChange: (index) => _onTabChange(context, index),
            padding: EdgeInsets.all(16),
            tabs: [
              GButton(icon: Icons.home, text: AppLocalizations.of(context, 'nav_home')),
              GButton(icon: Icons.search, text: AppLocalizations.of(context, 'nav_search')),
              GButton(icon: Icons.settings, text: AppLocalizations.of(context, 'nav_settings')),
            ],
          ),
        ),
      ),
    );
  }
}
