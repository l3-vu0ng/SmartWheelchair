import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/wheelchair_provider.dart';

/// ============================================================================
/// [HealthTab] — Theo dõi sức khỏe
/// ============================================================================
class HealthTab extends StatelessWidget {
  const HealthTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WheelchairProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text('SỨC KHỎE', style: AppTheme.sectionLabel),
                Text('Theo dõi sức khỏe', style: AppTheme.headlineLg),
                const SizedBox(height: AppTheme.spacingLg),

                // Fall detection banner
                _FallDetectionBanner(provider: provider),
                const SizedBox(height: AppTheme.spacingMd),

                // Heart rate card
                _HeartRateCard(provider: provider),
                const SizedBox(height: AppTheme.spacingMd),

                // Stats row
                _HealthStatsRow(provider: provider),
                const SizedBox(height: AppTheme.spacingLg),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// FALL DETECTION BANNER
// =============================================================================
class _FallDetectionBanner extends StatelessWidget {
  final WheelchairProvider provider;
  const _FallDetectionBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isFallen = provider.isFallen;
    final color = isFallen ? AppTheme.statusOffline : AppTheme.statusOnline;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFallen ? Icons.warning_amber_rounded : Icons.shield_outlined,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFallen
                      ? 'PHÁT HIỆN NGÃ / LẬT XE!'
                      : 'Không có sự cố ngã / lật xe nào được phát hiện',
                  style: AppTheme.labelBold.copyWith(color: color),
                ),
                Text(
                  isFallen
                      ? 'Vui lòng kiểm tra khẩn cấp'
                      : 'Hệ thống đang theo dõi liên tục',
                  style: AppTheme.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HEART RATE CARD
// =============================================================================
class _HeartRateCard extends StatelessWidget {
  final WheelchairProvider provider;
  const _HeartRateCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nhịp tim', style: AppTheme.labelBold),
                    Text(
                      provider.sensorData?.heartRate != null
                          ? 'Cập nhật liên tục'
                          : 'Đang chờ dữ liệu...',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
              Text(
                provider.sensorData?.heartRate?.toString() ?? '--',
                style: AppTheme.valueLg,
              ),
              const SizedBox(width: 4),
              Text('bpm', style: AppTheme.bodySm),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Status chip
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    (provider.sensorData?.heartRate != null
                            ? AppTheme.statusOnline
                            : AppTheme.textSecondary)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.sensorData?.heartRate != null
                        ? Icons.sensors_rounded
                        : Icons.sensors_off_rounded,
                    size: 14,
                    color: provider.sensorData?.heartRate != null
                        ? AppTheme.statusOnline
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    provider.sensorData?.heartRate != null
                        ? 'Cảm biến MAX30102 đang hoạt động'
                        : 'Chưa kết nối cảm biến nhịp tim',
                    style: AppTheme.caption.copyWith(
                      color: provider.sensorData?.heartRate != null
                          ? AppTheme.statusOnline
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HEALTH STATS ROW
// =============================================================================
class _HealthStatsRow extends StatelessWidget {
  final WheelchairProvider provider;
  const _HealthStatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.water_drop_rounded,
            iconColor: Colors.blueAccent,
            value: provider.sensorData?.spo2?.toString() ?? '--',
            unit: '%',
            label: 'Nồng độ oxy SpO2',
          ),
        ),
        const SizedBox(width: AppTheme.spacingXs),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.monitor_heart_rounded,
            iconColor: const Color(0xFFFF6B6B),
            value: provider.sensorData?.heartRate?.toString() ?? '--',
            unit: 'bpm',
            label: 'Nhịp tim',
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;

  const _MiniStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.valueMd.copyWith(fontSize: 20)),
          Text(unit, style: AppTheme.caption),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.caption),
        ],
      ),
    );
  }
}
