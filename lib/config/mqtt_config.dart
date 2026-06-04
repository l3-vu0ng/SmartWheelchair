/// ============================================================================
/// [MqttConfig] — Cấu hình kết nối MQTT Broker
/// ============================================================================
/// Tập trung toàn bộ thông tin kết nối HiveMQ Cloud và các Topic MQTT
/// vào một nơi duy nhất. Tương đương với file `application.properties`
/// trong Spring Boot hoặc `Constants.java` trong Java.
///
/// Topic Architecture (Kiến trúc chủ đề):
///   smart_wheelchair/cmd     → Lệnh điều khiển từ App gửi xuống ESP32
///   smart_wheelchair/sensors → Dữ liệu cảm biến từ ESP32 gửi lên App
///   smart_wheelchair/status  → Trạng thái thiết bị (Online/Offline via LWT)
/// ============================================================================
library;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MqttConfig {
  MqttConfig._(); // Ngăn khởi tạo instance

  // ===========================================================================
  // BROKER CONNECTION
  // ===========================================================================

  /// URL của HiveMQ Cloud Broker.
  static const String brokerUrl =
      '4716e4f8ebde460e890d5eab74eb28af.s1.eu.hivemq.cloud';

  /// Cổng kết nối:
  /// - 8883: Kết nối bảo mật TLS/SSL (khuyến nghị cho production)
  /// - 1883: Kết nối không mã hóa (chỉ dùng khi test nhanh)
  static const int port = 8883;

  /// Tên đăng nhập HiveMQ Cloud.
  static String get username => dotenv.env['MQTT_USERNAME'] ?? '';

  /// Mật khẩu HiveMQ Cloud.
  static String get password => dotenv.env['MQTT_PASSWORD'] ?? '';

  /// Sử dụng kết nối bảo mật TLS/SSL hay không.
  /// Set `true` khi dùng port 8883.
  static const bool useTls = true;

  /// Thời gian keep-alive (giây).
  /// ESP32/App sẽ gửi PING mỗi 60s để duy trì kết nối.
  static const int keepAlive = 60;

  /// Thời gian chờ kết nối tối đa (giây).
  static const int connectionTimeout = 30;

  // ===========================================================================
  // MQTT TOPICS — Kiến trúc chủ đề
  // ===========================================================================

  /// Topic nhận lệnh điều khiển (App → ESP32).
  /// Payload JSON: {"cmd": "forward", "speed": 200}
  static const String topicCommand = 'smart_wheelchair/cmd';

  /// Topic gửi dữ liệu cảm biến (ESP32 → App).
  /// Payload JSON: {"distance": 45.2, "battery": 87.5, "timestamp": 1714000000}
  static const String topicSensors = 'smart_wheelchair/sensors';

  /// Topic trạng thái thiết bị (ESP32 → App, hỗ trợ LWT).
  /// Payload JSON: {"online": true, "state": "connected"}
  static const String topicStatus = 'smart_wheelchair/status';

  // ===========================================================================
  // CLIENT ID GENERATOR
  // ===========================================================================

  /// Tạo Client ID duy nhất cho mỗi phiên kết nối.
  /// HiveMQ yêu cầu mỗi client có ID riêng biệt — nếu trùng sẽ bị đá ra.
  /// Tương đương với UUID.randomUUID() trong Java.
  static String generateClientId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'xelan_app_$timestamp';
  }

  // ===========================================================================
  // LWT (Last Will and Testament) — Sẽ dùng ở Session 4
  // ===========================================================================

  /// Topic cho LWT message.
  static const String lwtTopic = topicStatus;

  /// Nội dung LWT — tự động publish khi ESP32 mất kết nối đột ngột.
  static const String lwtMessage = '{"online": false, "state": "disconnected"}';

  /// QoS cho LWT message (1 = At least once delivery).
  static const int lwtQos = 1;

  /// Retain flag cho LWT — giữ message cuối cùng trên broker.
  static const bool lwtRetain = true;
}
