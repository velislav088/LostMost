import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:mobile/theme/app_localizations.dart';
import 'package:mobile/theme/app_theme.dart';

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
          padding: const EdgeInsets.all(16),
          tabs: [
            GButton(
              icon: Icons.home,
              text: AppLocalizations.of(context, 'nav_home'),
            ),
            GButton(
              icon: Icons.search,
              text: AppLocalizations.of(context, 'nav_search'),
            ),
            GButton(
              icon: Icons.settings,
              text: AppLocalizations.of(context, 'nav_settings'),
            ),
          ],
        ),
      ),
    ),
  );
}
