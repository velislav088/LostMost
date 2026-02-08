import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mobile/theme/app_localizations.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/settings_provider.dart';
import 'package:mobile/theme/theme_provider.dart';
import 'package:mobile/utils/ui_utils.dart';
import 'package:mobile/view_models/profile_view_model.dart';
import 'package:mobile/widgets/animations_util.dart';
import 'package:mobile/widgets/profile/profile_menu_tile.dart';
import 'package:mobile/widgets/profile/profile_section_card.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => ProfileViewModel(
      authService: Provider.of<AuthService>(context, listen: false),
    ),
    child: const _ProfilePageContent(),
  );
}

class _ProfilePageContent extends StatelessWidget {
  const _ProfilePageContent();

  Future<void> _launchGitHub(BuildContext context) async {
    final url = Uri.parse('https://github.com/velislav088/LostMost');
    if (!await launchUrl(url)) {
      if (!context.mounted) {
        return;
      }
      context.showInfoSnackBar('Could not launch GitHub URL');
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final viewModel = Provider.of<ProfileViewModel>(context, listen: false);
    final logoutDialog = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (logoutDialog == true) {
      await viewModel.logout();
      if (!context.mounted) {
        return;
      }
      context.go('/login');
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    // We keep the controller in the dialog builder or use a stateful widget for the dialog
    // Since it's simple, we can just use a local controller in the builder
    showDialog(
      context: context,
      builder: (context) {
        final passwordController = TextEditingController();
        return AlertDialog(
          title: Text(AppLocalizations.of(context, 'change_password')),
          content: TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(
                context,
                'new_password',
                listen: false,
              ),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                AppLocalizations.of(context, 'cancel', listen: false),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPassword = passwordController.text;
                if (newPassword.isNotEmpty) {
                  try {
                    final viewModel = Provider.of<ProfileViewModel>(
                      context,
                      listen: false,
                    );
                    await viewModel.updatePassword(newPassword);
                    if (!context.mounted) {
                      return;
                    }
                    context
                      ..pop()
                      ..showSuccessSnackBar(
                        AppLocalizations.of(
                          context,
                          'password_updated',
                          listen: false,
                        ),
                      );
                  } catch (e) {
                    if (!context.mounted) {
                      return;
                    }
                    // Error is handled in ViewModel but we might want to show it here
                    // Actually ViewModel rethrows so we can catch it
                    context.showInfoSnackBar(
                      '${AppLocalizations.of(context, 'password_update_failed', listen: false)}: $e',
                    );
                  }
                }
              },
              child: Text(AppLocalizations.of(context, 'save', listen: false)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProfileViewModel>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    String t(String key, {bool listen = true}) =>
        AppLocalizations.of(context, key, listen: listen);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('profile_title')),
        actions: [
          IconButton(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FadeInAnimation(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // Account Section
            ProfileSectionCard(
              title: t('account'),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.email, color: context.textMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          viewModel.currentUserEmail ?? '...',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProfileMenuTile(
                    icon: Icons.lock_outline,
                    title: t('change_password'),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Appearance Section
            ProfileSectionCard(
              title: t('appearance'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        onChanged: (value) {
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
            const SizedBox(height: 16),

            // Language Section
            ProfileSectionCard(
              title: t('app_language'),
              child: Row(
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
                    onChanged: (newValue) {
                      if (newValue != null) {
                        settingsProvider.setLocale(newValue);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Data & Storage Section
            ProfileSectionCard(
              title: t('data_storage'),
              child: Column(
                children: [
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
                    onChanged: settingsProvider.setDataSaver,
                    secondary: Icon(Icons.data_usage, color: context.textMuted),
                  ),
                  const Divider(),
                  ProfileMenuTile(
                    icon: Icons.delete_outline,
                    title: t('clear_cache'),
                    subtitle: viewModel.cacheSize,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(Icons.warning_amber, color: context.warning),
                              const SizedBox(width: 8),
                              Text(t('clear_cache')),
                            ],
                          ),
                          content: Text(
                            t('clear_cache_confirm'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => context.pop(false),
                              child: Text(t('cancel', listen: false)),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => context.pop(true),
                              icon: const Icon(Icons.delete),
                              label: Text(t('clear', listen: false)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.danger,
                                foregroundColor: context.bgLight,
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        if (context.mounted) {
                          await viewModel.clearCache();
                          if (context.mounted) {
                            context.showInfoSnackBar(
                              viewModel.error ?? 'Cache cleared',
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // About Section
            ProfileSectionCard(
              title: t('about'),
              child: Column(
                children: [
                  ProfileMenuTile(
                    icon: Icons.info_outline,
                    title: t('version'),
                    trailing: Text(
                      viewModel.appVersion,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.textMuted,
                      ),
                    ),
                  ),
                  ProfileMenuTile(
                    icon: Icons.code,
                    title: t('source_code'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _launchGitHub(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Color Preview Section
            ProfileSectionCard(
              title: t('color_preview'),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ColorChip(label: t('primary_color'), color: context.primary),
                  _ColorChip(
                    label: t('secondary_color'),
                    color: context.secondary,
                  ),
                  _ColorChip(label: t('success_color'), color: context.success),
                  _ColorChip(label: t('warning_color'), color: context.warning),
                  _ColorChip(label: t('danger_color'), color: context.danger),
                  _ColorChip(label: t('info_color'), color: context.info),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: context.border),
      ),
    ),
    label: Text(label),
    backgroundColor: context.bgLight,
    side: BorderSide(color: context.borderMuted),
  );
}
