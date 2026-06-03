import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'config/app_theme.dart';
import 'providers/wheelchair_provider.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

/// ============================================================================
/// [main] — Entry point của ứng dụng SmartWheel
/// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Khởi tạo Notification
    await NotificationService().init();

    await dotenv.load(fileName: ".env");
    
    // Khởi tạo Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stacktrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Lỗi khởi động:\n\n$e\n\nStacktrace:\n$stacktrace',
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(const SmartWheelchairApp());
}

/// Widget gốc — cấu hình Theme và Provider tree.
class SmartWheelchairApp extends StatelessWidget {
  final Stream<User?>? authStream;
  const SmartWheelchairApp({super.key, this.authStream});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WheelchairProvider>(
          create: (_) => WheelchairProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'SmartWheel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainScreen(), // Tạm bypass AuthWrapper để test UI
      ),
    );
  }
}

/// Lớp trung gian điều hướng giữa Màn hình đăng nhập và Màn hình chính
class AuthWrapper extends StatelessWidget {
  final Stream<User?>? authStream;
  const AuthWrapper({super.key, this.authStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authStream ?? AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Đang tải / Đang kiểm tra trạng thái
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Nếu đã đăng nhập thành công
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }

        // Chưa đăng nhập
        return const LoginScreen();
      },
    );
  }
}
