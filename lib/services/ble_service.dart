import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/sensor_data.dart';
import '../models/wheelchair_status.dart';
import 'ble_constants.dart';
import 'connection_service.dart';

/// ============================================================================
/// [BleService] — Kênh kết nối Bluetooth Low Energy (implements ConnectionService)
/// ============================================================================
/// Giao tiếp trực tiếp App ↔ ESP32 qua BLE GATT Protocol.
/// Không cần WiFi hay MQTT Broker — phù hợp khi offline hoặc phạm vi gần.
///
/// Luồng hoạt động:
///   1. Scan thiết bị BLE → lọc theo tên "SmartWheelchair"
///   2. Kết nối → Discover GATT Services
///   3. Enable Notify trên Sensor + Status characteristics
///   4. Write command vào Command characteristic
/// ============================================================================
class BleService implements ConnectionService {
  // — BLE Device đang kết nối —
  BluetoothDevice? _device;

  // — GATT Characteristics cache —
  BluetoothCharacteristic? _sensorChar;
  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _statusChar;

  // ===========================================================================
  // STREAM CONTROLLERS
  // ===========================================================================

  final StreamController<SensorData> _sensorController =
      StreamController<SensorData>.broadcast();

  final StreamController<WheelchairStatus> _statusController =
      StreamController<WheelchairStatus>.broadcast();

  final StreamController<AppConnectionState> _connectionController =
      StreamController<AppConnectionState>.broadcast();

  @override
  Stream<SensorData> get sensorStream => _sensorController.stream;
  @override
  Stream<WheelchairStatus> get statusStream => _statusController.stream;
  @override
  Stream<AppConnectionState> get connectionStream =>
      _connectionController.stream;

  AppConnectionState _connectionState = AppConnectionState.disconnected;
  @override
  AppConnectionState get connectionState => _connectionState;

  @override
  ConnectionType get type => ConnectionType.bluetooth;

  // — Stream subscriptions —
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _sensorNotifySub;
  StreamSubscription<List<int>>? _statusNotifySub;

  // ===========================================================================
  // SCAN — Quét thiết bị BLE
  // ===========================================================================

  /// Bắt đầu quét thiết bị BLE.
  /// Trả về Stream các thiết bị tìm thấy, lọc theo tên "SmartWheelchair".
  Stream<List<ScanResult>> startScan() {
    FlutterBluePlus.startScan(
      timeout: BleConstants.scanTimeout,
      withServices: [BleConstants.serviceUuid],
    );

    return FlutterBluePlus.scanResults;
  }

  /// Dừng quét.
  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  // ===========================================================================
  // KẾT NỐI
  // ===========================================================================

  /// Gán thiết bị BLE cần kết nối (gọi trước connect()).
  void setDevice(BluetoothDevice device) {
    _device = device;
  }

