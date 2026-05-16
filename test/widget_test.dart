import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vpc_smartwheelchair/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Load file môi trường giả lập để không bị lỗi khi test
    dotenv.testLoad(fileInput: '''
MQTT_USERNAME=test_user
MQTT_PASSWORD=test_pass
''');

    // Xây dựng app và render frame đầu tiên.
    await tester.pumpWidget(const SmartWheelchairApp());

    // Xác nhận một số Text xuất hiện trên thanh điều hướng bên dưới.
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Điều khiển'), findsOneWidget);
  });
}
