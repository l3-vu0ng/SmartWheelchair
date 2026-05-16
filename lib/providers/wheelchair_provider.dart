import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../models/sensor_data.dart';
import '../models/wheelchair_status.dart';
import '../services/mqtt_service.dart';

/// ============================================================================
/// [WheelchairProvider] — ChangeNotifier bridge giữa MqttService và UI
/// ============================================================================
/// Đây là lớp trung gian theo pattern Observer (tương đương ViewModel trong
/// Android MVVM hoặc Controller trong MVC Java Swing).
///
/// Hỗ trợ 2 chế độ:
/// - **Live mode**: Kết nối MQTT Broker thật (dùng trên mobile/desktop)
/// - **Demo mode**: Giả lập dữ liệu cảm biến (dùng để test UI trên web/emulator)
/// ============================================================================
class WheelchairProvider extends ChangeNotifier {
  final MqttService _mqttService;

  // — State fields —
  SensorData? _sensorData;
  WheelchairStatus _status = WheelchairStatus.initial();
  MqttConnectionState _connectionState = MqttConnectionState.disconnected;
  String? _errorMessage;
  bool _isConnecting = false;
  bool _isFallen = false;

  // — Demo mode —
  bool _isDemoMode = false;
  Timer? _demoTimer;
  final Random _random = Random();

  // — Stream subscriptions (cần cancel khi dispose) —
  StreamSubscription<SensorData>? _sensorSub;
  StreamSubscription<WheelchairStatus>? _statusSub;
  StreamSubscription<MqttConnectionState>? _connectionSub;

  // ===========================================================================
  // CONSTRUCTOR — Inject MqttService
  // ===========================================================================

  WheelchairProvider({required MqttService mqttService})
      : _mqttService = mqttService {
    _listenToStreams();
  }

  // ===========================================================================
  // PUBLIC GETTERS — UI truy cập state qua đây
  // ===========================================================================

  /// Dữ liệu cảm biến mới nhất (null nếu chưa nhận).
  SensorData? get sensorData => _sensorData;

  /// Trạng thái thiết bị ESP32.
  WheelchairStatus get deviceStatus => _status;

  /// Trạng thái kết nối MQTT của App.
  MqttConnectionState get connectionState => _connectionState;

  /// Đang trong quá trình kết nối hay không.
  bool get isConnecting => _isConnecting;

  /// Đã kết nối thành công hay chưa.
  bool get isConnected => _connectionState == MqttConnectionState.connected;

  /// Thông báo lỗi (null nếu không có lỗi).
  String? get errorMessage => _errorMessage;

  /// Khoảng cách vật cản (0 nếu chưa có data).
  double get obstacleDistance => _sensorData?.obstacleDistance ?? 0.0;

  /// Mức pin (0 nếu chưa có data).
  double get batteryLevel => _sensorData?.batteryLevel ?? 0.0;

  /// Thiết bị online hay không.
  bool get isDeviceOnline => _status.isOnline;

  /// Đang ở chế độ demo hay không.
  bool get isDemoMode => _isDemoMode;

  /// Cảnh báo ngã.
  bool get isFallen => _isFallen;

  // ===========================================================================
  // ACTIONS — UI gọi các hàm này để thực hiện hành động
  // ===========================================================================

  /// Kết nối tới MQTT Broker (live mode).
  Future<void> connectToBroker() async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _mqttService.connect();

    _isConnecting = false;
    if (!success) {
      _errorMessage = 'Không thể kết nối MQTT Broker. Kiểm tra mạng.';
    }
    notifyListeners();
  }

  /// Ngắt kết nối.
  void disconnectFromBroker() {
    if (_isDemoMode) {
      _stopDemoMode();
    } else {
      _mqttService.disconnect();
    }
    _sensorData = null;
    _status = WheelchairStatus.initial();
    _connectionState = MqttConnectionState.disconnected;
    notifyListeners();
  }

  /// Bật chế độ Demo — giả lập dữ liệu cảm biến để test UI.
  /// Hữu ích khi chạy trên web/emulator không có MQTT.
  void startDemoMode() {
    _isDemoMode = true;
    _connectionState = MqttConnectionState.connected;
    _status = WheelchairStatus(
      isOnline: true,
      connectionState: 'connected (demo)',
      lastSeen: DateTime.now(),
    );
    notifyListeners();

    // Phát dữ liệu giả lập mỗi 800ms
    _demoTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _generateMockSensorData();
    });

    debugPrint('[Demo] 🎭 Chế độ demo đã bật — dữ liệu giả lập.');
  }

  /// Gửi lệnh điều khiển xe lăn.
  void sendCommand(String direction, {int speed = 200}) {
    if (!isConnected) {
      _errorMessage = 'Chưa kết nối — không thể gửi lệnh.';
      notifyListeners();
      return;
    }

    if (_isDemoMode) {
      debugPrint('[Demo] 🎮 Lệnh: $direction | Tốc độ: $speed');
      return; // Demo mode không gửi MQTT thật
    }

    _mqttService.sendCommand(direction, speed: speed);
  }

  /// Xóa thông báo lỗi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Mô phỏng sự kiện ngã.
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
  // PRIVATE — Demo Mode Data Generator
  // ===========================================================================

  /// Tạo dữ liệu cảm biến giả lập thay đổi tự nhiên.
  void _generateMockSensorData() {
    // Khoảng cách dao động 10-200cm với biến thiên nhỏ
    final baseDistance = _sensorData?.obstacleDistance ?? 100.0;
    final variation = (_random.nextDouble() - 0.5) * 20; // ±10cm
    final newDistance = (baseDistance + variation).clamp(5.0, 200.0);

    // Pin giảm dần chậm (giả lập)
    final baseBattery = _sensorData?.batteryLevel ?? 85.0;
    final newBattery = (baseBattery - _random.nextDouble() * 0.1).clamp(10.0, 100.0);

    _sensorData = SensorData(
      obstacleDistance: double.parse(newDistance.toStringAsFixed(1)),
      batteryLevel: double.parse(newBattery.toStringAsFixed(1)),
      timestamp: DateTime.now(),
    );
    notifyListeners();
  }

  /// Dừng chế độ demo.
  void _stopDemoMode() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _isDemoMode = false;
    debugPrint('[Demo] 🎭 Chế độ demo đã tắt.');
  }

  // ===========================================================================
  // PRIVATE — Lắng nghe Streams từ MqttService
  // ===========================================================================

  void _listenToStreams() {
    _sensorSub = _mqttService.sensorStream.listen((data) {
      _sensorData = data;
      notifyListeners();
    });

    _statusSub = _mqttService.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });

    _connectionSub = _mqttService.connectionStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });
  }

  // ===========================================================================
  // DISPOSE — Giải phóng tài nguyên
  // ===========================================================================

  @override
  void dispose() {
    _demoTimer?.cancel();
    _sensorSub?.cancel();
    _statusSub?.cancel();
    _connectionSub?.cancel();
    _mqttService.dispose();
    super.dispose();
  }
}
