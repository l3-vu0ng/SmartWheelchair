import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/sensor_data.dart';
import '../models/wheelchair_status.dart';
import '../services/ble_service.dart';
import '../services/connection_service.dart';
import '../services/mqtt_service.dart';

/// ============================================================================
/// [WheelchairProvider] — ChangeNotifier bridge giữa ConnectionService và UI
/// ============================================================================
/// Lớp trung gian theo pattern Observer (tương đương ViewModel trong
/// Android MVVM hoặc Controller trong MVC Java Swing).
///
/// Hỗ trợ 2 kênh kết nối thực tế:
/// - **WiFi mode**: Kết nối MQTT Broker (HiveMQ Cloud) qua Internet.
/// - **BLE mode**: Kết nối trực tiếp App ↔ ESP32 qua Bluetooth Low Energy.
/// ============================================================================
class WheelchairProvider extends ChangeNotifier {
  // — Active connection service (WiFi hoặc BLE) —
  ConnectionService? _activeConnection;

  // — State fields —
  SensorData? _sensorData;
  WheelchairStatus _status = WheelchairStatus.initial();
  AppConnectionState _connectionState = AppConnectionState.disconnected;
  ConnectionType _connectionType = ConnectionType.none;
  String? _errorMessage;
  bool _isConnecting = false;
  bool _isFallen = false;

  // — Stream subscriptions (cần cancel khi switch kết nối) —
  StreamSubscription<SensorData>? _sensorSub;
  StreamSubscription<WheelchairStatus>? _statusSub;
  StreamSubscription<AppConnectionState>? _connectionSub;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  WheelchairProvider();

  // ===========================================================================
  // PUBLIC GETTERS — UI truy cập state qua đây
  // ===========================================================================

  /// Dữ liệu cảm biến mới nhất (null nếu chưa nhận).
  SensorData? get sensorData => _sensorData;

  /// Trạng thái thiết bị ESP32.
  WheelchairStatus get deviceStatus => _status;

  /// Trạng thái kết nối của App.
  AppConnectionState get connectionState => _connectionState;

  /// Loại kết nối hiện tại (WiFi / Bluetooth / None).
  ConnectionType get connectionType => _connectionType;

  /// Đang trong quá trình kết nối hay không.
  bool get isConnecting => _isConnecting;

  /// Đã kết nối thành công hay chưa.
  bool get isConnected => _connectionState == AppConnectionState.connected;

  /// Thông báo lỗi (null nếu không có lỗi).
  String? get errorMessage => _errorMessage;

  /// Khoảng cách vật cản (0 nếu chưa có data).
  double get obstacleDistance => _sensorData?.obstacleDistance ?? 0.0;

  /// Mức pin (0 nếu chưa có data).
  double get batteryLevel => _sensorData?.batteryLevel ?? 0.0;

  /// Thiết bị online hay không.
  bool get isDeviceOnline => _status.isOnline;

  /// Cảnh báo ngã.
  bool get isFallen => _isFallen;

  // ===========================================================================
  // ACTIONS — Kết nối WiFi (MQTT)
  // ===========================================================================

  /// Kết nối tới MQTT Broker qua WiFi.
  Future<void> connectViaMqtt() async {
    // Ngắt kết nối cũ nếu có
    _disconnectCurrent();

    _isConnecting = true;
    _errorMessage = null;
    _connectionType = ConnectionType.wifi;
    notifyListeners();

    final mqttService = MqttService();
    _activeConnection = mqttService;
    _listenToStreams(mqttService);

    final success = await mqttService.connect();

    _isConnecting = false;
    if (!success) {
      _errorMessage = 'Không thể kết nối MQTT Broker. Kiểm tra mạng WiFi.';
      _connectionType = ConnectionType.none;
      _sensorSub?.cancel();
      _statusSub?.cancel();
      _connectionSub?.cancel();
      mqttService.dispose();
      _activeConnection = null;
    }
    notifyListeners();
  }

  // ===========================================================================
  // ACTIONS — Kết nối BLE (Bluetooth)
  // ===========================================================================

  /// Kết nối tới thiết bị ESP32 qua Bluetooth Low Energy.
  Future<void> connectViaBle(BluetoothDevice device) async {
    // Ngắt kết nối cũ nếu có
    _disconnectCurrent();

    _isConnecting = true;
    _errorMessage = null;
    _connectionType = ConnectionType.bluetooth;
    notifyListeners();

    final bleService = BleService();
    bleService.setDevice(device);
    _activeConnection = bleService;
    _listenToStreams(bleService);

    final success = await bleService.connect();

    _isConnecting = false;
    if (!success) {
      _errorMessage =
          'Không thể kết nối Bluetooth. Kiểm tra thiết bị có bật BLE.';
      _connectionType = ConnectionType.none;
      _sensorSub?.cancel();
      _statusSub?.cancel();
      _connectionSub?.cancel();
      bleService.dispose();
      _activeConnection = null;
    }
    notifyListeners();
  }

  // ===========================================================================
  // ACTIONS — Ngắt kết nối
  // ===========================================================================

  /// Ngắt kết nối hiện tại (bất kể WiFi hay BLE).
  void disconnectAll() {
    _disconnectCurrent();
    _sensorData = null;
    _status = WheelchairStatus.initial();
    _connectionState = AppConnectionState.disconnected;
    _connectionType = ConnectionType.none;
    notifyListeners();
  }

  // ===========================================================================
  // ACTIONS — Gửi lệnh điều khiển
  // ===========================================================================

  /// Gửi lệnh điều khiển xe lăn qua kênh đang kết nối.
  void sendCommand(String direction, {int speed = 200}) {
    if (!isConnected) {
      _errorMessage = 'Chưa kết nối — không thể gửi lệnh.';
      notifyListeners();
      return;
    }

    _activeConnection?.sendCommand(direction, speed: speed);
  }

  /// Xóa thông báo lỗi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Mô phỏng sự kiện ngã (dùng cho test).
  void triggerFallDetectionTest() {
    _isFallen = true;
    notifyListeners();
  }

  /// Xóa trạng thái ngã.
  void clearFallDetection() {
    _isFallen = false;
    notifyListeners();
  }

  // ===========================================================================
  // PRIVATE — Quản lý kết nối
  // ===========================================================================

  /// Ngắt kết nối hiện tại và cancel stream subscriptions.
  void _disconnectCurrent() {
    _sensorSub?.cancel();
    _statusSub?.cancel();
    _connectionSub?.cancel();
    _activeConnection?.dispose();
    _activeConnection = null;
  }

  /// Lắng nghe Streams từ ConnectionService.
  void _listenToStreams(ConnectionService service) {
    _sensorSub = service.sensorStream.listen((data) {
      _sensorData = data;
      notifyListeners();
    });

    _statusSub = service.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });

    _connectionSub = service.connectionStream.listen((state) {
      _connectionState = state;

      // Nếu mất kết nối bất ngờ → reset connection type
      if (state == AppConnectionState.disconnected) {
        _connectionType = ConnectionType.none;
        _activeConnection = null;
      }
      notifyListeners();
    });
  }

  // ===========================================================================
  // DISPOSE — Giải phóng tài nguyên
  // ===========================================================================

  @override
  void dispose() {
    _disconnectCurrent();
    super.dispose();
  }
}
