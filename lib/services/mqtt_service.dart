import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../config/mqtt_config.dart';
import '../models/sensor_data.dart';
import '../models/wheelchair_status.dart';
import 'connection_service.dart';

/// ============================================================================
/// [MqttService] — Kênh kết nối WiFi/MQTT (implements ConnectionService)
/// ============================================================================
/// Đảm nhận toàn bộ logic kết nối, subscribe, publish qua MQTT.
/// Tương đương với một Service class trong Spring Boot — UI KHÔNG ĐƯỢC
/// gọi trực tiếp mqtt client, mà phải thông qua lớp này.
///
/// Sử dụng StreamController để phát dữ liệu lên UI theo pattern Observer
/// (tương đương EventBus hoặc LiveData trong Android).
/// ============================================================================
class MqttService implements ConnectionService {
  // — MQTT Client instance —
  late MqttServerClient _client;

  // ===========================================================================
  // STREAM CONTROLLERS — Kênh phát dữ liệu lên UI
  // ===========================================================================
  // Broadcast stream cho phép nhiều widget cùng lắng nghe (multi-subscriber).
  // Tương đương PublishSubject trong RxJava.

  /// Stream dữ liệu cảm biến (khoảng cách, pin).
  final StreamController<SensorData> _sensorController =
      StreamController<SensorData>.broadcast();

  /// Stream trạng thái thiết bị (online/offline).
  final StreamController<WheelchairStatus> _statusController =
      StreamController<WheelchairStatus>.broadcast();

  /// Stream trạng thái kết nối MQTT của App.
  final StreamController<AppConnectionState> _connectionController =
      StreamController<AppConnectionState>.broadcast();

  // — Public getters cho UI subscribe —
  @override
  Stream<SensorData> get sensorStream => _sensorController.stream;
  @override
  Stream<WheelchairStatus> get statusStream => _statusController.stream;
  @override
  Stream<AppConnectionState> get connectionStream =>
      _connectionController.stream;

  /// Trạng thái kết nối hiện tại.
  AppConnectionState _connectionState = AppConnectionState.disconnected;
  @override
  AppConnectionState get connectionState => _connectionState;

  @override
  ConnectionType get type => ConnectionType.wifi;

  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSubscription;

  // ===========================================================================
  // KHỞI TẠO VÀ KẾT NỐI
  // ===========================================================================

  /// Khởi tạo MQTT client với cấu hình từ [MqttConfig].
  void _initializeClient() {
    final clientId = MqttConfig.generateClientId();
    _client = MqttServerClient.withPort(
      MqttConfig.brokerUrl,
      clientId,
      MqttConfig.port,
    );

    // — Cấu hình client —
    _client.keepAlivePeriod = MqttConfig.keepAlive;
    _client.connectTimeoutPeriod = MqttConfig.connectionTimeout * 1000;
    _client.autoReconnect = true;
    _client.resubscribeOnAutoReconnect = true;

    // — Bảo mật TLS/SSL —
    if (MqttConfig.useTls) {
      _client.secure = true;
      _client.securityContext = SecurityContext.defaultContext;
    }

    // — Logging (tắt trong production) —
    _client.logging(on: kDebugMode);

    // — Callbacks —
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onAutoReconnect = _onAutoReconnect;
    _client.onAutoReconnected = _onAutoReconnected;
    _client.onSubscribed = _onSubscribed;
  }

  /// Kết nối tới MQTT Broker.
  /// Trả về `true` nếu thành công, `false` nếu thất bại.
  /// Try-catch bọc toàn bộ — KHÔNG throw exception ra ngoài UI.
  @override
  Future<bool> connect() async {
    try {
      _initializeClient();

      // — Xây dựng message kết nối —
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(_client.clientIdentifier)
          .authenticateAs(MqttConfig.username, MqttConfig.password)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client.connectionMessage = connMessage;

      _updateConnectionState(AppConnectionState.connecting);

      debugPrint('[MqttService] Đang kết nối tới ${MqttConfig.brokerUrl}...');
      await _client.connect();

      if (_client.connectionStatus?.state ==
          MqttConnectionState.connected) {
        debugPrint('[MqttService] ✅ Kết nối thành công!');
        _subscribeToTopics();
        _listenForMessages();
        return true;
      } else {
        debugPrint('[MqttService] ❌ Kết nối thất bại: '
            '${_client.connectionStatus}');
        _client.disconnect();
        return false;
      }
    } catch (e) {
      debugPrint('[MqttService] ❌ Lỗi kết nối: $e');
      _updateConnectionState(AppConnectionState.disconnected);
      return false;
    }
  }

