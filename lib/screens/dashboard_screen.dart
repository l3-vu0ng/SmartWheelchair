// ============================================================================
// [DashboardScreen] — LEGACY — Đã chuyển sang MainScreen + 5 Tab
// ============================================================================
// File này được giữ lại để tránh lỗi import.
// Giao diện chính hiện nằm tại: lib/screens/main_screen.dart
// ============================================================================
import 'package:flutter/material.dart';

import 'main_screen.dart';

/// Legacy redirect — mọi navigation đến DashboardScreen sẽ chuyển sang MainScreen.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}