  /// Kết nối tới thiết bị BLE đã được gán qua [setDevice].
  @override
  Future<bool> connect() async {
    if (_device == null) {
      debugPrint('[BleService] ❌ Chưa chọn thiết bị — gọi setDevice() trước.');
      return false;
    }

    try {
      _updateConnectionState(AppConnectionState.connecting);
      debugPrint('[BleService] Đang kết nối tới ${_device!.platformName}...');

      await _device!.connect(timeout: const Duration(seconds: 15));

      // Lắng nghe trạng thái kết nối BLE
      _connectionSub = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint('[BleService] ❌ BLE Disconnected');
          _updateConnectionState(AppConnectionState.disconnected);
          _cleanupCharacteristics();
        }
      });

      // Discover GATT services
      final services = await _device!.discoverServices();
      final targetService = services.firstWhere(
        (s) => s.serviceUuid == BleConstants.serviceUuid,
        orElse: () => throw Exception('Service SmartWheelchair không tìm thấy'),
      );

      // Tìm các characteristics
      for (final char in targetService.characteristics) {
        if (char.characteristicUuid == BleConstants.sensorCharUuid) {
          _sensorChar = char;
        } else if (char.characteristicUuid == BleConstants.commandCharUuid) {
          _commandChar = char;
        } else if (char.characteristicUuid == BleConstants.statusCharUuid) {
          _statusChar = char;
        }
      }

      if (_sensorChar == null || _commandChar == null) {
        throw Exception('Thiếu characteristics cần thiết');
      }

      // Enable notifications
      await _enableNotifications();

      _updateConnectionState(AppConnectionState.connected);
      debugPrint('[BleService] ✅ Kết nối BLE thành công!');
      return true;
    } catch (e) {
      debugPrint('[BleService] ❌ Lỗi kết nối BLE: $e');
      _updateConnectionState(AppConnectionState.disconnected);
      return false;
    }
  }

  /// Ngắt kết nối BLE.
  @override
  void disconnect() {
    debugPrint('[BleService] Ngắt kết nối BLE...');
    _sensorNotifySub?.cancel();
    _statusNotifySub?.cancel();
    _connectionSub?.cancel();

    try {
      _device?.disconnect();
    } catch (e) {
      debugPrint('[BleService] ⚠️ Lỗi khi disconnect: $e');
    }

    _cleanupCharacteristics();
    _updateConnectionState(AppConnectionState.disconnected);
  }

  // ===========================================================================
  // NOTIFY — Lắng nghe dữ liệu từ ESP32
  // ===========================================================================

  /// Enable notifications cho Sensor và Status characteristics.
  Future<void> _enableNotifications() async {
    // Sensor notifications
    if (_sensorChar != null) {
      await _sensorChar!.setNotifyValue(true);
      _sensorNotifySub = _sensorChar!.lastValueStream.listen((value) {
        if (value.isEmpty) return;
        try {
          final jsonString = utf8.decode(value);
          final sensorData = SensorData.fromJson(jsonString);
          _sensorController.add(sensorData);
          debugPrint('[BleService] 📩 Sensor: $jsonString');
        } catch (e) {
          debugPrint('[BleService] ⚠️ Lỗi parse sensor BLE: $e');
        }
      });
    }

    // Status notifications
    if (_statusChar != null) {
      await _statusChar!.setNotifyValue(true);
      _statusNotifySub = _statusChar!.lastValueStream.listen((value) {
        if (value.isEmpty) return;
        try {
          final jsonString = utf8.decode(value);
          final status = WheelchairStatus.fromJson(jsonString);
          _statusController.add(status);
          debugPrint('[BleService] 📩 Status: $jsonString');
        } catch (e) {
          debugPrint('[BleService] ⚠️ Lỗi parse status BLE: $e');
        }
      });
    }
  }

  // ===========================================================================
  // WRITE — Gửi lệnh điều khiển qua BLE
  // ===========================================================================

  @override
  void sendCommand(String command, {int speed = 200}) {
    if (_connectionState != AppConnectionState.connected) {
      debugPrint('[BleService] ⚠️ Chưa kết nối — không thể gửi lệnh.');
      return;
    }

    if (_commandChar == null) {
      debugPrint('[BleService] ⚠️ Command characteristic chưa sẵn sàng.');
      return;
    }

    final payload = jsonEncode({
      'cmd': command,
      'speed': speed,
    });

    final bytes = utf8.encode(payload);
    _commandChar!.write(bytes, withoutResponse: true);
    debugPrint('[BleService] 🎮 Gửi lệnh BLE: $payload');
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  void _updateConnectionState(AppConnectionState state) {
    _connectionState = state;
    _connectionController.add(state);
  }

  void _cleanupCharacteristics() {
    _sensorChar = null;
    _commandChar = null;
    _statusChar = null;
  }

  // ===========================================================================
  // CLEANUP
  // ===========================================================================

  @override
  void dispose() {
    disconnect();
    _sensorController.close();
    _statusController.close();
    _connectionController.close();
  }
}