  /// Ngắt kết nối và giải phóng tài nguyên.
  @override
  void disconnect() {
    debugPrint('[MqttService] Ngắt kết nối...');
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    try {
      _client.disconnect();
    } catch (e) {
      // _client có thể chưa được khởi tạo nếu chưa từng gọi connect()
    }
    _updateConnectionState(AppConnectionState.disconnected);
  }

  // ===========================================================================
  // SUBSCRIBE — Đăng ký lắng nghe Topics
  // ===========================================================================

  /// Subscribe tất cả topics cần thiết.
  void _subscribeToTopics() {
    _client.subscribe(MqttConfig.topicSensors, MqttQos.atLeastOnce);
    _client.subscribe(MqttConfig.topicStatus, MqttQos.atLeastOnce);
    debugPrint('[MqttService] 📡 Đã subscribe: '
        '${MqttConfig.topicSensors}, ${MqttConfig.topicStatus}');
  }

  // ===========================================================================
  // PUBLISH — Gửi lệnh điều khiển
  // ===========================================================================

  /// Publish một lệnh điều khiển lên Topic `smart_wheelchair/cmd`.
  ///
  /// [command] — hướng di chuyển: "forward", "backward", "left", "right", "stop"
  /// [speed] — tốc độ PWM (0-255), mặc định 200.
  @override
  void sendCommand(String command, {int speed = 200}) {
    final payload = jsonEncode({
      'cmd': command,
      'speed': speed,
    });
    _publish(MqttConfig.topicCommand, payload);
    debugPrint('[MqttService] 🎮 Gửi lệnh: $payload');
  }

  /// Publish raw message lên một topic bất kỳ.
  void _publish(String topic, String message) {
    if (_connectionState != AppConnectionState.connected) {
      debugPrint('[MqttService] ⚠️ Chưa kết nối — không thể publish.');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  // ===========================================================================
  // LISTEN — Lắng nghe và phân phối dữ liệu
  // ===========================================================================

  /// Lắng nghe tất cả messages đến và phân phối vào đúng Stream.
  void _listenForMessages() {
    _updatesSubscription = _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        final topic = message.topic;
        final payload = message.payload as MqttPublishMessage;
        final payloadString = MqttPublishPayload.bytesToStringAsString(
          payload.payload.message,
        );

        debugPrint('[MqttService] 📩 [$topic]: $payloadString');

        // — Phân loại message theo topic —
        try {
          if (topic == MqttConfig.topicSensors) {
            final sensorData = SensorData.fromJson(payloadString);
            _sensorController.add(sensorData);
          } else if (topic == MqttConfig.topicStatus) {
            final status = WheelchairStatus.fromJson(payloadString);
            _statusController.add(status);
          }
        } catch (e) {
          debugPrint('[MqttService] ⚠️ Lỗi parse message: $e');
        }
      }
    });
  }

  // ===========================================================================
  // CALLBACKS — Xử lý sự kiện kết nối
  // ===========================================================================

  void _onConnected() {
    debugPrint('[MqttService] ✅ Callback: Connected');
    _updateConnectionState(AppConnectionState.connected);
  }

  void _onDisconnected() {
    debugPrint('[MqttService] ❌ Callback: Disconnected');
    _updateConnectionState(AppConnectionState.disconnected);
  }

  void _onAutoReconnect() {
    debugPrint('[MqttService] 🔄 Callback: Auto-reconnecting...');
    _updateConnectionState(AppConnectionState.connecting);
  }

  void _onAutoReconnected() {
    debugPrint('[MqttService] ✅ Callback: Auto-reconnected');
    _updateConnectionState(AppConnectionState.connected);
  }

  void _onSubscribed(String topic) {
    debugPrint('[MqttService] ✅ Subscribed: $topic');
  }

  /// Cập nhật trạng thái kết nối và phát lên Stream.
  void _updateConnectionState(AppConnectionState state) {
    _connectionState = state;
    _connectionController.add(state);
  }

  // ===========================================================================
  // CLEANUP — Giải phóng tài nguyên
  // ===========================================================================

  /// Đóng tất cả StreamControllers. Gọi khi App bị dispose.
  /// Tương đương với close() trong Java Closeable interface.
  @override
  void dispose() {
    disconnect();
    _sensorController.close();
    _statusController.close();
    _connectionController.close();
  }
}
