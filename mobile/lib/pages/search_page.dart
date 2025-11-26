import 'package:flutter/material.dart';
import 'package:mobile/theme/app_localizations.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context, 'search_title'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 100),
            Text(AppLocalizations.of(context, 'search_page'), style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
