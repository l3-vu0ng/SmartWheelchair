import 'dart:async';

import '../models/sensor_data.dart';
import '../models/wheelchair_status.dart';

/// Phương thức kết nối hiện tại.
enum ConnectionType {
  /// Kết nối qua WiFi + MQTT Broker (HiveMQ Cloud).
  wifi,

  /// Kết nối qua Bluetooth Low Energy (BLE) trực tiếp.
  bluetooth,

  /// Kết nối trực tiếp qua WiFi cục bộ (ESP32 làm Access Point) bằng WebSocket.
  localWifi,

  /// Chưa kết nối.
  none,
}

/// Trạng thái kết nối chung — dùng thay cho MqttConnectionState
/// để UI không phụ thuộc vào package mqtt_client.
enum AppConnectionState {
  connected,
  connecting,
  disconnected,
}

/// ============================================================================
/// [ConnectionService] — Interface trừu tượng cho mọi kênh kết nối
/// ============================================================================
/// Mọi phương thức giao tiếp (WiFi/MQTT, Bluetooth/BLE) đều phải implement
/// interface này. Đảm bảo WheelchairProvider có thể hoán đổi kênh kết nối
/// mà không cần thay đổi logic nghiệp vụ.
///
/// Tương đương với Strategy Pattern trong Gang of Four.
/// ============================================================================
abstract class ConnectionService {
  /// Loại kết nối mà service này đại diện.
  ConnectionType get type;

  /// Kết nối tới thiết bị. Trả về `true` nếu thành công.
  Future<bool> connect();

  /// Ngắt kết nối và giải phóng tài nguyên.
  void disconnect();

  /// Gửi lệnh điều khiển xe lăn.
  ///
  /// [command] — hướng: "forward", "backward", "left", "right", "stop".
  /// [speed] — tốc độ PWM (0-255), mặc định 200.
  void sendCommand(String command, {int speed = 200});

  /// Stream dữ liệu cảm biến (khoảng cách, pin).
  Stream<SensorData> get sensorStream;

  /// Stream trạng thái thiết bị (online/offline).
  Stream<WheelchairStatus> get statusStream;

  /// Stream trạng thái kết nối của App.
  Stream<AppConnectionState> get connectionStream;

  /// Trạng thái kết nối hiện tại.
  AppConnectionState get connectionState;

  /// Giải phóng tất cả tài nguyên. Gọi khi App dispose.
  void dispose();
}
