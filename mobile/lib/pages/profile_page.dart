import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mobile/theme/theme_provider.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // get auth service
  final authService = AuthService();

  // confirm logout
  void confirmLogout() async {
    // get user choice
    final logoutDialog = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            // cancel
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            // confirm
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (logoutDialog == true) {
      logout();
    }
  }

  // logout
  void logout() async {
    await authService.signOut();
    if (!mounted) return; // guard the use with a 'mounted' check
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // get user email
    final currentEmail = authService.getCurrentUserEmail();
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          // logout button
          IconButton(onPressed: confirmLogout, icon: Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // profile info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.email, color: context.textMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currentEmail.toString(),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // user settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.palette, color: context.textMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Theme',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // app theme
                      DropdownButton<ThemeOption>(
                        value: themeProvider.themeOption,
                        underline: Container(),
                        borderRadius: BorderRadius.circular(8),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeOption.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: ThemeOption.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeOption.dark,
                            child: Text('Dark'),
                          ),
                        ],
                        onChanged: (ThemeOption? value) {
                          if (value != null) {
                            themeProvider.setThemeOption(value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how the app looks to you',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: context.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Color preview card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color Preview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ColorChip(label: 'Primary', color: context.primary),
                      _ColorChip(label: 'Secondary', color: context.secondary),
                      _ColorChip(label: 'Success', color: context.success),
                      _ColorChip(label: 'Warning', color: context.warning),
                      _ColorChip(label: 'Danger', color: context.danger),
                      _ColorChip(label: 'Info', color: context.info),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: context.border, width: 1),
        ),
      ),
      label: Text(label),
      backgroundColor: context.bgLight,
      side: BorderSide(color: context.borderMuted),
    );
  }
}
