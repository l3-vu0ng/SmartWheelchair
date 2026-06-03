import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cập nhật thông tin User lên Firestore khi đăng nhập
  Future<void> saveUser(UserModel user) async {
    try {
      // Dùng set với merge: true để tạo mới nếu chưa có, hoặc cập nhật nếu đã có
      await _firestore.collection('users').doc(user.uid).set(
            user.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Lỗi khi lưu dữ liệu người dùng: $e');
    }
  }

  /// Đọc thông tin User từ Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy dữ liệu người dùng: $e');
    }
  }
}
