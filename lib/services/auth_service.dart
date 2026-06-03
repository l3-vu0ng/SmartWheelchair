import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  // Private constructor
  AuthService._internal();

  // Static instance
  static final AuthService _instance = AuthService._internal();

  // Factory constructor returning the static instance
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseService _dbService = DatabaseService();

  /// Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Lấy User hiện tại
  User? get currentUser => _auth.currentUser;

  /// Xử lý đăng nhập bằng Google
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Kích hoạt luồng xác thực Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Người dùng hủy đăng nhập
        return null;
      }

      // 2. Lấy thông tin xác thực (token) từ yêu cầu
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Tạo credential mới cho Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Đăng nhập vào Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      // 5. Lưu thông tin người dùng vào Firestore
      if (user != null) {
        UserModel? existingUser = await _dbService.getUser(user.uid);
        
        UserModel userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: existingUser?.displayName ?? user.displayName ?? 'Người dùng',
          photoUrl: user.photoURL ?? existingUser?.photoUrl,
          createdAt: existingUser?.createdAt ?? DateTime.now(),
          lastLoginAt: DateTime.now(),
          age: existingUser?.age,
          emergencyPhone: existingUser?.emergencyPhone,
        );
        await _dbService.saveUser(userModel);
      }

      return user;
    } catch (e) {
      throw Exception('Lỗi đăng nhập Google: $e');
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Lỗi đăng xuất: $e');
    }
  }
}
