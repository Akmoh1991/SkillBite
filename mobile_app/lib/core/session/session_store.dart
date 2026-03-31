import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'session_user.dart';

class RestoredSession {
  const RestoredSession({
    required this.languageName,
    required this.token,
    required this.user,
  });

  final String? languageName;
  final String? token;
  final SessionUser? user;
}

class SessionStore {
  static const String _prefsTokenKey = 'skillbite.token';
  static const String _prefsUserKey = 'skillbite.user';
  static const String _prefsLanguageKey = 'skillbite.language';

  const SessionStore();

  Future<RestoredSession> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString(_prefsUserKey);
    SessionUser? user;
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        user =
            SessionUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      } catch (_) {
        user = null;
      }
    }

    return RestoredSession(
      languageName: prefs.getString(_prefsLanguageKey),
      token: prefs.getString(_prefsTokenKey),
      user: user,
    );
  }

  Future<void> save({
    required String languageName,
    String? token,
    SessionUser? user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLanguageKey, languageName);

    if (token != null && user != null) {
      await prefs.setString(_prefsTokenKey, token);
      await prefs.setString(_prefsUserKey, jsonEncode(user.toJson()));
      return;
    }

    await prefs.remove(_prefsTokenKey);
    await prefs.remove(_prefsUserKey);
  }
}
