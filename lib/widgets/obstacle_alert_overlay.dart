import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// ============================================================================
/// [ObstacleAlertOverlay] — Lớp cảnh báo vật cản
/// ============================================================================
class ObstacleAlertOverlay extends StatelessWidget {
  final double distance;
  final Widget child;

  const ObstacleAlertOverlay({
    super.key,
    required this.distance,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isAlert = distance > 0 && distance < 15;

    return Stack(
      children: [
        child,
        if (isAlert)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.statusOffline.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.statusOffline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.statusOffline, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠ VẬT CẢN GẦN — ${distance.toStringAsFixed(1)} cm',
                        style: AppTheme.labelBold.copyWith(
                          color: AppTheme.statusOffline,
                        ),
                      ),
                      Text(
                        'Giảm tốc hoặc đổi hướng ngay!',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.statusOffline.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
