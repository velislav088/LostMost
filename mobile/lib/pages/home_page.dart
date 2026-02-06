import 'package:flutter/material.dart';
import 'package:mobile/mqtt/mqtt_service.dart';
import 'package:mobile/theme/app_localizations.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/animations_util.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // get mqtt service
  late final MQTTService _rssiService;
  String? _rssi;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rssiService = Provider.of<MQTTService>(context, listen: false);
    _initializeMQTT();
  }

  Future<void> _initializeMQTT() async {
    try {
      await _rssiService.initialize();
      _rssiService.rssiStream.listen(
        (value) {
          if (mounted) {
            setState(() {
              _rssi = value;
              _error = null;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _error = error.toString();
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _rssiService.dispose();
    super.dispose();
  }

  String _getProximityLabel(BuildContext context, int rssi) {
    if (rssi >= -60) {
      return AppLocalizations.of(context, 'proximity_close');
    } else if (rssi >= -80) {
      return AppLocalizations.of(context, 'proximity_nearby');
    } else {
      return AppLocalizations.of(context, 'proximity_far');
    }
  }

  Color _getProximityColor(BuildContext context, int rssi) {
    if (rssi >= -60) {
      return context.success;
    } else if (rssi >= -80) {
      return context.warning;
    } else {
      return context.danger;
    }
  }

  // Parse RSSI output like integer
  int? _parseRssi(String s) {
    final match = RegExp(r'-?\d+').firstMatch(s);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(0)!);
  }

  @override
  Widget build(BuildContext context) {
    final rssiValue = _rssi != null ? _parseRssi(_rssi!) : null;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context, 'home_title'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: _error != null
                ? FadeInAnimation(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: context.danger,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context, 'error'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: context.danger,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: context.textMuted),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _rssi = null;
                            });
                            _initializeMQTT();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(AppLocalizations.of(context, 'retry')),
                        ),
                      ],
                    ),
                  )
                : FadeInAnimation(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleInAnimation(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: context.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.sensors,
                              size: 80,
                              color: context.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          _rssi ?? AppLocalizations.of(context, 'connecting'),
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.text,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        if (rssiValue != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getProximityColor(
                                context,
                                rssiValue,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getProximityLabel(context, rssiValue),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getProximityColor(
                                      context,
                                      rssiValue,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
