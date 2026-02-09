import 'package:flutter/material.dart';

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ProfileSectionCard({
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}
