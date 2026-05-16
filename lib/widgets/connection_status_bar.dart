import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../config/app_theme.dart';

/// ============================================================================
/// [ConnectionStatusBar] — Thanh trạng thái kết nối MQTT
/// ============================================================================
class ConnectionStatusBar extends StatelessWidget {
  final MqttConnectionState connectionState;
  final bool isDeviceOnline;

  const ConnectionStatusBar({
    super.key,
    required this.connectionState,
    required this.isDeviceOnline,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon, text) = switch (connectionState) {
      MqttConnectionState.connected => (
          AppTheme.statusOnline,
          Icons.wifi_rounded,
          isDeviceOnline ? 'Đã kết nối · Thiết bị Online' : 'Đã kết nối · Chờ thiết bị',
        ),
      MqttConnectionState.connecting => (
          AppTheme.statusConnecting,
          Icons.sync_rounded,
          'Đang kết nối...',
        ),
      _ => (
          AppTheme.textSecondary,
          Icons.wifi_off_rounded,
          'Chưa kết nối',
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
