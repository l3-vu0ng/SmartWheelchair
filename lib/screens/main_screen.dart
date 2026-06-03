import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../providers/wheelchair_provider.dart';
import '../services/permission_service.dart';

import 'tabs/home_tab.dart';
import 'tabs/control_tab.dart';
import 'tabs/health_tab.dart';
import 'tabs/navigation_tab.dart';
import 'tabs/settings_tab.dart';

/// ============================================================================
/// [MainScreen] — Shell chính với BottomNavigationBar 5 tab
/// ============================================================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  WheelchairProvider? _providerRef;
  bool _hasShownLowBatteryWarning = false;
  bool _isShowingFallDialog = false;

  @override
  void initState() {
    super.initState();
    _requestInitialPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _providerRef = context.read<WheelchairProvider>();
      _providerRef?.addListener(_onProviderChange);
    });
  }

  Future<void> _requestInitialPermissions() async {
    await PermissionService.requestNotificationPermission();
  }

  void _onProviderChange() {
    if (!mounted || _providerRef == null) return;
    
    // Check fall detection
    if (_providerRef!.isFallen && !_isShowingFallDialog) {
      _isShowingFallDialog = true;
      _showFallDialog();
    }

    // Check low battery
    if (_providerRef!.sensorData?.isLowBattery == true && !_hasShownLowBatteryWarning) {
      _hasShownLowBatteryWarning = true;
      _showLowBatteryDialog();
    } else if (_providerRef!.sensorData != null && !_providerRef!.sensorData!.isLowBattery) {
      _hasShownLowBatteryWarning = false;
    }
  }

  void _showFallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.statusOffline, size: 32),
            const SizedBox(width: 8),
            Text('CẢNH BÁO NGÃ', style: AppTheme.headlineMd.copyWith(color: AppTheme.statusOffline)),
          ],
        ),
        content: Text(
          'Hệ thống phát hiện xe lăn có thể đã bị lật hoặc người dùng bị ngã. Vui lòng kiểm tra ngay lập tức!',
          style: AppTheme.bodyLg,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusOffline),
            onPressed: () {
              Navigator.of(ctx).pop();
              _isShowingFallDialog = false;
              _providerRef?.clearFallDetection();
            },
            child: const Text('Đã xác nhận an toàn'),
          ),
        ],
      ),
    );
  }

  void _showLowBatteryDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.battery_alert_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Pin yếu! Vui lòng sạc điện cho xe lăn.')),
          ],
        ),
        backgroundColor: AppTheme.warningOrange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
      ),
    );
  }

  @override
  void dispose() {
    _providerRef?.removeListener(_onProviderChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      HomeTab(
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const ControlTab(),
      const HealthTab(),
      const NavigationTab(),
      const SettingsTab(),
    ];

    return Scaffold(
      extendBody: true, // Cho phép body tràn xuống dưới thanh nav lơ lửng
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: AppTheme.spacingLg, right: AppTheme.spacingLg, bottom: AppTheme.spacingLg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: AppTheme.glassmorphismDecoration,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXs,
                    vertical: AppTheme.spacingXs, // Tăng padding một chút cho đẹp
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: 'Trang chủ',
                        isSelected: _currentIndex == 0,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                      _NavItem(
                        icon: Icons.flash_on_rounded,
                        label: 'Điều khiển',
                        isSelected: _currentIndex == 1,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      _NavItem(
                        icon: Icons.monitor_heart_rounded,
                        label: 'Sức khỏe',
                        isSelected: _currentIndex == 2,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                      _NavItem(
                        icon: Icons.near_me_rounded,
                        label: 'Điều hướng',
                        isSelected: _currentIndex == 3,
                        onTap: () => setState(() => _currentIndex = 3),
                      ),
                      _NavItem(
                        icon: Icons.settings_rounded,
                        label: 'Cài đặt',
                        isSelected: _currentIndex == 4,
                        onTap: () => setState(() => _currentIndex = 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Một mục trong thanh nav — dọc: icon trên, label dưới.
/// Active = nền xanh bo tròn, icon + text trắng.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl), // Bo tròn thành dạng pill
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? AppTheme.canvasWhite : AppTheme.textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  fontSize: 10,
                  color: isSelected ? AppTheme.canvasWhite : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
