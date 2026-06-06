import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/sensor_data.dart';
import '../models/wheelchair_status.dart';
import 'connection_service.dart';

/// Service kết nối trực tiếp với ESP32 qua WebSocket nội bộ.
class WebSocketService implements ConnectionService {
  @override
  ConnectionType get type => ConnectionType.localWifi;

  final String _wsUrl = 'ws://192.168.4.1/ws'; // IP mặc định của ESP32 AP
  WebSocketChannel? _channel;

  // Streams controller
  final _sensorController = StreamController<SensorData>.broadcast();
  final _statusController = StreamController<WheelchairStatus>.broadcast();
  final _connectionController = StreamController<AppConnectionState>.broadcast();

  AppConnectionState _currentState = AppConnectionState.disconnected;

  @override
  Stream<SensorData> get sensorStream => _sensorController.stream;

  @override
  Stream<WheelchairStatus> get statusStream => _statusController.stream;

  @override
  Stream<AppConnectionState> get connectionStream => _connectionController.stream;

  @override
  AppConnectionState get connectionState => _currentState;

  @override
  Future<bool> connect() async {
    _updateState(AppConnectionState.connecting);

    try {
      final uri = Uri.parse(_wsUrl);
      _channel = WebSocketChannel.connect(uri);
      
      await _channel!.ready; // Đợi kết nối thành công (yêu cầu web_socket_channel ^3.0.0)

      _updateState(AppConnectionState.connected);
      _statusController.add(WheelchairStatus(isOnline: true, connectionState: 'connected', lastSeen: DateTime.now()));

      // Bắt đầu lắng nghe dữ liệu từ ESP32
      _channel!.stream.listen(
        (message) {
          _handleMessage(message.toString());
        },
        onDone: () {
          debugPrint('[WebSocket] Bị ngắt kết nối.');
          _disconnectInternal();
        },
        onError: (error) {
          debugPrint('[WebSocket] Lỗi: $error');
          _disconnectInternal();
        },
      );

      return true;
    } catch (e) {
      debugPrint('[WebSocket] Lỗi kết nối tới $_wsUrl: $e');
      _disconnectInternal();
      return false;
    }
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message);
      
      // Xử lý dữ liệu cảm biến
      if (data.containsKey('distance') || data.containsKey('battery')) {
        final distance = (data['distance'] as num?)?.toDouble() ?? 0.0;
        final battery = (data['battery'] as num?)?.toDouble() ?? 0.0;
        
        _sensorController.add(SensorData(
          obstacleDistance: distance,
          batteryLevel: battery,
          latitude: null, // WebSocket không cần thiết truyền GPS trừ khi ESP32 có module GPS
          longitude: null,
          timestamp: DateTime.now(),
        ));
      }

      // Xử lý các trạng thái khác nếu có
    } catch (e) {
      debugPrint('[WebSocket] Lỗi parse JSON: $e, message: $message');
    }
  }

  @override
  void sendCommand(String command, {int speed = 200}) {
    if (_currentState != AppConnectionState.connected || _channel == null) {
      return;
    }

    // Gửi dưới dạng JSON tương thích với các chế độ trước
    final payload = {
      'cmd': command,
      'speed': speed,
    };
    
    _channel!.sink.add(jsonEncode(payload));
  }

  @override
  void disconnect() {
    _disconnectInternal();
  }

  void _disconnectInternal() {
    if (_currentState == AppConnectionState.disconnected) return;
    
    _channel?.sink.close();
    _channel = null;
    
    _updateState(AppConnectionState.disconnected);
    _statusController.add(WheelchairStatus(isOnline: false, connectionState: 'disconnected', lastSeen: DateTime.now()));
  }

  void _updateState(AppConnectionState state) {
    _currentState = state;
    if (!_connectionController.isClosed) {
      _connectionController.add(state);
    }
  }

  @override
  void dispose() {
    _disconnectInternal();
    _sensorController.close();
    _statusController.close();
    _connectionController.close();
  }
}
