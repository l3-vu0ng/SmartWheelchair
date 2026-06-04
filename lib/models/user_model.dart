class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int? age;
  final String? emergencyPhone;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.age,
    this.emergencyPhone,
  });

  /// Factory constructor để tạo UserModel từ Map (Firestore)
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastLoginAt'])
          : DateTime.now(),
      age: data['age'],
      emergencyPhone: data['emergencyPhone'],
    );
  }

  /// Chuyển đối tượng UserModel thành Map để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
      if (age != null) 'age': age,
      if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
    };
  }
  
  /// CopyWith method để cập nhật một số trường
  UserModel copyWith({
    String? displayName,
    int? age,
    String? emergencyPhone,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      age: age ?? this.age,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
    );
  }
}
