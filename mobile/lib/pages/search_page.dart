import 'package:flutter/material.dart';
import 'package:mobile/theme/app_localizations.dart';
import 'package:mobile/widgets/animations_util.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context, 'search_title'))),
    body: SafeArea(
      child: FadeInAnimation(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleInAnimation(
                child: Icon(
                  Icons.search,
                  size: 100,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context, 'search_page'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
