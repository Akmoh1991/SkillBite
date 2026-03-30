import 'package:skillbite_mobile/core/utils/data_helpers.dart';

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
    final business = asMap(json['business']);
    return SessionUser(
      id: _asInt(json['id']),
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

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
