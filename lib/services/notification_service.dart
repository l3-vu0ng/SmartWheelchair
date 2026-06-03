import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Thêm để dùng Color

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Khởi tạo cho Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Khởi tạo cho iOS (Nều cần)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      // V21.0.0 dùng named arguments
      settings: initializationSettings, 
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng chạm vào thông báo (nếu cần)
      },
    );

    _isInitialized = true;
  }

  /// Bắn thông báo Local Notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      // Local notifications không được hỗ trợ chính thức trên Web thông qua plugin này
      debugPrint('Web Notification (Bypassed): $title - $body');
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'vpc_smartwheelchair_channel_1',
      'Cảnh báo an toàn',
      channelDescription: 'Kênh thông báo các cảnh báo nguy hiểm từ xe lăn',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Color(0xFFEF4444), // AppTheme.statusOffline red
      ledColor: Color(0xFFEF4444),
      ledOnMs: 1000,
      ledOffMs: 500,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }
}
