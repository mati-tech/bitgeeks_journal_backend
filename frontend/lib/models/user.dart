class User {
  final String id;
  final String email;
  final String? fullName;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class AuthSession {
  final String accessToken;
  final User user;

  const AuthSession({required this.accessToken, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['access_token'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}
