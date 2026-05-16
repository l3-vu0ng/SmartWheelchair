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
                const _HeartRateCard(),
                const SizedBox(height: AppTheme.spacingMd),

                // Stats row
                const _HealthStatsRow(),
                const SizedBox(height: AppTheme.spacingLg),

                // Health notifications
                Text('Thông báo sức khỏe', style: AppTheme.labelBold),
                const SizedBox(height: AppTheme.spacingSm),
                const _HealthNotification(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppTheme.statusOnline,
                  title: 'Nhịp tim ổn định trong 2 giờ qua',
                  subtitle: '10 phút trước',
                ),
                const SizedBox(height: AppTheme.spacingXs),
                const _HealthNotification(
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppTheme.warningOrange,
                  title: 'Tốc độ cao bất thường được phát hiện',
                  subtitle: '32 phút trước',
                  isWarning: true,
                ),
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
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
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
                  isFallen ? 'PHÁT HIỆN NGÃ / LẬT XE!' : 'Không có ngã nào được phát hiện',
                  style: AppTheme.labelBold.copyWith(
                    color: color,
                  ),
                ),
                Text(
                  isFallen ? 'Vui lòng kiểm tra khẩn cấp' : 'Hệ thống đang theo dõi liên tục',
                  style: AppTheme.bodySm,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              provider.triggerFallDetectionTest();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Text(
                'Thử nghiệm',
                style: AppTheme.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HEART RATE CARD (with mock chart)
// =============================================================================
class _HeartRateCard extends StatelessWidget {
  const _HeartRateCard();

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
                child: const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFFF6B6B)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nhịp tim', style: AppTheme.labelBold),
                    Text('Đo liên tục', style: AppTheme.caption),
                  ],
                ),
              ),
              Text('72', style: AppTheme.valueLg),
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
                color: AppTheme.statusOnline.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppTheme.statusOnline),
                  const SizedBox(width: 4),
                  Text(
                    'Nhịp tim bình thường',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.statusOnline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Mock chart
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _HeartRateChartPainter(),
            ),
          ),

          // Time labels
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(':00', style: AppTheme.caption),
                Text('12:00', style: AppTheme.caption),
                Text('16:00', style: AppTheme.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartRateChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.cubicTo(
      size.width * 0.1, size.height * 0.4,
      size.width * 0.15, size.height * 0.3,
      size.width * 0.2, size.height * 0.5,
    );
    path.cubicTo(
      size.width * 0.3, size.height * 0.7,
      size.width * 0.35, size.height * 0.2,
      size.width * 0.45, size.height * 0.35,
    );
    path.cubicTo(
      size.width * 0.55, size.height * 0.5,
      size.width * 0.6, size.height * 0.3,
      size.width * 0.7, size.height * 0.4,
    );
    path.cubicTo(
      size.width * 0.8, size.height * 0.5,
      size.width * 0.85, size.height * 0.45,
      size.width, size.height * 0.55,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// HEALTH STATS ROW
// =============================================================================
class _HealthStatsRow extends StatelessWidget {
  const _HealthStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.directions_walk_rounded,
            iconColor: AppTheme.primaryBlue,
            value: '2.4',
            unit: 'km',
            label: 'Quãng đường',
          ),
        ),
        const SizedBox(width: AppTheme.spacingXs),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFFF6B6B),
            value: '74',
            unit: 'bpm',
            label: 'Nhịp tim TB',
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

// =============================================================================
// HEALTH NOTIFICATION TILE
// =============================================================================
class _HealthNotification extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isWarning;

  const _HealthNotification({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: isWarning
            ? AppTheme.warningOrange.withValues(alpha: 0.06)
            : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isWarning
              ? AppTheme.warningOrange.withValues(alpha: 0.2)
              : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
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
        ],
      ),
    );
  }
}
