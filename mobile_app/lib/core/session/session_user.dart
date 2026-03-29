Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

class SessionUser {
  SessionUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.businessName,
  });

  final int id;
  final String username;
  final String displayName;
  final String role;
  final String businessName;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    final business = _asMap(json['business']);
    return SessionUser(
      id: (json['id'] ?? 0) as int,
      username: (json['username'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      businessName: (business['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'role': role,
      'business': {
        'name': businessName,
      },
    };
  }
}
