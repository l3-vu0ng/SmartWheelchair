import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../providers/wheelchair_provider.dart';
import '../services/ble_constants.dart';
import '../services/ble_service.dart';
import '../services/permission_service.dart';

/// ============================================================================
/// [BleScanDialog] — Dialog quét và chọn thiết bị Bluetooth BLE
/// ============================================================================
/// Hiển thị danh sách thiết bị BLE tìm thấy, lọc theo tên "SmartWheelchair".
/// Nhấn vào thiết bị → kết nối → đóng dialog.
/// ============================================================================
class BleScanDialog {
  BleScanDialog._();

  /// Hiển thị dialog quét BLE.
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _BleScanDialogContent(),
    );
  }
}

class _BleScanDialogContent extends StatefulWidget {
  const _BleScanDialogContent();

  @override
  State<_BleScanDialogContent> createState() => _BleScanDialogContentState();
}

class _BleScanDialogContentState extends State<_BleScanDialogContent> {
  final BleService _bleService = BleService();
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _hasPermission = false;
  String? _errorMessage;
  StreamSubscription<List<ScanResult>>? _scanSub;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndScan();
  }

  Future<void> _checkPermissionsAndScan() async {
    final granted = await PermissionService.requestBluetoothPermissions();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
      });
    }

    if (granted) {
      _startScan();
    } else {
      setState(() {
        _errorMessage = 'Cần cấp quyền Bluetooth để quét thiết bị.';
      });
    }
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _scanResults = [];
      _errorMessage = null;
    });

    _scanSub = _bleService.startScan().listen((results) {
      if (mounted) {
        setState(() {
          // Lọc thiết bị theo tên
          _scanResults = results.where((r) {
            final name = r.device.platformName;
            return name.isNotEmpty &&
                name.startsWith(BleConstants.deviceNamePrefix);
          }).toList();
        });
      }
    });

    // Tự dừng scan sau timeout
    Future.delayed(BleConstants.scanTimeout, () {
      if (mounted) {
        _bleService.stopScan();
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  Future<void> _connectToDevice(ScanResult result) async {
    _bleService.stopScan();
    _scanSub?.cancel();

    if (!mounted) return;
    Navigator.of(context).pop();

    // Kết nối qua provider
    final provider = context.read<WheelchairProvider>();
    await provider.connectViaBle(result.device);
  }

  @override
  void dispose() {
    _bleService.stopScan();
    _scanSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bluetooth_searching_rounded,
              color: Color(0xFF7C3AED),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Quét thiết bị BLE', style: AppTheme.headlineMd),
          ),
          if (_isScanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _buildContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        if (!_isScanning && _hasPermission)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            onPressed: _startScan,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Quét lại'),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildMessageState(
        icon: Icons.bluetooth_disabled_rounded,
        message: _errorMessage!,
        color: AppTheme.statusOffline,
      );
    }

    if (!_hasPermission) {
      return _buildMessageState(
        icon: Icons.lock_rounded,
        message: 'Cần cấp quyền Bluetooth',
        color: AppTheme.warningOrange,
      );
    }

    if (_scanResults.isEmpty && _isScanning) {
      return _buildMessageState(
        icon: Icons.bluetooth_searching_rounded,
        message: 'Đang tìm kiếm thiết bị...',
        color: AppTheme.tealSignal,
      );
    }

    if (_scanResults.isEmpty && !_isScanning) {
      return _buildMessageState(
        icon: Icons.search_off_rounded,
        message:
            'Không tìm thấy thiết bị.\nĐảm bảo ESP32 đã bật và ở gần.',
        color: AppTheme.textSecondary,
      );
    }

    return ListView.separated(
      itemCount: _scanResults.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 56),
      itemBuilder: (ctx, index) {
        final result = _scanResults[index];
        final device = result.device;
        final rssi = result.rssi;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingXxs,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  const Color(0xFF7C3AED).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bluetooth_rounded,
              color: Color(0xFF7C3AED),
              size: 20,
            ),
          ),
          title: Text(
            device.platformName.isNotEmpty
                ? device.platformName
                : 'Unknown Device',
            style: AppTheme.labelBold,
          ),
          subtitle: Text(
            'Tín hiệu: $rssi dBm',
            style: AppTheme.caption,
          ),
          trailing: _buildSignalIndicator(rssi),
          onTap: () => _connectToDevice(result),
        );
      },
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  /// Hiển thị thanh tín hiệu BLE (RSSI).
  Widget _buildSignalIndicator(int rssi) {
    final strength = rssi > -60
        ? 3
        : rssi > -75
            ? 2
            : 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 4,
          height: 8.0 + (i * 4),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: i < strength
                ? AppTheme.statusOnline
                : AppTheme.borderLight,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
