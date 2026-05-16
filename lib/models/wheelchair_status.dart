import 'dart:convert';

/// ============================================================================
/// [WheelchairStatus] — Model trạng thái thiết bị ESP32
/// ============================================================================
/// Theo dõi trạng thái online/offline qua Topic `smart_wheelchair/status`.
/// Hỗ trợ LWT (Last Will and Testament) — khi ESP32 mất kết nối đột ngột,
/// broker tự động publish message offline.
/// ============================================================================
class WheelchairStatus {
  /// Thiết bị đang online hay không.
  final bool isOnline;

  /// Trạng thái kết nối chi tiết: "connected" | "disconnected" | "connecting"
  final String connectionState;

  /// Thời điểm nhận status cuối cùng.
  final DateTime lastSeen;

  const WheelchairStatus({
    required this.isOnline,
    required this.connectionState,
    required this.lastSeen,
  });

  /// Trạng thái mặc định khi App vừa khởi động (chưa kết nối).
  factory WheelchairStatus.initial() {
    return WheelchairStatus(
      isOnline: false,
      connectionState: 'disconnected',
      lastSeen: DateTime.now(),
    );
  }

  /// Parse từ JSON string nhận qua MQTT.
  factory WheelchairStatus.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return WheelchairStatus.fromMap(json);
  }

  /// Parse từ Map.
  factory WheelchairStatus.fromMap(Map<String, dynamic> map) {
    return WheelchairStatus(
      isOnline: map['online'] as bool? ?? false,
      connectionState: map['state'] as String? ?? 'disconnected',
      lastSeen: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'online': isOnline,
        'state': connectionState,
      };

  String toJson() => jsonEncode(toMap());

  @override
  String toString() =>
      'WheelchairStatus(online: $isOnline, state: $connectionState)';
}
