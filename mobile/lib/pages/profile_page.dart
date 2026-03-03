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
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<ProfileViewModel>(
        create: (context) =>
            ProfileViewModel(authService: context.read<AuthService>()),
        child: const _ProfilePageContent(),
      );
}

class _ProfilePageContent extends StatelessWidget {
  const _ProfilePageContent();

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t(context, 'logout')),
        content: Text(_t(context, 'logout_confirm')),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(_t(context, 'cancel', listen: false)),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            child: Text(_t(context, 'logout', listen: false)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await context.read<ProfileViewModel>().logout();
    if (!context.mounted) {
      return;
    }
    context.go('/login');
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_t(context, 'profile_title')),
      actions: <Widget>[
        IconButton(
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: FadeInAnimation(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: <Widget>[
          _AccountSection(
            onChangePasswordTap: () => _showChangePasswordDialog(context),
          ),
          const SizedBox(height: 16),
          const _AppearanceSection(),
          const SizedBox(height: 16),
          const _LanguageSection(),
          const SizedBox(height: 16),
          const _DataStorageSection(),
          const SizedBox(height: 16),
          const _AboutSection(),
          const SizedBox(height: 16),
          const _ColorPreviewSection(),
        ],
      ),
    ),
  );
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.onChangePasswordTap});

  final VoidCallback onChangePasswordTap;

  @override
  Widget build(BuildContext context) {
    final email = context.select<ProfileViewModel, String?>(
      (viewModel) => viewModel.currentUserEmail,
    );

    return ProfileSectionCard(
      title: _t(context, 'account'),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.email, color: context.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  email ?? '...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProfileMenuTile(
            icon: Icons.lock_outline,
            title: _t(context, 'change_password'),
            onTap: onChangePasswordTap,
          ),
        ],
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final themeOption = context.select<ThemeProvider, ThemeOption>(
      (provider) => provider.themeOption,
    );

    return ProfileSectionCard(
      title: _t(context, 'appearance'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.palette, color: context.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t(context, 'theme'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<ThemeOption>(
                value: themeOption,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(8),
                items: <DropdownMenuItem<ThemeOption>>[
                  DropdownMenuItem(
                    value: ThemeOption.system,
                    child: Text(_t(context, 'system', listen: false)),
                  ),
                  DropdownMenuItem(
                    value: ThemeOption.light,
                    child: Text(_t(context, 'light', listen: false)),
                  ),
                  DropdownMenuItem(
                    value: ThemeOption.dark,
                    child: Text(_t(context, 'dark', listen: false)),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  context.read<ThemeProvider>().setThemeOption(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _t(context, 'choose_look'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.textMuted),
          ),
        ],
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final locale = context.select<SettingsProvider, Locale>(
      (provider) => provider.locale,
    );

    return ProfileSectionCard(
      title: _t(context, 'app_language'),
      child: Row(
        children: <Widget>[
          Icon(Icons.language, color: context.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _t(context, 'language'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          DropdownButton<Locale>(
            value: locale,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(8),
            items: const <DropdownMenuItem<Locale>>[
              DropdownMenuItem(value: Locale('en'), child: Text('English')),
              DropdownMenuItem(value: Locale('bg'), child: Text('Български')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              context.read<SettingsProvider>().setLocale(value);
            },
          ),
        ],
      ),
    );
  }
}

class _DataStorageSection extends StatelessWidget {
  const _DataStorageSection();

  Future<void> _confirmAndClearCache(BuildContext context) async {
    final clearCache = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: <Widget>[
            Icon(Icons.warning_amber, color: context.warning),
            const SizedBox(width: 8),
            Text(_t(context, 'clear_cache')),
          ],
        ),
        content: Text(
          _t(context, 'clear_cache_confirm'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(_t(context, 'cancel', listen: false)),
          ),
          ElevatedButton.icon(
            onPressed: () => context.pop(true),
            icon: const Icon(Icons.delete),
            label: Text(_t(context, 'clear', listen: false)),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.danger,
              foregroundColor: context.bgLight,
            ),
          ),
        ],
      ),
    );

    if (clearCache != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final viewModel = context.read<ProfileViewModel>();
    final success = await viewModel.clearCache();
    if (!context.mounted) {
      return;
    }

    if (success) {
      context.showSuccessSnackBar(_t(context, 'cache_cleared', listen: false));
      return;
    }

    context.showErrorSnackBar(
      viewModel.error ?? _t(context, 'cache_clear_failed', listen: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataSaverEnabled = context.select<SettingsProvider, bool>(
      (provider) => provider.dataSaverEnabled,
    );
    final cacheSize = context.select<ProfileViewModel, String>(
      (viewModel) => viewModel.cacheSize,
    );

    return ProfileSectionCard(
      title: _t(context, 'data_storage'),
      child: Column(
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _t(context, 'data_saver'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(
              _t(context, 'reduce_data'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.textMuted),
            ),
            value: dataSaverEnabled,
            onChanged: (value) {
              context.read<SettingsProvider>().setDataSaver(value);
            },
            secondary: Icon(Icons.data_usage, color: context.textMuted),
          ),
          const Divider(),
          ProfileMenuTile(
            icon: Icons.delete_outline,
            title: _t(context, 'clear_cache'),
            subtitle: cacheSize,
            onTap: () => _confirmAndClearCache(context),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  Future<void> _launchGitHub(BuildContext context) async {
    final uri = Uri.parse('https://github.com/velislav088/LostMost');
    if (await launchUrl(uri)) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    context.showErrorSnackBar(_t(context, 'open_link_failed', listen: false));
  }

  @override
  Widget build(BuildContext context) {
    final appVersion = context.select<ProfileViewModel, String>(
      (viewModel) => viewModel.appVersion,
    );

    return ProfileSectionCard(
      title: _t(context, 'about'),
      child: Column(
        children: <Widget>[
          ProfileMenuTile(
            icon: Icons.info_outline,
            title: _t(context, 'version'),
            trailing: Text(
              appVersion,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.textMuted),
            ),
          ),
          ProfileMenuTile(
            icon: Icons.code,
            title: _t(context, 'source_code'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchGitHub(context),
          ),
        ],
      ),
    );
  }
}

class _ColorPreviewSection extends StatelessWidget {
  const _ColorPreviewSection();

  @override
  Widget build(BuildContext context) => ProfileSectionCard(
    title: _t(context, 'color_preview'),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _ColorChip(label: _t(context, 'primary_color'), color: context.primary),
        _ColorChip(
          label: _t(context, 'secondary_color'),
          color: context.secondary,
        ),
        _ColorChip(label: _t(context, 'success_color'), color: context.success),
        _ColorChip(label: _t(context, 'warning_color'), color: context.warning),
        _ColorChip(label: _t(context, 'danger_color'), color: context.danger),
        _ColorChip(label: _t(context, 'info_color'), color: context.info),
      ],
    ),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return _t(context, 'password_required', listen: false);
    }

    if (password.length < 6) {
      return _t(context, 'password_too_short', listen: false);
    }

    return null;
  }

  Future<void> _savePassword() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final viewModel = context.read<ProfileViewModel>();
    final success = await viewModel.updatePassword(_passwordController.text);
    if (!mounted) {
      return;
    }

    if (success) {
      context
        ..pop()
        ..showSuccessSnackBar(_t(context, 'password_updated', listen: false));
      return;
    }

    context.showErrorSnackBar(
      viewModel.error ?? _t(context, 'password_update_failed', listen: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<ProfileViewModel, bool>(
      (viewModel) => viewModel.isLoading,
    );

    return AlertDialog(
      title: Text(_t(context, 'change_password')),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: _t(context, 'new_password', listen: false),
          ),
          validator: _validatePassword,
          onFieldSubmitted: (_) => _savePassword(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: isLoading ? null : () => context.pop(),
          child: Text(_t(context, 'cancel', listen: false)),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _savePassword,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_t(context, 'save', listen: false)),
        ),
      ],
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

String _t(BuildContext context, String key, {bool listen = true}) =>
    AppLocalizations.of(context, key, listen: listen);
