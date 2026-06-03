import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/connection_service.dart';

/// ============================================================================
/// [ConnectionStatusBar] — Thanh trạng thái kết nối (WiFi/BLE)
/// ============================================================================
class ConnectionStatusBar extends StatelessWidget {
  final AppConnectionState connectionState;
  final ConnectionType connectionType;
  final bool isDeviceOnline;

  const ConnectionStatusBar({
    super.key,
    required this.connectionState,
    required this.connectionType,
    required this.isDeviceOnline,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon, text) = switch (connectionState) {
      AppConnectionState.connected => (
          AppTheme.statusOnline,
          connectionType == ConnectionType.bluetooth
              ? Icons.bluetooth_connected_rounded
              : Icons.wifi_rounded,
          connectionType == ConnectionType.bluetooth
              ? (isDeviceOnline
                  ? 'BLE · Thiết bị Online'
                  : 'BLE · Đã kết nối')
              : (isDeviceOnline
                  ? 'WiFi · Thiết bị Online'
                  : 'WiFi · Đã kết nối'),
        ),
      AppConnectionState.connecting => (
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
