import 'package:flutter/material.dart';
import 'package:mobile/config/app_constants.dart';
import 'package:mobile/mqtt/mqtt_service.dart';
import 'package:mobile/theme/app_localizations.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/view_models/home_view_model.dart';
import 'package:mobile/widgets/animations_util.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<HomeViewModel>(
    create: (context) =>
        HomeViewModel(mqttService: context.read<MQTTService>())..initialize(),
    child: const _HomePageContent(),
  );
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context, 'home_title'))),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Selector<HomeViewModel, _HomeViewState>(
            selector: (_, viewModel) => _HomeViewState(
              error: viewModel.error,
              rssi: viewModel.latestRssi,
            ),
            builder: (context, state, _) {
              if (state.error != null) {
                return _HomeErrorView(error: state.error!);
              }

              return _RssiStatusView(rssi: state.rssi);
            },
          ),
        ),
      ),
    ),
  );
}

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) => FadeInAnimation(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.error_outline, size: 64, color: context.danger),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context, 'error'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: context.danger,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          error,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: context.textMuted),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => context.read<HomeViewModel>().retry(),
          icon: const Icon(Icons.refresh),
          label: Text(AppLocalizations.of(context, 'retry')),
        ),
      ],
    ),
  );
}

class _RssiStatusView extends StatelessWidget {
  const _RssiStatusView({required this.rssi});

  final int? rssi;

  String _proximityLabel(BuildContext context, int value) {
    if (value >= AppConstants.rssiCloseThreshold) {
      return AppLocalizations.of(context, 'proximity_close');
    }

    if (value >= AppConstants.rssiNearbyThreshold) {
      return AppLocalizations.of(context, 'proximity_nearby');
    }

    return AppLocalizations.of(context, 'proximity_far');
  }

  Color _proximityColor(BuildContext context, int value) {
    if (value >= AppConstants.rssiCloseThreshold) {
      return context.success;
    }

    if (value >= AppConstants.rssiNearbyThreshold) {
      return context.warning;
    }

    return context.danger;
  }

  @override
  Widget build(BuildContext context) => FadeInAnimation(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ScaleInAnimation(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: context.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sensors, size: 80, color: context.primary),
          ),
        ),
        const SizedBox(height: 48),
        Text(
          rssi != null
              ? 'RSSI: $rssi'
              : AppLocalizations.of(context, 'connecting'),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.text,
          ),
          textAlign: TextAlign.center,
        ),
        if (rssi != null) ...<Widget>[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _proximityColor(context, rssi!).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _proximityLabel(context, rssi!),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _proximityColor(context, rssi!),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

@immutable
class _HomeViewState {
  const _HomeViewState({required this.error, required this.rssi});

  final String? error;
  final int? rssi;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _HomeViewState &&
        other.error == error &&
        other.rssi == rssi;
  }

  @override
  int get hashCode => Object.hash(error, rssi);
}
