// lib/models/user.dart
class User {
  final int userId;
  final String username;
  final String email;
  final String passwordHash;
  final String createdAt;
  final String updatedAt;
  final String status;
  final String avatar;
  final String? role;

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.avatar,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      username: json['username'],
      email: json['email'],
      passwordHash: json['passwordHash'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      status: json['status'],
      avatar: json['avatar'],
      role: json['role'],
    );
  }
}
