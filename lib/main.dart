import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_theme.dart';
import 'providers/wheelchair_provider.dart';
import 'screens/main_screen.dart';
import 'services/mqtt_service.dart';

/// ============================================================================
/// [main] — Entry point của ứng dụng SmartWheel
/// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const SmartWheelchairApp());
}

/// Widget gốc — cấu hình Theme và Provider tree.
class SmartWheelchairApp extends StatelessWidget {
  const SmartWheelchairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WheelchairProvider>(
          create: (_) => WheelchairProvider(
            mqttService: MqttService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'SmartWheel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainScreen(),
      ),
    );
  }
}
