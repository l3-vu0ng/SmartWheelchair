import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../providers/wheelchair_provider.dart';
import '../services/connection_service.dart';
import 'ble_scan_dialog.dart';

/// ============================================================================
/// [ConnectionDialog] — Bottom Sheet lựa chọn phương thức kết nối
/// ============================================================================
/// Hiển thị 2 lựa chọn: WiFi (MQTT) và Bluetooth (BLE).
/// Gọi từ nút kết nối trên Home Header hoặc Control Header.
/// ============================================================================
class ConnectionDialog {
  ConnectionDialog._();

  /// Hiển thị dialog lựa chọn phương thức kết nối.
  static void show(BuildContext context) {
    final provider = context.read<WheelchairProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: const BoxDecoration(
          color: AppTheme.canvasWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Title
            Text('Chọn phương thức kết nối', style: AppTheme.headlineMd),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Kết nối với xe lăn thông minh',
              style: AppTheme.bodySm,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // WiFi Option
            _ConnectionOption(
              icon: Icons.wifi_rounded,
              iconColor: AppTheme.primaryBlue,
              title: 'WiFi (MQTT)',
              subtitle: 'Kết nối qua Internet · HiveMQ Cloud',
              isActive: provider.connectionType == ConnectionType.wifi,
              onTap: () {
                Navigator.of(ctx).pop();
                provider.connectViaMqtt();
              },
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // Bluetooth Option
            _ConnectionOption(
              icon: Icons.bluetooth_rounded,
              iconColor: const Color(0xFF7C3AED),
              title: 'Bluetooth (BLE)',
              subtitle: 'Kết nối trực tiếp · Phạm vi ~10m',
              isActive:
                  provider.connectionType == ConnectionType.bluetooth,
              onTap: () {
                Navigator.of(ctx).pop();
                BleScanDialog.show(context);
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }
}

/// Một option trong Connection Dialog.
class _ConnectionOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _ConnectionOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isActive
              ? iconColor.withValues(alpha: 0.06)
              : AppTheme.scaffoldBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isActive
                ? iconColor.withValues(alpha: 0.3)
                : AppTheme.borderLight,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.labelBold),
                  Text(subtitle, style: AppTheme.caption),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.statusOnline.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  'Đang kết nối',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.statusOnline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
