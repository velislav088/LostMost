import 'package:flutter/material.dart';
import 'package:mobile/mqtt/mqtt_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // get mqtt service
  final MQTTService _rssiService = MQTTService();
  String _rssi = "Connecting...";

  @override
  void initState() {
    super.initState();
    _initializeMQTT();
  }

  Future<void> _initializeMQTT() async {
    await _rssiService.initialize();
    _rssiService.rssiStream.listen((value) {
      setState(() {
        _rssi = value;
      });
    });
  }

  @override
  void dispose() {
    _rssiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RSSI Viewer')),
      body: Center(
        child: Text(
          _rssi,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
