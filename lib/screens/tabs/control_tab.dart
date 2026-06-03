import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_theme.dart';
import '../../providers/wheelchair_provider.dart';
import '../../widgets/connection_dialog.dart';

/// ============================================================================
/// [ControlTab] — Tab Điều khiển xe lăn
/// ============================================================================
/// Gồm: D-pad buttons, Speed slider, Fullscreen mode.
/// ============================================================================
class ControlTab extends StatefulWidget {
  const ControlTab({super.key});

  @override
  State<ControlTab> createState() => _ControlTabState();
}

class _ControlTabState extends State<ControlTab> {
  String _currentDirection = 'stop';
  double _maxSpeed = 2.0; // km/h
  bool _hapticEnabled = true;
  WheelchairProvider? _providerRef;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _providerRef = context.read<WheelchairProvider>();
      _providerRef?.addListener(_onProviderChange);
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hapticEnabled = prefs.getBool('hapticFeedback') ?? true;
      });
    }
  }

  void _onProviderChange() {
    if (!mounted || _providerRef == null) return;
    if (_providerRef!.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(_providerRef!.errorMessage!)),
            ],
          ),
          backgroundColor: AppTheme.warningOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      _providerRef!.clearError();
    }
  }

  @override
  void dispose() {
    _providerRef?.removeListener(_onProviderChange);
    super.dispose();
  }

  void _showFullScreenControl(BuildContext context, WheelchairProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _FullScreenControlScreen(
          provider: provider,
          maxSpeed: _maxSpeed,
          hapticEnabled: _hapticEnabled,
          onSpeedChanged: (val) {
            setState(() {
              _maxSpeed = val;
            });
          },
        ),
      ),
    );
  }

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
                _ControlHeader(provider: provider),
                const SizedBox(height: AppTheme.spacingMd),

                // --- Status bar ---
                _StatusBanner(provider: provider),
                const SizedBox(height: AppTheme.spacingMd),

                // --- D-Pad ---
                _DPadCard(
                  currentDirection: _currentDirection,
                  onDirection: (dir) {
                    setState(() => _currentDirection = dir);
                    int pwm = (_maxSpeed / 6.0 * 255).toInt();
                    provider.sendCommand(dir, speed: pwm);
                    if (_hapticEnabled) HapticFeedback.lightImpact();
                  },
                  onFullScreenTap: () => _showFullScreenControl(context, provider),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // --- Speed Control ---
                _SpeedControlCard(
                  maxSpeed: _maxSpeed,
                  onChanged: (v) => setState(() => _maxSpeed = v),
                ),
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
// HEADER
// =============================================================================
class _ControlHeader extends StatelessWidget {
  final WheelchairProvider provider;
  const _ControlHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ĐIỀU KHIỂN', style: AppTheme.sectionLabel),
              Text('Xe lăn thông minh', style: AppTheme.headlineLg),
            ],
          ),
        ),
        // Connect Button — mở dialog chọn WiFi/BLE
        GestureDetector(
          onTap: () {
            if (provider.isConnected) {
              provider.disconnectAll();
            } else {
              ConnectionDialog.show(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: provider.isConnected
                  ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                  : AppTheme.scaffoldBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Icon(
              Icons.power_settings_new_rounded,
              color: provider.isConnected
                  ? AppTheme.primaryBlue
                  : AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// STATUS BANNER
// =============================================================================
class _StatusBanner extends StatelessWidget {
  final WheelchairProvider provider;
  const _StatusBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: provider.isConnected
                  ? AppTheme.statusOnline
                  : AppTheme.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.isConnected
                  ? 'Xe lăn đã sẵn sàng điều khiển'
                  : 'Nhấn nút nguồn để bắt đầu',
              style: AppTheme.bodyMd,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// D-PAD CARD
// =============================================================================
class _DPadCard extends StatelessWidget {
  final String currentDirection;
  final void Function(String) onDirection;
  final VoidCallback onFullScreenTap;

  const _DPadCard({
    required this.currentDirection,
    required this.onDirection,
    required this.onFullScreenTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NÚT ĐỊNH HƯỚNG', style: AppTheme.sectionLabel),
              GestureDetector(
                onTap: onFullScreenTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fullscreen_rounded, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Center(
            child: Column(
              children: [
                _DPadButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  isActive: currentDirection == 'forward',
                  onTapDown: () => onDirection('forward'),
                  onTapUp: () => onDirection('stop'),
                  size: 64,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DPadButton(
                      icon: Icons.keyboard_arrow_left_rounded,
                      isActive: currentDirection == 'left',
                      onTapDown: () => onDirection('left'),
                      onTapUp: () => onDirection('stop'),
                      size: 64,
                    ),
                    const SizedBox(width: 12),
                    // Stop button
                    GestureDetector(
                      onTap: () => onDirection('stop'),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: currentDirection == 'stop'
                              ? AppTheme.statusOffline
                              : AppTheme.textSecondary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.stop_rounded,
                          size: 32,
                          color: currentDirection == 'stop'
                              ? AppTheme.canvasWhite
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _DPadButton(
                      icon: Icons.keyboard_arrow_right_rounded,
                      isActive: currentDirection == 'right',
                      onTapDown: () => onDirection('right'),
                      onTapUp: () => onDirection('stop'),
                      size: 64,
                ),
                  ],
                ),
                const SizedBox(height: 12),
                _DPadButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  isActive: currentDirection == 'backward',
                  onTapDown: () => onDirection('backward'),
                  onTapUp: () => onDirection('stop'),
                  size: 64,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DPadButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final double size;

  const _DPadButton({
    required this.icon,
    required this.isActive,
    required this.onTapDown,
    required this.onTapUp,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue.withValues(alpha: 0.15) : AppTheme.scaffoldBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? AppTheme.primaryBlue : AppTheme.borderLight,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
          size: size * 0.6,
        ),
      ),
    );
  }
}

// =============================================================================
// SPEED CONTROL CARD
// =============================================================================
class _SpeedControlCard extends StatelessWidget {
  final double maxSpeed;
  final ValueChanged<double> onChanged;

  const _SpeedControlCard({
    required this.maxSpeed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TỐC ĐỘ TỐI ĐA', style: AppTheme.sectionLabel),
              Text(
                '${maxSpeed.toStringAsFixed(0)} km/h',
                style: AppTheme.labelBold.copyWith(color: AppTheme.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              // Minus
              GestureDetector(
                onTap: () {
                  if (maxSpeed > 0) onChanged(maxSpeed - 1);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.remove, color: AppTheme.textSecondary),
                ),
              ),
              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryBlue,
                    inactiveTrackColor: AppTheme.borderLight,
                    thumbColor: AppTheme.primaryBlue,
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: maxSpeed,
                    min: 0,
                    max: 6,
                    divisions: 6,
                    onChanged: onChanged,
                  ),
                ),
              ),
              // Plus
              GestureDetector(
                onTap: () {
                  if (maxSpeed < 6) onChanged(maxSpeed + 1);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.add, color: AppTheme.canvasWhite),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FULL SCREEN CONTROL SCREEN
// =============================================================================
class _FullScreenControlScreen extends StatefulWidget {
  final WheelchairProvider provider;
  final double maxSpeed;
  final bool hapticEnabled;
  final ValueChanged<double> onSpeedChanged;

  const _FullScreenControlScreen({
    required this.provider,
    required this.maxSpeed,
    required this.hapticEnabled,
    required this.onSpeedChanged,
  });

  @override
  State<_FullScreenControlScreen> createState() => _FullScreenControlScreenState();
}

class _FullScreenControlScreenState extends State<_FullScreenControlScreen> {
  String _currentDirection = 'stop';
  late double _localSpeed;

  @override
  void initState() {
    super.initState();
    _localSpeed = widget.maxSpeed;
    // Set landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    // Revert to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _handleDirection(String dir) {
    setState(() => _currentDirection = dir);
    int pwm = (_localSpeed / 6.0 * 255).toInt();
    widget.provider.sendCommand(dir, speed: pwm);
    if (widget.hapticEnabled) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingMd),
          child: Row(
            children: [
              // Left side: Close, Speed, Status
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_fullscreen_rounded, size: 32),
                          onPressed: () {
                            _handleDirection('stop');
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 8),
                        Text('ĐIỀU KHIỂN', style: AppTheme.headlineMd),
                      ],
                    ),
                    const Spacer(),
                    Text('TỐC ĐỘ: ${_localSpeed.toStringAsFixed(0)} km/h', style: AppTheme.labelBold),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.primaryBlue,
                        inactiveTrackColor: AppTheme.borderLight,
                        thumbColor: AppTheme.primaryBlue,
                        trackHeight: 8,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                      ),
                      child: Slider(
                        value: _localSpeed,
                        min: 0,
                        max: 6,
                        divisions: 6,
                        onChanged: (val) {
                          setState(() => _localSpeed = val);
                          widget.onSpeedChanged(val);
                        },
                      ),
                    ),
                    const Spacer(),
                    _StatusBanner(provider: widget.provider),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingXl),
              // Right side: Giant D-Pad
              Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _DPadButton(
                        icon: Icons.keyboard_arrow_up_rounded,
                        isActive: _currentDirection == 'forward',
                        onTapDown: () => _handleDirection('forward'),
                        onTapUp: () => _handleDirection('stop'),
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DPadButton(
                            icon: Icons.keyboard_arrow_left_rounded,
                            isActive: _currentDirection == 'left',
                            onTapDown: () => _handleDirection('left'),
                            onTapUp: () => _handleDirection('stop'),
                            size: 80,
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _handleDirection('stop'),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _currentDirection == 'stop'
                                    ? AppTheme.statusOffline
                                    : AppTheme.textSecondary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.stop_rounded,
                                size: 40,
                                color: _currentDirection == 'stop'
                                    ? AppTheme.canvasWhite
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _DPadButton(
                            icon: Icons.keyboard_arrow_right_rounded,
                            isActive: _currentDirection == 'right',
                            onTapDown: () => _handleDirection('right'),
                            onTapUp: () => _handleDirection('stop'),
                            size: 80,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DPadButton(
                        icon: Icons.keyboard_arrow_down_rounded,
                        isActive: _currentDirection == 'backward',
                        onTapDown: () => _handleDirection('backward'),
                        onTapUp: () => _handleDirection('stop'),
                        size: 80,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
