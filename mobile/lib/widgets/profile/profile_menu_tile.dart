import 'package:flutter/material.dart';
import 'package:mobile/theme/app_theme.dart';

class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? subtitle;
  final Color? iconColor;

  const ProfileMenuTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.subtitle,
    this.iconColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    leading: Icon(icon, color: iconColor ?? context.textMuted),
    title: Text(title),
    subtitle: subtitle != null ? Text(subtitle!) : null,
    trailing:
        trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
    onTap: onTap,
  );
}
