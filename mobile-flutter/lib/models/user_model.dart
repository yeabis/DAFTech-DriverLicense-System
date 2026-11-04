class User {
  final String id;
  final String username;
  final String badgeNumber;
  final String role;
  final String? token;

  const User({
    required this.id,
    required this.username,
    required this.badgeNumber,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      badgeNumber: json['badgeNumber'] ?? '',
      role: json['role'] ?? 'Officer',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'badgeNumber': badgeNumber,
      'role': role,
      'token': token,
    };
  }
}

