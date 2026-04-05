import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/shell/role_shell.dart';
import 'package:skillbite_mobile/app/theme/app_theme.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/session/session_store.dart';
import 'package:skillbite_mobile/core/session/session_user.dart';
import 'package:skillbite_mobile/core/utils/data_helpers.dart';
import 'package:skillbite_mobile/features/auth/pages/pages.dart';

void main() {
  debugPrint('SkillBite app main() start');
  runApp(const SkillBiteMobileApp());
}

class SkillBiteMobileApp extends StatefulWidget {
  const SkillBiteMobileApp({super.key});

  @override
  State<SkillBiteMobileApp> createState() => _SkillBiteMobileAppState();
}

class _SkillBiteMobileAppState extends State<SkillBiteMobileApp> {
  static const SessionStore _sessionStore = SessionStore();

  late final MobileApiClient api;
  SessionUser? sessionUser;
  AppLanguage language = AppLanguage.ar;
  bool restoringSession = true;

  @override
  void initState() {
    super.initState();
    AppLanguageController.onChange = _handleLanguageChanged;
    final apiBaseUrlCandidates = buildApiBaseUrlCandidates();
    api = MobileApiClient(
      baseUrl: apiBaseUrlCandidates.first,
      fallbackBaseUrls: apiBaseUrlCandidates.skip(1).toList(),
    );
    unawaited(_restoreSession());
  }

  @override
  void dispose() {
    if (AppLanguageController.onChange == _handleLanguageChanged) {
      AppLanguageController.onChange = null;
    }
    super.dispose();
  }

  Future<void> _restoreSession() async {
    final restored = await _sessionStore.load();
    final savedLanguage = restored.languageName;
    final savedToken = restored.token;
    final cachedUser = restored.user;

    if (savedLanguage == AppLanguage.en.name) {
      language = AppLanguage.en;
    } else if (savedLanguage == AppLanguage.ar.name) {
      language = AppLanguage.ar;
    }

    if (!mounted) {
      return;
    }

    if (savedToken != null) {
      api.token = savedToken;

      if (cachedUser != null) {
        setState(() {
          sessionUser = cachedUser;
          restoringSession = false;
        });
        unawaited(_refreshSession());
        return;
      }

      try {
        final payload = await api.get('/auth/me/');
        if (!mounted) {
          return;
        }
        setState(() {
          sessionUser = SessionUser.fromJson(asMap(payload['user']));
          restoringSession = false;
        });
        unawaited(_persistSession());
        return;
      } catch (_) {
        api.token = null;
        await _sessionStore.save(languageName: language.name);
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      restoringSession = false;
    });
  }

  Future<void> _refreshSession() async {
    if (api.token == null) {
      return;
    }

    try {
      final payload = await api.get('/auth/me/');
      final refreshedUser = SessionUser.fromJson(asMap(payload['user']));
      if (!mounted) {
        return;
      }
      setState(() {
        sessionUser = refreshedUser;
      });
      await _persistSession();
    } catch (_) {
      api.token = null;
      await _sessionStore.save(languageName: language.name);
      if (!mounted) {
        return;
      }
      setState(() {
        sessionUser = null;
      });
    }
  }

  Future<void> _persistSession() async {
    await _sessionStore.save(
      languageName: language.name,
      token: api.token,
      user: sessionUser,
    );
  }

  void _handleLogin(SessionUser user) {
    setState(() {
      sessionUser = user;
    });
    unawaited(_persistSession());
  }

  Future<void> _handleLogout() async {
    try {
      await api.post('/auth/logout/', {});
    } catch (_) {}
    setState(() {
      api.token = null;
      sessionUser = null;
    });
    await _persistSession();
  }

  void _handleLanguageChanged(AppLanguage nextLanguage) {
    setState(() {
      language = nextLanguage;
    });
    unawaited(_persistSession());
  }

  @override
  Widget build(BuildContext context) {
    final homeKey = ValueKey<String>(
      'home-${language.name}-${restoringSession ? 'restoring' : sessionUser?.role ?? 'guest'}-${sessionUser?.id ?? 0}',
    );
    return MaterialApp(
      title: 'SkillBite Mobile',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: Locale(language == AppLanguage.ar ? 'ar' : 'en'),
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: restoringSession
          ? AppLoadingState(key: homeKey)
          : sessionUser == null
              ? LoginScreen(key: homeKey, api: api, onLoggedIn: _handleLogin)
              : RoleShell(
                  key: homeKey,
                  api: api,
                  user: sessionUser!,
                  onLogout: _handleLogout,
                ),
    );
  }
}
