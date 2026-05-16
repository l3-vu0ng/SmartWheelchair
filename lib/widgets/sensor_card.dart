import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// ============================================================================
/// [SensorCard] — Card hiển thị dữ liệu cảm biến (Legacy — dùng cho tương thích)
/// ============================================================================
class SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accentColor;
  final double? progressValue;
  final SensorCardStatus status;
  final bool isPrimary;

  const SensorCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.accentColor = AppTheme.primaryBlue,
    this.progressValue,
    this.status = SensorCardStatus.normal,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: isPrimary ? null : AppTheme.cardBg,
        gradient: isPrimary && status == SensorCardStatus.normal
            ? const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isPrimary ? Colors.transparent : AppTheme.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isPrimary ? AppTheme.canvasWhite : accentColor)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, size: 18,
                    color: isPrimary ? AppTheme.canvasWhite : accentColor),
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    color: isPrimary ? AppTheme.canvasWhite : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTheme.valueLg.copyWith(
                  color: isPrimary ? AppTheme.canvasWhite : AppTheme.textPrimary,
                  fontSize: 36,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: AppTheme.caption.copyWith(
                  color: isPrimary
                      ? AppTheme.canvasWhite.withValues(alpha: 0.7)
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          if (progressValue != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progressValue!.clamp(0.0, 1.0),
                backgroundColor: isPrimary
                    ? AppTheme.canvasWhite.withValues(alpha: 0.2)
                    : AppTheme.scaffoldBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPrimary ? AppTheme.canvasWhite : accentColor,
                ),
                minHeight: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum SensorCardStatus { normal, warning, danger }
