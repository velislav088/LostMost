class Device {
  final String id;
  final String name;
  final int rssi;
  final Map<String, dynamic> metadata;

  Device({
    required this.id,
    required this.name,
    required this.rssi,
    this.metadata = const {},
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'] as String? ?? 'unknown',
    name: json['name'] as String? ?? 'Unknown Device',
    rssi: json['rssi'] as int? ?? 0,
    metadata: json['metadata'] as Map<String, dynamic>? ?? {},
  );
}
