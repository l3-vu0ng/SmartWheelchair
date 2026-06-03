import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vpc_smartwheelchair/main.dart';

// Lớp giả lập cho User để test hiển thị Dashboard
class FakeUser extends Fake implements User {
  @override
  String get uid => 'test-uid-123';
  @override
  String get email => 'test@example.com';
  @override
  String get displayName => 'Test User';
}

void main() {
  // Khởi tạo Binding trước khi thiết lập mocks
  TestWidgetsFlutterBinding.ensureInitialized();

  // Thiết lập Firebase Core mocks
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Load file môi trường giả lập để không bị lỗi khi test
    dotenv.testLoad(fileInput: '''
MQTT_USERNAME=test_user
MQTT_PASSWORD=test_pass
''');

    final fakeUser = FakeUser();

    // Xây dựng app và render frame đầu tiên, truyền fake user stream
    await tester.pumpWidget(SmartWheelchairApp(
      authStream: Stream<User?>.value(fakeUser),
    ));

    // Đợi render xong vì Stream.value phát ra bất đồng bộ ở frame tiếp theo
    await tester.pump();

    // Xác nhận một số Text xuất hiện trên thanh điều hướng bên dưới.
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Điều khiển'), findsOneWidget);
  });
}
