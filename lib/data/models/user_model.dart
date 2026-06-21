class UserModel {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String role; // 'admin' or 'user'
  final String? photoProfile; // path to local profile photo

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    this.photoProfile,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'photo_profile': photoProfile,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
      photoProfile: map['photo_profile'] as String?,
    );
  }
}
