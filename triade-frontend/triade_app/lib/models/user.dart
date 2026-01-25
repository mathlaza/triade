/// Modelo de usuário para o app Tríade
class User {
  final int id;
  final String username;
  final String personalName;
  final String email;
  final bool hasPhoto;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    required this.personalName,
    required this.email,
    this.hasPhoto = false,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      personalName: json['personal_name'] as String,
      email: json['email'] as String,
      hasPhoto: json['has_photo'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'personal_name': personalName,
      'email': email,
      'has_photo': hasPhoto,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? personalName,
    String? email,
    bool? hasPhoto,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      personalName: personalName ?? this.personalName,
      email: email ?? this.email,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: @$username, name: $personalName, email: $email)';
  }
}

/// Resposta de autenticação (login/register)
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;
  final String? message;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );
  }
}
