import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Yêu cầu quyền Thông báo (Notification)
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Yêu cầu quyền Vị trí (Location)
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) return true;

    final result = await Permission.location.request();
    if (result.isPermanentlyDenied) {
      // Mở cài đặt nếu người dùng đã từ chối vĩnh viễn
      await openAppSettings();
      return false; // Phải đợi người dùng quay lại để check
    }
    return result.isGranted;
  }
}
