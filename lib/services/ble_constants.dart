import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// ============================================================================
/// [BleConstants] — UUIDs và hằng số BLE cho SmartWheelchair
/// ============================================================================
/// Tất cả UUIDs phải khớp 100% giữa firmware ESP32 và Flutter App.
/// Sử dụng UUID v4 custom — không trùng với Bluetooth SIG reserved UUIDs.
/// ============================================================================
class BleConstants {
  BleConstants._();

  // ===========================================================================
  // BLE SERVICE & CHARACTERISTIC UUIDs
  // ===========================================================================

  /// Service UUID chính của SmartWheelchair.
  static final Guid serviceUuid =
      Guid('4fafc201-1fb5-459e-8fcc-c5c9c331914b');

  /// Characteristic: Dữ liệu cảm biến (ESP32 → App).
  /// Properties: Notify.
  /// Payload JSON: {"distance": 45.2, "battery": 87.5}
  static final Guid sensorCharUuid =
      Guid('beb5483e-36e1-4688-b7f5-ea07361b26a8');

  /// Characteristic: Lệnh điều khiển (App → ESP32).
  /// Properties: Write.
  /// Payload JSON: {"cmd": "forward", "speed": 200}
  static final Guid commandCharUuid =
      Guid('e3223119-9445-4e96-a4a1-85358c4046a2');

  /// Characteristic: Trạng thái thiết bị (ESP32 → App).
  /// Properties: Read + Notify.
  /// Payload JSON: {"online": true, "state": "connected"}
  static final Guid statusCharUuid =
      Guid('d1a7e3b5-7c8f-4a2d-9e6b-5f3c1d8e2a4b');

  // ===========================================================================
  // BLE DEVICE NAME
  // ===========================================================================

  /// Tên thiết bị BLE mà ESP32 advertise — dùng để filter khi scan.
  static const String deviceNamePrefix = 'SmartWheelchair';

  // ===========================================================================
  // SCAN CONFIG
  // ===========================================================================

  /// Thời gian quét BLE tối đa (giây).
  static const Duration scanTimeout = Duration(seconds: 10);
}
