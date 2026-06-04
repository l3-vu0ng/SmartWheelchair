import 'dart:convert';

/// ============================================================================
/// [SensorData] — Model dữ liệu cảm biến từ ESP32
/// ============================================================================
/// Đóng gói dữ liệu từ HC-SR04 (khoảng cách) và pin.
/// Tương đương POJO/DTO trong Java — immutable, có factory fromJson.
/// ============================================================================
class SensorData {
  /// Khoảng cách vật cản (cm) — đo bởi HC-SR04. Phạm vi: 2-400cm.
  final double obstacleDistance;

  /// Mức pin ước tính (%) — đo bằng ADC trên ESP32.
  final double batteryLevel;

  /// Nhịp tim (bpm) — đo bởi MAX30102.
  final int? heartRate;

  /// Nồng độ oxy trong máu (%) — đo bởi MAX30102.
  final int? spo2;

  /// Vĩ độ (Latitude) của xe lăn (nếu có).
  final double? latitude;

  /// Kinh độ (Longitude) của xe lăn (nếu có).
  final double? longitude;

  /// Thời điểm đo (epoch ms).
  final DateTime timestamp;

  const SensorData({
    required this.obstacleDistance,
    required this.batteryLevel,
    this.heartRate,
    this.spo2,
    this.latitude,
    this.longitude,
    required this.timestamp,
  });

  /// Parse từ JSON string nhận qua MQTT.
  factory SensorData.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return SensorData.fromMap(json);
  }

  /// Parse từ Map.
  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      obstacleDistance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      batteryLevel: (map['battery'] as num?)?.toDouble() ?? 0.0,
      heartRate: (map['heartRate'] as num?)?.toInt(),
      spo2: (map['spo2'] as num?)?.toInt(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as num).toInt() * 1000)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'distance': obstacleDistance,
        'battery': batteryLevel,
        if (heartRate != null) 'heartRate': heartRate,
        if (spo2 != null) 'spo2': spo2,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
      };

  String toJson() => jsonEncode(toMap());

  /// Vật cản nguy hiểm (< 15cm — ngưỡng dừng khẩn cấp trên ESP32).
  bool get isDangerousObstacle => obstacleDistance > 0 && obstacleDistance < 15;

  /// Vật cản cảnh báo (15-30cm).
  bool get isWarningObstacle =>
      obstacleDistance >= 15 && obstacleDistance < 30;

  /// Pin yếu (< 20%).
  bool get isLowBattery => batteryLevel > 0 && batteryLevel < 20;

  @override
  String toString() =>
      'SensorData(distance: ${obstacleDistance}cm, battery: $batteryLevel%, lat: $latitude, lng: $longitude)';
}
