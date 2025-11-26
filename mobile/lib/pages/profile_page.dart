import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mobile/theme/theme_provider.dart';
import 'package:mobile/theme/settings_provider.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _cacheSize = "Calculating...";

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true, followLinks: false).forEach((
          FileSystemEntity entity,
        ) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
      if (!mounted) return;
      setState(() {
        _cacheSize = _formatBytes(totalSize);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cacheSize = "Unknown";
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    if (bytes < 1024) return "$bytes B";
    double value = bytes / 1.0;
    int suffixIndex = 0;
    while (value >= 1024 && suffixIndex < suffixes.length - 1) {
      value /= 1024;
      suffixIndex++;
    }
    return "${value.toStringAsFixed(1)} ${suffixes[suffixIndex]}";
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      await _calculateCacheSize();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cache cleared'),
          backgroundColor: context.info,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear cache: $e'),
          backgroundColor: context.info,
        ),
      );
    }
  }

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
            onPressed: () => context.pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            // confirm
            onPressed: () => context.pop(true),
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
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    if (!mounted) return; // guard the use with a 'mounted' check
    context.go('/login');
  }

  Future<void> _launchGitHub() async {
    final Uri url = Uri.parse('https://github.com/velislav088/LostMost');
    if (!await launchUrl(url)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not launch GitHub URL'),
          backgroundColor: context.info,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // get user email
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentEmail = authService.getCurrentUserEmail();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // Localization helper
    String t(String key, {bool listen = true}) {
      return AppLocalizations.of(context, key, listen: listen);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('profile_title')),
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
                    t('account'),
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
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.lock_outline, color: context.textMuted),
                    title: Text(t('change_password')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final passwordController = TextEditingController();
                          return AlertDialog(
                            title: Text(t('change_password')),
                            content: TextField(
                              controller: passwordController,
                              decoration: InputDecoration(
                                labelText: t('new_password', listen: false),
                              ),
                              obscureText: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => context.pop(),
                                child: Text(t('cancel', listen: false)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final newPassword = passwordController.text;
                                  if (newPassword.isNotEmpty) {
                                    try {
                                      final authService =
                                          Provider.of<AuthService>(
                                            context,
                                            listen: false,
                                          );
                                      await authService.updatePassword(
                                        newPassword,
                                      );
                                      if (!context.mounted) return;
                                      context.pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            t(
                                              'password_updated',
                                              listen: false,
                                            ),
                                          ),
                                          backgroundColor: context.info,
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      context.go('/profile');
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "${t('password_update_failed', listen: false)}: $e",
                                          ),
                                          backgroundColor: context.info,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(t('save', listen: false)),
                              ),
                            ],
                          );
                        },
                      );
                    },
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
                    t('appearance'),
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
                          t('theme'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // app theme
                      DropdownButton<ThemeOption>(
                        value: themeProvider.themeOption,
                        underline: Container(),
                        borderRadius: BorderRadius.circular(8),
                        items: [
                          DropdownMenuItem(
                            value: ThemeOption.system,
                            child: Text(t('system')),
                          ),
                          DropdownMenuItem(
                            value: ThemeOption.light,
                            child: Text(t('light')),
                          ),
                          DropdownMenuItem(
                            value: ThemeOption.dark,
                            child: Text(t('dark')),
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
                    t('choose_look'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: context.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // language settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('app_language'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.language, color: context.textMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t('language'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      DropdownButton<Locale>(
                        value: settingsProvider.locale,
                        underline: Container(),
                        borderRadius: BorderRadius.circular(8),
                        items: const [
                          DropdownMenuItem(
                            value: Locale('en'),
                            child: Text('English'),
                          ),
                          DropdownMenuItem(
                            value: Locale('bg'),
                            child: Text('Български'),
                          ),
                        ],
                        onChanged: (Locale? newValue) {
                          if (newValue != null) {
                            settingsProvider.setLocale(newValue);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // data and storage
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('data_storage'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      t('data_saver'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      t('reduce_data'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: context.textMuted),
                    ),
                    value: settingsProvider.dataSaverEnabled,
                    onChanged: (bool value) {
                      settingsProvider.setDataSaver(value);
                    },
                    secondary: Icon(Icons.data_usage, color: context.textMuted),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_outline,
                      color: context.textMuted,
                    ),
                    title: Text(t('clear_cache')),
                    subtitle: Text(_cacheSize),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(t('clear_cache')),
                          content: Text(t('clear_cache_confirm')),
                          actions: [
                            TextButton(
                              onPressed: () => context.pop(false),
                              child: Text(t('cancel', listen: false)),
                            ),
                            ElevatedButton(
                              onPressed: () => context.pop(true),
                              child: Text(t('clear', listen: false)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _clearCache();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // about
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('about'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.info_outline, color: context.textMuted),
                    title: Text(t('version')),
                    trailing: Text(
                      '0.1.0',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.textMuted,
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.code, color: context.textMuted),
                    title: Text(t('source_code')),
                    onTap: _launchGitHub,
                    trailing: const Icon(Icons.open_in_new),
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
                    t('color_preview'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ColorChip(
                        label: t('primary_color'),
                        color: context.primary,
                      ),
                      _ColorChip(
                        label: t('secondary_color'),
                        color: context.secondary,
                      ),
                      _ColorChip(
                        label: t('success_color'),
                        color: context.success,
                      ),
                      _ColorChip(
                        label: t('warning_color'),
                        color: context.warning,
                      ),
                      _ColorChip(
                        label: t('danger_color'),
                        color: context.danger,
                      ),
                      _ColorChip(label: t('info_color'), color: context.info),
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
