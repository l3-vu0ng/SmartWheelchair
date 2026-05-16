import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/wheelchair_provider.dart';

/// ============================================================================
/// [HomeTab] — Trang chủ Dashboard
/// ============================================================================
/// Hiển thị: Hero card (tốc độ + pin), stat cards (nhịp tim, năng lượng),
/// và Quick Access shortcuts.
/// ============================================================================
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

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
                // --- Header ---
                _HomeHeader(provider: provider),
                const SizedBox(height: AppTheme.spacingLg),

                // --- Hero Status Card ---
                _HeroCard(provider: provider),
                const SizedBox(height: AppTheme.spacingMd),

                // --- Stat Cards Row ---
                _StatCardsRow(provider: provider),
                const SizedBox(height: AppTheme.spacingLg),

                // --- Quick Access ---
                Text('TRUY CẬP NHANH', style: AppTheme.sectionLabel),
                const SizedBox(height: AppTheme.spacingSm),
                const _QuickAccessList(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// HEADER — Xin chào + Trạng thái kết nối
// =============================================================================
class _HomeHeader extends StatelessWidget {
  final WheelchairProvider provider;
  const _HomeHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Xin chào 👋', style: AppTheme.bodySm),
              Text('SmartWheel', style: AppTheme.headlineLg),
            ],
          ),
        ),
        // Connection indicator
        GestureDetector(
          onTap: () {
            if (provider.isConnected) {
              provider.disconnectFromBroker();
            } else if (!provider.isDemoMode) {
              provider.startDemoMode();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: provider.isConnected
                  ? AppTheme.statusOnline.withValues(alpha: 0.1)
                  : AppTheme.scaffoldBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(
                color: provider.isConnected
                    ? AppTheme.statusOnline.withValues(alpha: 0.3)
                    : AppTheme.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_rounded,
                  size: 16,
                  color: provider.isConnected
                      ? AppTheme.statusOnline
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  provider.isConnected ? 'Đã kết nối' : 'Demo',
                  style: AppTheme.caption.copyWith(
                    color: provider.isConnected
                        ? AppTheme.statusOnline
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// HERO CARD — Tốc độ + Pin + Vị trí
// =============================================================================
class _HeroCard extends StatelessWidget {
  final WheelchairProvider provider;
  const _HeroCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final battery = provider.batteryLevel;
    final distance = provider.obstacleDistance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Tốc độ + Pin
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tốc độ hiện tại',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.canvasWhite.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        provider.isConnected ? '3.2' : '--',
                        style: AppTheme.valueLg.copyWith(
                          color: AppTheme.canvasWhite,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'km/h',
                        style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.canvasWhite.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Battery
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Pin xe lăn',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.canvasWhite.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Battery bar
                      Container(
                        width: 60,
                        height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.canvasWhite.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: battery > 0 ? (battery / 100).clamp(0, 1) : 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.canvasWhite,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        battery > 0 ? '${battery.toStringAsFixed(0)}%' : '--%',
                        style: AppTheme.labelBold.copyWith(
                          color: AppTheme.canvasWhite,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Bottom chips
          Row(
            children: [
              _HeroChip(
                icon: Icons.location_on_outlined,
                label: provider.isConnected ? 'Đang hoạt động' : 'Chờ kết nối',
              ),
              const SizedBox(width: AppTheme.spacingXs),
              _HeroChip(
                icon: Icons.straighten_rounded,
                label: distance > 0
                    ? '${distance.toStringAsFixed(1)} cm phía trước'
                    : 'Không có dữ liệu',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.canvasWhite.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.canvasWhite),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: AppTheme.canvasWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STAT CARDS — Nhịp tim + Năng lượng
// =============================================================================
class _StatCardsRow extends StatelessWidget {
  final WheelchairProvider provider;
  const _StatCardsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFFF6B6B),
            iconBgColor: const Color(0xFFFFEBEB),
            label: 'Nhịp tim',
            value: provider.isConnected ? '72' : '--',
            unit: 'bpm',
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: _StatCard(
            icon: Icons.battery_charging_full_rounded,
            iconColor: AppTheme.primaryBlue,
            iconBgColor: AppTheme.primaryBlueLight,
            label: 'Năng lượng',
            value: provider.batteryLevel > 0
                ? provider.batteryLevel.toStringAsFixed(0)
                : '--',
            unit: '%',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String value;
  final String unit;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(label, style: AppTheme.bodySm),
          const SizedBox(height: AppTheme.spacingXxs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTheme.valueMd),
              const SizedBox(width: 4),
              Text(unit, style: AppTheme.bodySm),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// QUICK ACCESS LIST
// =============================================================================
class _QuickAccessList extends StatelessWidget {
  const _QuickAccessList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuickAccessTile(
          icon: Icons.gamepad_rounded,
          iconColor: AppTheme.primaryBlue,
          title: 'Điều khiển xe lăn',
          subtitle: 'Joystick & giọng nói',
        ),
        const SizedBox(height: AppTheme.spacingXs),
        _QuickAccessTile(
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFFF6B6B),
          title: 'Theo dõi sức khỏe',
          subtitle: 'Nhịp tim, cảnh báo ngã',
        ),
        const SizedBox(height: AppTheme.spacingXs),
        _QuickAccessTile(
          icon: Icons.near_me_rounded,
          iconColor: AppTheme.primaryBlue,
          title: 'Điều hướng',
          subtitle: 'Tìm lối đi phù hợp',
        ),
      ],
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _QuickAccessTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.labelBold),
                Text(subtitle, style: AppTheme.bodySm),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}
