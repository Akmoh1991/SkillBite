// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

const Color _brandTeal = Color(0xFF1F8A7A);
const Color _brandTealDark = Color(0xFF16695F);
const Color _ink = Color(0xFF20242F);
const Color _muted = Color(0xFF8B909A);
const Color _surface = Color(0xFFFFFFFF);
const Color _surfaceAlt = Color(0xFFF7F8FB);
const Color _line = Color(0xFFE6E8EE);
const Color _warmCard = Color(0xFFF8C46E);

enum AppLanguage { en, ar }

class _AppScope extends InheritedWidget {
  const _AppScope({
    required this.language,
    required this.onLanguageChanged,
    required super.child,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  static _AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppScope>();
    assert(scope != null, 'App scope is missing.');
    return scope!;
  }

  @override
  bool updateShouldNotify(_AppScope oldWidget) => oldWidget.language != language;
}

bool _isArabic(BuildContext context) => _AppScope.of(context).language == AppLanguage.ar;

String _tr(BuildContext context, String english) {
  if (!_isArabic(context)) {
    return english;
  }
  return _arabicStrings[english] ?? english;
}

const Map<String, String> _arabicStrings = {
  'Reset Password': 'إعادة تعيين كلمة المرور',
  'Reset your password using your username and the recovery email saved on your account.': 'أعد تعيين كلمة المرور باستخدام اسم المستخدم والبريد الإلكتروني المسجل في الحساب.',
  'Username': 'اسم المستخدم',
  'Recovery email': 'البريد الإلكتروني للاستعادة',
  'New password': 'كلمة المرور الجديدة',
  'Confirm password': 'تأكيد كلمة المرور',
  'Password updated. You can sign in with the new password now.': 'تم تحديث كلمة المرور. يمكنك تسجيل الدخول بكلمة المرور الجديدة الآن.',
  'Updating...': 'جارٍ التحديث...',
  'Update Password': 'تحديث كلمة المرور',
  'Username and password are required.': 'اسم المستخدم وكلمة المرور مطلوبان.',
  'Sign in to SkillBite': 'تسجيل الدخول إلى SkillBite',
  'Please enter your information below in order to login to your account': 'يرجى إدخال بياناتك أدناه لتسجيل الدخول إلى حسابك.',
  'Enter your username': 'أدخل اسم المستخدم',
  'Password': 'كلمة المرور',
  'Enter your password': 'أدخل كلمة المرور',
  'Search here...': 'ابحث هنا...',
  'Forgot Password?': 'هل نسيت كلمة المرور؟',
  'Signing in...': 'جارٍ تسجيل الدخول...',
  'Log In': 'تسجيل الدخول',
  'Demo Access': 'الوصول التجريبي',
  'Owner Demo': 'تجربة المالك',
  'Employee Demo': 'تجربة الموظف',
  'Language': 'اللغة',
  'Arabic': 'العربية',
  'English': 'الإنجليزية',
  'Home': 'الرئيسية',
  'Employees': 'الموظفون',
  'Titles': 'المسميات',
  'Courses': 'الدورات',
  'Reports': 'التقارير',
  'Checklists': 'قوائم التحقق',
  'Chat': 'المحادثة',
  'History': 'السجل',
  'Business Chat': 'محادثة النشاط',
  'Team Chat': 'محادثة الفريق',
  'Notifications': 'الإشعارات',
  'Activity for ': 'النشاط لـ ',
  'Unread chat': 'المحادثات غير المقروءة',
  'Pending courses': 'الدورات المعلّقة',
  'Pending checklists': 'قوائم التحقق المعلّقة',
  'Active employees': 'الموظفون النشطون',
  'Active courses': 'الدورات النشطة',
  'All caught up': 'لا توجد عناصر جديدة',
  'There are no new notifications right now.': 'لا توجد إشعارات جديدة حالياً.',
  'new': 'جديد',
  'Recommendations': 'التوصيات',
  'No active courses.': 'لا توجد دورات نشطة.',
  'Trending courses': 'الدورات الرائجة',
  'View all': 'عرض الكل',
  'Best of the week': 'الأفضل هذا الأسبوع',
  'Today checklist': 'قائمة اليوم',
  'tasks': 'مهام',
  'No checklists assigned.': 'لا توجد قوائم تحقق مخصصة.',
  'Completed today': 'تم الإنجاز اليوم',
  'Pending checklist': 'قائمة تحقق معلّقة',
  'No courses assigned.': 'لا توجد دورات مخصصة.',
  'min': 'دقيقة',
  'Open': 'فتح',
  'Learning History': 'سجل التعلم',
  'No completed courses yet.': 'لا توجد دورات مكتملة بعد.',
  'Details': 'التفاصيل',
  'About the lesson': 'عن الدرس',
  'Lesson': 'الدرس',
  'No mobile content items.': 'لا توجد عناصر محتوى للجوال.',
  'More content': 'محتوى إضافي',
  'Continue': 'متابعة',
  'In progress': 'قيد التقدم',
  'Completing...': 'جارٍ الإكمال...',
  'Exam': 'الاختبار',
  'Course Exam': 'اختبار الدورة',
  'Pass score ': 'درجة النجاح ',
  'Question ': 'السؤال ',
  'Your answer': 'إجابتك',
  'Submitting...': 'جارٍ الإرسال...',
  'Submit Exam': 'إرسال الاختبار',
  'Checklist': 'قائمة التحقق',
  'Items': 'العناصر',
  'No checklist items.': 'لا توجد عناصر في القائمة.',
  'Already Completed': 'تم الإنجاز مسبقاً',
  'Complete Checklist': 'إكمال قائمة التحقق',
  'Workspace overview': 'نظرة عامة على مساحة العمل',
  'Your people': 'فريقك',
  'No employees yet.': 'لا يوجد موظفون بعد.',
  'Suggested course pushes': 'الدورات المقترحة',
  'No assignable courses.': 'لا توجد دورات قابلة للإسناد.',
  'Deactivate Employee': 'تعطيل الموظف',
  'Cancel': 'إلغاء',
  'Deactivate': 'تعطيل',
  'Create Employee': 'إنشاء موظف',
  'Full name': 'الاسم الكامل',
  'Email': 'البريد الإلكتروني',
  'Job title': 'المسمى الوظيفي',
  'Saving...': 'جارٍ الحفظ...',
  'Create': 'إنشاء',
  'Add': 'إضافة',
  'Title name': 'اسم المسمى',
  'Job Titles': 'المسميات الوظيفية',
  'No job titles created.': 'لم يتم إنشاء مسميات وظيفية بعد.',
  'active employees': 'موظفون نشطون',
  'Create Course': 'إنشاء دورة',
  'Title': 'العنوان',
  'Description': 'الوصف',
  'Minutes': 'الدقائق',
  'First content title': 'عنوان المحتوى الأول',
  'First content body': 'نص المحتوى الأول',
  'Assign Course': 'إسناد دورة',
  'assigned': 'مُسند',
  'Has exam': 'يوجد اختبار',
  'No exam': 'لا يوجد اختبار',
  'Manage Content': 'إدارة المحتوى',
  'Assign': 'إسناد',
  'Edit Content': 'تعديل المحتوى',
  'Add Content': 'إضافة محتوى',
  'Content type': 'نوع المحتوى',
  'Text': 'نص',
  'Link': 'رابط',
  'Body': 'المحتوى',
  'Material URL': 'رابط المادة',
  'Order': 'الترتيب',
  'Update': 'تحديث',
  'Delete Content': 'حذف المحتوى',
  'Delete': 'حذف',
  'Course Content': 'محتوى الدورة',
  'Course': 'الدورة',
  'No content items yet.': 'لا توجد عناصر محتوى بعد.',
  'Edit': 'تعديل',
  'Progress': 'التقدم',
  'Overall completion rate: ': 'معدل الإكمال العام: ',
  'Create Checklist': 'إنشاء قائمة تحقق',
  'Frequency': 'التكرار',
  'Daily': 'يومي',
  'Weekly': 'أسبوعي',
  'On demand': 'عند الطلب',
  'Assign to job title': 'إسناد إلى مسمى وظيفي',
  'No automatic assignment': 'بدون إسناد تلقائي',
  'Items, one per line': 'العناصر، كل عنصر في سطر',
  'Create Checklist Rule': 'إنشاء قاعدة إسناد',
  'Rule': 'قاعدة',
  'No checklists created.': 'لم يتم إنشاء قوائم تحقق بعد.',
  'Assignment Rules': 'قواعد الإسناد',
  'No checklist rules yet.': 'لا توجد قواعد إسناد بعد.',
  'Send Team Message': 'إرسال رسالة للفريق',
  'Message': 'الرسالة',
  'Sending...': 'جارٍ الإرسال...',
  'Send': 'إرسال',
  'Send Private Message': 'إرسال رسالة خاصة',
  'Need an account? Ask your business owner or administrator.': 'تحتاج إلى حساب؟ اطلبه من مالك النشاط أو المسؤول.',
  'Recipient': 'المستلم',
  'Write your message': 'اكتب رسالتك',
  'Team': 'الفريق',
  'Private': 'خاص',
  'Team Messages': 'رسائل الفريق',
  'No team messages yet.': 'لا توجد رسائل فريق بعد.',
  'People': 'الأشخاص',
  'Person': 'الشخص',
  'No private messages yet.': 'لا توجد رسائل خاصة بعد.',
  'Loading workspace...': 'جارٍ تحميل مساحة العمل...',
};

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
  final MobileApiClient api = MobileApiClient(
    baseUrl: kIsWeb
        ? 'http://127.0.0.1:8000/api/mobile/v1'
        : Platform.isAndroid
        ? 'http://10.0.2.2:8000/api/mobile/v1'
        : 'http://127.0.0.1:8000/api/mobile/v1',
    fallbackBaseUrls: const [],
  );
  SessionUser? sessionUser;
  AppLanguage language = AppLanguage.ar;

  void _handleLogin(SessionUser user) {
    setState(() {
      sessionUser = user;
    });
  }

  Future<void> _handleLogout() async {
    try {
      await api.post('/auth/logout/', {});
    } catch (_) {}
    setState(() {
      api.token = null;
      sessionUser = null;
    });
  }

  void _handleLanguageChanged(AppLanguage nextLanguage) {
    setState(() {
      language = nextLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SkillBiteMobileApp build language=$language sessionUser=${sessionUser?.username}');
    return _AppScope(
      language: language,
      onLanguageChanged: _handleLanguageChanged,
      child: MaterialApp(
        title: 'SkillBite Mobile',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        locale: Locale(language == AppLanguage.ar ? 'ar' : 'en'),
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: sessionUser == null
            ? LoginScreen(api: api, onLoggedIn: _handleLogin)
            : RoleShell(
                api: api,
                user: sessionUser!,
                onLogout: _handleLogout,
              ),
      ),
    );
  }
}

ThemeData _buildTheme() {
  const seed = _brandTeal;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    primary: seed,
    secondary: _warmCard,
    surface: _surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: _surface,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.4, color: _ink),
      headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: _ink),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.7, color: _ink),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: _ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: _muted),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: _muted),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
      backgroundColor: _surface,
      foregroundColor: _ink,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: _ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      color: _surface,
      shadowColor: const Color(0x14000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surface,
      labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: _muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: seed, width: 1.4),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _surface,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? seed : const Color(0xFFC9CDD7),
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected) ? seed : const Color(0xFFC9CDD7),
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F6F4),
      selectedColor: const Color(0xFFD7EFE8),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: _ink),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
  );
}

class MobileApiClient {
  MobileApiClient({
    required String baseUrl,
    List<String> fallbackBaseUrls = const [],
  })  : _baseUrlCandidates = [
          baseUrl,
          ...fallbackBaseUrls.where((candidate) => candidate != baseUrl),
        ],
        _activeBaseUrl = baseUrl;

  final List<String> _baseUrlCandidates;
  String _activeBaseUrl;
  String? token;
  static const Duration _requestTimeout = Duration(seconds: 8);

  String get baseUrl => _activeBaseUrl;

  Future<SessionUser> login(String username, String password) async {
    final payload = await _postWithFallback('/auth/login/', {
      'username': username,
      'password': password,
      'device_name': 'flutter-dev',
    }, includeAuth: false);
    token = payload['token'] as String?;
    return SessionUser.fromJson(payload['user'] as Map<String, dynamic>);
  }

  Future<void> forgotPassword({
    required String username,
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _postWithFallback('/auth/forgot-password/', {
      'username': username,
      'email': email,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    }, includeAuth: false);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http
        .get(_uriFor(baseUrl, path), headers: _headers())
        .timeout(_requestTimeout);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, Object body, {bool includeAuth = true}) async {
    final response = await http
        .post(
          _uriFor(baseUrl, path),
          headers: _headers(includeAuth: includeAuth),
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> _postWithFallback(
    String path,
    Object body, {
    bool includeAuth = true,
  }) async {
    Object? lastError;
    for (final candidate in _baseUrlCandidates) {
      try {
        final response = await http.post(
              _uriFor(candidate, path),
              headers: _headers(includeAuth: includeAuth),
              body: jsonEncode(body),
            )
            .timeout(_requestTimeout);
        final payload = _parseResponse(response);
        _activeBaseUrl = candidate;
        return payload;
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? Exception('Login failed.');
  }

  Uri _uriFor(String base, String path) => Uri.parse('$base$path');

  Map<String, String> _headers({bool includeAuth = true}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (includeAuth && token != null) 'Authorization': 'Bearer $token',
    };
  }

  String resolveUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return parsed.toString();
    }
    return Uri.parse(baseUrl).resolve(trimmed).toString();
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> payload;
    final rawBody = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    final normalizedBody = rawBody.startsWith('\uFEFF') ? rawBody.substring(1) : rawBody;
    try {
      payload = jsonDecode(normalizedBody) as Map<String, dynamic>;
    } catch (_) {
      if (normalizedBody.isEmpty) {
        throw Exception('Empty server response (${response.statusCode}).');
      }
      final preview = normalizedBody.length > 180
          ? '${normalizedBody.substring(0, 180)}...'
          : normalizedBody;
      throw Exception('Unexpected server response (${response.statusCode}): $preview');
    }
    if (payload['ok'] == true) {
      return payload;
    }
    if (response.statusCode >= 400 || payload['ok'] != true) {
      throw Exception(_extractError(payload));
    }
    return payload;
  }

  String _extractError(Map<String, dynamic> payload) {
    final error = payload['error'];
    if (error is Map<String, dynamic>) {
      return (error['message'] ?? 'Request failed').toString();
    }
    return 'Request failed';
  }
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
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.api,
    required this.onLoggedIn,
  });

  final MobileApiClient api;
  final ValueChanged<SessionUser> onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;
  String? errorText;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => errorText = 'Username and password are required.');
      return;
    }
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      final user = await widget.api.login(
        username,
        password,
      );
      widget.onLoggedIn(user);
    } catch (error) {
      setState(() {
        errorText = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _openForgotPassword() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ForgotPasswordScreen(api: widget.api)),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('LoginScreen build language=${_AppScope.of(context).language}');
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: _surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final scope = _AppScope.of(context);
                        scope.onLanguageChanged(_isArabic(context) ? AppLanguage.en : AppLanguage.ar);
                      },
                      icon: const Icon(Icons.language_rounded),
                      label: Text(_isArabic(context) ? 'English' : 'العربية'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  _tr(context, 'Sign in to SkillBite'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  _tr(context, 'Please enter your information below in order to login to your account'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _muted, height: 1.35),
                ),
                const SizedBox(height: 28),
                Text(_tr(context, 'Username'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: _tr(context, 'Enter your username'),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 22),
                Text(_tr(context, 'Password'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  onSubmitted: (_) => loading ? null : _submit(),
                  decoration: InputDecoration(
                    hintText: _tr(context, 'Enter your password'),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: const Icon(Icons.visibility_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _openForgotPassword,
                    child: Text(
                      _tr(context, 'Forgot Password?'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _brandTeal),
                    ),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 16),
                  _InlineError(message: errorText!),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: Text(loading ? _tr(context, 'Signing in...') : _tr(context, 'Log In')),
                ),
                const SizedBox(height: 28),
                Card(
                  color: _surfaceAlt,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_tr(context, 'Demo Access'), style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _DemoChip(
                              label: _tr(context, 'Owner Demo'),
                              onTap: () {
                                usernameController.text = 'demo_owner';
                                passwordController.text = 'pass12345';
                                setState(() => errorText = null);
                              },
                            ),
                            _DemoChip(
                              label: _tr(context, 'Employee Demo'),
                              onTap: () {
                                usernameController.text = 'demo_employee';
                                passwordController.text = 'pass12345';
                                setState(() => errorText = null);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: "Don’t have an account ? ",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF25314C)),
                      children: const [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(color: _brandTeal, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool saving = false;
  String? errorText;
  String? successText;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      saving = true;
      errorText = null;
      successText = null;
    });
    try {
      await widget.api.forgotPassword(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        newPassword: newPasswordController.text,
        confirmPassword: confirmPasswordController.text,
      );
      setState(() {
        successText = 'Password updated. You can sign in with the new password now.';
      });
    } catch (error) {
      setState(() {
        errorText = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tr(context, 'Reset Password'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          Text(
            _tr(context, 'Reset your password using your username and the recovery email saved on your account.'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _muted),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: _tr(context, 'Username'),
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: _tr(context, 'Recovery email'),
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: newPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _tr(context, 'New password'),
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _tr(context, 'Confirm password'),
              prefixIcon: Icon(Icons.verified_user_outlined),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 16),
            _InlineError(message: errorText!),
          ],
          if (successText != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _tr(context, successText!),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _brandTealDark),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving ? null : _submit,
            child: Text(saving ? _tr(context, 'Updating...') : _tr(context, 'Update Password')),
          ),
        ],
      ),
    );
  }
}

class RoleShell extends StatefulWidget {
  const RoleShell({
    super.key,
    required this.api,
    required this.user,
    required this.onLogout,
  });

  final MobileApiClient api;
  final SessionUser user;
  final Future<void> Function() onLogout;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int index = 0;

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          api: widget.api,
          user: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerMode = widget.user.role == 'business_owner';
    final pages = ownerMode
        ? [
            OwnerDashboardPage(api: widget.api, user: widget.user),
            OwnerEmployeesPage(api: widget.api),
            OwnerJobTitlesPage(api: widget.api),
            OwnerCoursesPage(api: widget.api),
            OwnerReportsPage(api: widget.api),
            OwnerChecklistsPage(api: widget.api),
            ChatPage(
              api: widget.api,
              roleBasePath: '/business-owner',
              title: _tr(context, 'Business Chat'),
            ),
          ]
        : [
            EmployeeDashboardPage(api: widget.api, user: widget.user),
            EmployeeCoursesPage(api: widget.api),
            EmployeeLearningHistoryPage(api: widget.api),
            EmployeeChecklistsPage(api: widget.api),
            ChatPage(
              api: widget.api,
              roleBasePath: '/employee',
              title: _tr(context, 'Team Chat'),
            ),
          ];
    final destinations = ownerMode
        ? [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: _tr(context, 'Home')),
            NavigationDestination(icon: Icon(Icons.group_outlined), label: _tr(context, 'Employees')),
            NavigationDestination(icon: Icon(Icons.badge_outlined), label: _tr(context, 'Titles')),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: _tr(context, 'Courses')),
            NavigationDestination(icon: Icon(Icons.insights_outlined), label: _tr(context, 'Reports')),
            NavigationDestination(icon: Icon(Icons.checklist_outlined), label: _tr(context, 'Checklists')),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: _tr(context, 'Chat')),
          ]
        : [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: _tr(context, 'Home')),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: _tr(context, 'Courses')),
            NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), label: _tr(context, 'History')),
            NavigationDestination(icon: Icon(Icons.checklist_outlined), label: _tr(context, 'Checklists')),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: _tr(context, 'Chat')),
          ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        titleSpacing: 24,
        title: Row(
          children: [
            _AvatarBadge(label: widget.user.displayName),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.user.displayName),
                  Text(
                    '@${widget.user.username}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _line),
              ),
              child: IconButton(
                onPressed: _openNotifications,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ),
          ),
          IconButton(
            onPressed: () async => widget.onLogout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Container(
          decoration: const BoxDecoration(
            color: _surface,
            border: Border(top: BorderSide(color: _line)),
          ),
          padding: const EdgeInsets.only(top: 6),
          child: NavigationBar(
            selectedIndex: index,
            height: 74,
            destinations: destinations,
            onDestinationSelected: (value) => setState(() => index = value),
          ),
        ),
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    required this.api,
    required this.user,
  });

  final MobileApiClient api;
  final SessionUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tr(context, 'Notifications'))),
      body: ApiFutureBuilder(
        future: api.get('/notifications/'),
        builder: (context, payload) {
          final summary = _asMap(payload['summary']);
          final notifications = _asList(payload['notifications']);
          return _PageBody(
            children: [
              Text(
                '${_tr(context, 'Activity for ')}${user.businessName}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _muted),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _NotificationSummaryChip(
                    label: _tr(context, 'Unread chat'),
                    value: '${summary['unread_chat_count'] ?? 0}',
                  ),
                  _NotificationSummaryChip(
                    label: user.role == 'employee' ? _tr(context, 'Pending courses') : _tr(context, 'Active employees'),
                    value: user.role == 'employee'
                        ? '${summary['pending_course_count'] ?? 0}'
                        : '${summary['active_employee_count'] ?? 0}',
                  ),
                  _NotificationSummaryChip(
                    label: user.role == 'employee' ? _tr(context, 'Pending checklists') : _tr(context, 'Active courses'),
                    value: user.role == 'employee'
                        ? '${summary['pending_checklist_count'] ?? 0}'
                        : '${summary['active_course_count'] ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (notifications.isEmpty)
                _SectionCard(
                  title: _tr(context, 'All caught up'),
                  child: Text(_tr(context, 'There are no new notifications right now.')),
                )
              else
                for (final item in notifications) ...[
                  _SectionCard(
                    title: _readString(item, 'title'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_readString(item, 'body')),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatusChip(
                              label: _readString(item, 'kind').replaceAll('_', ' '),
                            ),
                            const SizedBox(width: 8),
                            if (_readInt(item, 'unread_count') > 0)
                              _StatusChip(
                                label: '${_readInt(item, 'unread_count')} ${_tr(context, 'new')}',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
            ],
          );
        },
      ),
    );
  }
}

class EmployeeDashboardPage extends StatelessWidget {
  const EmployeeDashboardPage({
    super.key,
    required this.api,
    required this.user,
  });

  final MobileApiClient api;
  final SessionUser user;

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: api.get('/employee/dashboard/'),
      builder: (context, payload) {
        final dashboard = _asMap(payload['dashboard']);
        final assignments = _asList(dashboard['dashboard_course_assignments']);
        final checklists = _asList(dashboard['assigned_checklists']);
        final trending = assignments.take(2).toList();
        return _PageBody(
          children: [
            const _SearchHeroBar(),
            const SizedBox(height: 16),
            _HeaderRow(title: 'Trending courses', trailing: _sectionLink('View all')),
            const SizedBox(height: 14),
            SizedBox(
              height: 286,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: trending.isEmpty ? 2 : trending.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final item = trending.isEmpty ? null : _asMap(trending[index]);
                  final warm = index.isEven;
                  return _CoursePromoCard(
                    warm: warm,
                    tag: 'Trendy',
                    students: '680 + students',
                    title: item == null ? 'UX Master\nCourse' : _readPath(item, ['course', 'title']),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _HeaderRow(title: 'Best of the week', trailing: _sectionLink('View all')),
            const SizedBox(height: 16),
            if (assignments.isEmpty)
              const _SectionCard(title: 'Recommendations', child: Text('No active courses.'))
            else
              for (final item in assignments.take(4)) ...[
                _LessonListCard(
                  title: _readPath(item, ['course', 'title']),
                  subtitle:
                      '${_readString(item, 'status_label')}  ·  ${_readPath(item, ['course', 'estimated_minutes'])} lesson min',
                ),
                const SizedBox(height: 14),
              ],
            const SizedBox(height: 10),
            _HeroCard(
              title: 'Today checklist',
              subtitle: user.businessName,
              value: '${dashboard['assigned_checklist_count'] ?? 0} tasks',
            ),
            const SizedBox(height: 14),
            if (checklists.isEmpty)
              const _SectionCard(title: 'Checklists', child: Text('No checklists assigned.'))
            else
              for (final item in checklists.take(2)) ...[
                _LessonListCard(
                  title: _readString(item, 'title'),
                  subtitle: _readBool(item, 'completed_today') ? 'Completed today' : 'Pending checklist',
                  accent: const Color(0xFFFBE2EA),
                  trailingIcon: Icons.checklist_rounded,
                ),
                const SizedBox(height: 14),
              ],
          ],
        );
      },
    );
  }
}

class EmployeeCoursesPage extends StatefulWidget {
  const EmployeeCoursesPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<EmployeeCoursesPage> createState() => _EmployeeCoursesPageState();
}

class _EmployeeCoursesPageState extends State<EmployeeCoursesPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/employee/courses/');
  }

  void _reload() {
    setState(() {
      future = widget.api.get('/employee/courses/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: future,
      builder: (context, payload) {
        final courses = _asList(payload['courses']);
        return _PageBody(
          children: [
            _HeaderRow(
              title: 'Courses',
              trailing: IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ),
            const SizedBox(height: 16),
            if (courses.isEmpty)
              const _SectionCard(title: 'Courses', child: Text('No courses assigned.'))
            else
              for (final item in courses) ...[
                _SectionCard(
                  title: _readPath(item, ['course', 'title']),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_readPath(item, ['course', 'description'])),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatusChip(label: _readString(item, 'status_label')),
                          const SizedBox(width: 12),
                          Text('${_readPath(item, ['course', 'estimated_minutes'])} min'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonal(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EmployeeCourseDetailScreen(
                                  api: widget.api,
                                  assignmentId: _readInt(item, 'id'),
                                ),
                              ),
                            );
                            _reload();
                          },
                          child: Text(_tr(context, 'Open')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
    );
  }
}

class EmployeeLearningHistoryPage extends StatefulWidget {
  const EmployeeLearningHistoryPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<EmployeeLearningHistoryPage> createState() => _EmployeeLearningHistoryPageState();
}

class _EmployeeLearningHistoryPageState extends State<EmployeeLearningHistoryPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/employee/learning-history/');
  }

  void _reload() {
    setState(() {
      future = widget.api.get('/employee/learning-history/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: future,
      builder: (context, payload) {
        final history = _asList(payload['learning_history']);
        return _PageBody(
          children: [
            _HeaderRow(
              title: 'Learning History',
              trailing: IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              const _SectionCard(title: 'History', child: Text('No completed courses yet.'))
            else
              for (final item in history) ...[
                _SectionCard(
                  title: _readPath(item, ['course', 'title']),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_readPath(item, ['course', 'description'])),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatusChip(label: _readString(item, 'status_label')),
                          _StatusChip(label: '${_readPath(item, ['course', 'estimated_minutes'])} min'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
    );
  }
}

class EmployeeCourseDetailScreen extends StatefulWidget {
  const EmployeeCourseDetailScreen({
    super.key,
    required this.api,
    required this.assignmentId,
  });

  final MobileApiClient api;
  final int assignmentId;

  @override
  State<EmployeeCourseDetailScreen> createState() => _EmployeeCourseDetailScreenState();
}

class _EmployeeCourseDetailScreenState extends State<EmployeeCourseDetailScreen> {
  late Future<Map<String, dynamic>> future;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/employee/courses/${widget.assignmentId}/');
  }

  void _reload() {
    setState(() {
      future = widget.api.get('/employee/courses/${widget.assignmentId}/');
    });
  }

  Future<void> _openContentItem(Map<String, dynamic> item) async {
    final title = _readString(item, 'title');
    final videoUrl = widget.api.resolveUrl(_readString(item, 'video_url'));
    final pdfUrl = widget.api.resolveUrl(_readString(item, 'pdf_url'));
    final materialUrl = widget.api.resolveUrl(_readString(item, 'material_url'));
    if (videoUrl.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CourseVideoScreen(title: title, videoUrl: videoUrl),
        ),
      );
      return;
    }
    final browserUrl = pdfUrl.isNotEmpty ? pdfUrl : materialUrl;
    if (browserUrl.isEmpty) {
      _showSnack(
        context,
        _readString(item, 'body').isNotEmpty ? _readString(item, 'body') : 'No content URL available.',
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseWebContentScreen(
          title: title,
          url: browserUrl,
          isPdf: pdfUrl.isNotEmpty,
        ),
      ),
    );
  }

  Future<void> _completeCourse() async {
    setState(() => submitting = true);
    try {
      await widget.api.post('/employee/courses/${widget.assignmentId}/complete/', {});
      if (!mounted) return;
      _showSnack(context, 'Course completed.');
      _reload();
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tr(context, 'Details'))),
      body: ApiFutureBuilder(
        future: future,
        builder: (context, payload) {
          final assignment = _asMap(payload['course_assignment']);
          final course = _asMap(assignment['course']);
          final contentItems = _asList(course['content_items']);
          final hasExam = _readBool(course, 'has_exam');
          final featuredContent = contentItems.isEmpty ? const <dynamic>[] : [contentItems.first];
          final remainingContent = contentItems.length > 1 ? contentItems.skip(1).toList() : const <dynamic>[];
          return _PageBody(
            children: [
              _LessonProgressHeader(
                status: _readString(assignment, 'status_label'),
                progress: contentItems.isEmpty ? 0.2 : 0.26,
              ),
              const SizedBox(height: 16),
              Text(
                _tr(context, 'About the lesson'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 18,
                      color: _brandTeal,
                    ),
              ),
              const SizedBox(height: 16),
              if (featuredContent.isEmpty)
                _SectionCard(title: _tr(context, 'Lesson'), child: Text(_tr(context, 'No mobile content items.')))
              else
                _LessonMediaCard(
                  title: _readString(course, 'title'),
                  subtitle: _readString(course, 'description').isEmpty
                      ? _contentSubtitle(featuredContent.first)
                      : _readString(course, 'description'),
                  onTap: () => _openContentItem(_asMap(featuredContent.first)),
                ),
              const SizedBox(height: 18),
              Text(
                _readString(course, 'title'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              if (remainingContent.isNotEmpty) ...[
                _SectionCard(
                  title: _tr(context, 'More content'),
                  child: Column(
                    children: [
                      for (final item in remainingContent)
                        _CourseContentTile(
                          title: _readString(item, 'title'),
                          subtitle: _contentSubtitle(item),
                          icon: _contentIcon(item),
                          onTap: () => _openContentItem(_asMap(item)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              FilledButton(
                onPressed: submitting
                    ? null
                    : hasExam
                    ? () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => EmployeeExamScreen(
                              api: widget.api,
                              assignmentId: widget.assignmentId,
                            ),
                          ),
                        );
                        if (changed == true) {
                          _reload();
                        }
                      }
                    : _completeCourse,
                style: FilledButton.styleFrom(
                  backgroundColor: _brandTeal,
                ),
                child: Text(
                  hasExam
                      ? _tr(context, 'Continue')
                      : submitting
                          ? 'Completing...'
                          : _tr(context, 'Continue'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CourseVideoScreen extends StatefulWidget {
  const CourseVideoScreen({
    super.key,
    required this.title,
    required this.videoUrl,
  });

  final String title;
  final String videoUrl;

  @override
  State<CourseVideoScreen> createState() => _CourseVideoScreenState();
}

class _CourseVideoScreenState extends State<CourseVideoScreen> {
  VideoPlayerController? controller;
  String? errorText;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final nextController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await nextController.initialize();
      await nextController.setLooping(false);
      await nextController.play();
      if (!mounted) {
        await nextController.dispose();
        return;
      }
      setState(() {
        controller = nextController;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorText = 'Could not load this video.';
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: controller == null
          ? Center(
              child: errorText == null
                  ? const _LoadingState()
                  : _ErrorState(message: errorText!),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _LessonProgressHeader(status: _tr(context, 'In progress'), progress: 0.26),
                const SizedBox(height: 18),
                Text(
                  _tr(context, 'About the lesson'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                        color: _brandTeal,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: _brandTeal,
                  ),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: controller!.value.aspectRatio == 0 ? 16 / 9 : controller!.value.aspectRatio,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                          child: ColoredBox(
                            color: Colors.black,
                            child: VideoPlayer(controller!),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                final isPlaying = controller!.value.isPlaying;
                                setState(() {
                                  if (isPlaying) {
                                    controller!.pause();
                                  } else {
                                    controller!.play();
                                  }
                                });
                              },
                              icon: Icon(
                                controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withValues(alpha: 0.35),
                                  thumbColor: Colors.white,
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: controller!.value.position.inMilliseconds.toDouble().clamp(
                                        0,
                                        (controller!.value.duration.inMilliseconds == 0
                                                ? 1
                                                : controller!.value.duration.inMilliseconds)
                                            .toDouble(),
                                      ),
                                  max: (controller!.value.duration.inMilliseconds == 0
                                          ? 1
                                          : controller!.value.duration.inMilliseconds)
                                      .toDouble(),
                                  onChanged: (value) {
                                    controller!.seekTo(Duration(milliseconds: value.round()));
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final uri = Uri.parse(widget.videoUrl);
                                if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
                                  _showSnack(context, 'Could not open this video externally.');
                                }
                              },
                              icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(backgroundColor: _brandTeal),
                  child: Text(_tr(context, 'Continue')),
                ),
              ],
            ),
    );
  }
}

class CourseWebContentScreen extends StatefulWidget {
  const CourseWebContentScreen({
    super.key,
    required this.title,
    required this.url,
    required this.isPdf,
  });

  final String title;
  final String url;
  final bool isPdf;

  @override
  State<CourseWebContentScreen> createState() => _CourseWebContentScreenState();
}

class _CourseWebContentScreenState extends State<CourseWebContentScreen> {
  late final WebViewController controller;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => loading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () async {
              final uri = Uri.parse(widget.url);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
                _showSnack(context, 'Could not open this file externally.');
              }
            },
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (loading) const Center(child: CircularProgressIndicator()),
          if (widget.isPdf)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'If this PDF does not preview properly inside the app, use the open button in the top bar.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EmployeeExamScreen extends StatefulWidget {
  const EmployeeExamScreen({
    super.key,
    required this.api,
    required this.assignmentId,
  });

  final MobileApiClient api;
  final int assignmentId;

  @override
  State<EmployeeExamScreen> createState() => _EmployeeExamScreenState();
}

class _EmployeeExamScreenState extends State<EmployeeExamScreen> {
  late Future<Map<String, dynamic>> future;
  bool submitting = false;
  final Map<String, dynamic> answers = {};
  final Map<int, TextEditingController> textControllers = {};

  @override
  void initState() {
    super.initState();
    future = widget.api.post('/employee/courses/${widget.assignmentId}/exam/start/', {});
  }

  @override
  void dispose() {
    for (final controller in textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerForQuestion(int questionId) {
    return textControllers.putIfAbsent(questionId, TextEditingController.new);
  }

  Future<void> _submit(Map<String, dynamic> exam) async {
    setState(() => submitting = true);
    try {
      final result = await widget.api.post('/employee/courses/${widget.assignmentId}/exam/submit/', {
        'attempt_token': _readString(exam, 'attempt_token'),
        'answers': answers,
      });
      if (!mounted) return;
      final payload = _asMap(result['result']);
      final passed = _readBool(payload, 'passed');
      _showSnack(
        context,
        passed
            ? 'Exam passed with ${_readInt(payload, 'score_percent')}%.'
            : 'Exam submitted: ${_readInt(payload, 'score_percent')}%.',
      );
      Navigator.of(context).pop(passed);
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tr(context, 'Exam'))),
      body: ApiFutureBuilder(
        future: future,
        builder: (context, payload) {
          final exam = _asMap(payload['exam']);
          final questions = _asList(exam['questions']);
          return _PageBody(
            children: [
              _HeroCard(
                title: 'Course Exam',
                subtitle: 'Pass score ${_readInt(exam, 'passing_score_percent')}%',
                value: '${_readInt(exam, 'duration_minutes')} min',
              ),
              const SizedBox(height: 16),
              for (final rawQuestion in questions) ...[
                _SectionCard(
                  title: 'Question ${_readInt(rawQuestion, 'order')}',
                  child: _ExamQuestionCard(
                    question: _asMap(rawQuestion),
                    answers: answers,
                    controller: _controllerForQuestion(_readInt(rawQuestion, 'id')),
                    onChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: submitting ? null : () => _submit(exam),
                child: Text(submitting ? 'Submitting...' : 'Submit Exam'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExamQuestionCard extends StatelessWidget {
  const _ExamQuestionCard({
    required this.question,
    required this.answers,
    required this.controller,
    required this.onChanged,
  });

  final Map<String, dynamic> question;
  final Map<String, dynamic> answers;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final questionId = _readInt(question, 'id');
    final questionKey = questionId.toString();
    final questionType = _readString(question, 'question_type');
    final options = _asList(question['options']);
    final answer = answers[questionKey];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _readString(question, 'question_text'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (questionType == 'MCQ_SINGLE' || questionType == 'TRUE_FALSE')
          for (final option in options)
            RadioListTile<String>(
              value: _readInt(option, 'id').toString(),
              groupValue: answer?.toString(),
              contentPadding: EdgeInsets.zero,
              title: Text(_readString(option, 'text')),
              onChanged: (value) {
                answers[questionKey] = value ?? '';
                onChanged();
              },
            ),
        if (questionType == 'MCQ_MULTI')
          for (final option in options)
            CheckboxListTile(
              value: (answer is List ? answer : const []).contains(_readInt(option, 'id').toString()),
              contentPadding: EdgeInsets.zero,
              title: Text(_readString(option, 'text')),
              onChanged: (checked) {
                final values = List<String>.from(answer is List ? answer : const <String>[]);
                final optionId = _readInt(option, 'id').toString();
                if (checked == true) {
                  if (!values.contains(optionId)) values.add(optionId);
                } else {
                  values.remove(optionId);
                }
                answers[questionKey] = values;
                onChanged();
              },
            ),
        if (questionType == 'SHORT_ANSWER' || questionType == 'ESSAY')
          TextField(
            controller: controller,
            minLines: questionType == 'ESSAY' ? 4 : 2,
            maxLines: questionType == 'ESSAY' ? 8 : 3,
            onChanged: (value) {
              answers[questionKey] = value;
            },
            decoration: InputDecoration(
              labelText: _tr(context, 'Your answer'),
              alignLabelWithHint: true,
            ),
          ),
      ],
    );
  }
}

class EmployeeChecklistsPage extends StatefulWidget {
  const EmployeeChecklistsPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<EmployeeChecklistsPage> createState() => _EmployeeChecklistsPageState();
}

class _EmployeeChecklistsPageState extends State<EmployeeChecklistsPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/employee/checklists/');
  }

  void _reload() {
    setState(() {
      future = widget.api.get('/employee/checklists/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: future,
      builder: (context, payload) {
        final checklists = _asList(payload['checklists']);
        return _PageBody(
          children: [
            _HeaderRow(
              title: 'Checklists',
              trailing: IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ),
            const SizedBox(height: 16),
            if (checklists.isEmpty)
              const _SectionCard(title: 'Checklists', child: Text('No checklists assigned.'))
            else
              for (final item in checklists) ...[
                _SectionCard(
                  title: _readString(item, 'title'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_readString(item, 'description')),
                      const SizedBox(height: 12),
                      _StatusChip(
                        label: _readBool(item, 'completed_today') ? 'Completed today' : 'Pending',
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonal(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EmployeeChecklistDetailScreen(
                                  api: widget.api,
                                  checklistId: _readInt(item, 'id'),
                                ),
                              ),
                            );
                            _reload();
                          },
                          child: const Text('Open'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
    );
  }
}

class EmployeeChecklistDetailScreen extends StatefulWidget {
  const EmployeeChecklistDetailScreen({
    super.key,
    required this.api,
    required this.checklistId,
  });

  final MobileApiClient api;
  final int checklistId;

  @override
  State<EmployeeChecklistDetailScreen> createState() => _EmployeeChecklistDetailScreenState();
}

class _EmployeeChecklistDetailScreenState extends State<EmployeeChecklistDetailScreen> {
  late Future<Map<String, dynamic>> future;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/employee/checklists/${widget.checklistId}/');
  }

  Future<void> _completeChecklist(List<dynamic> items) async {
    setState(() => submitting = true);
    try {
      await widget.api.post('/employee/checklists/${widget.checklistId}/complete/', {
        'item_ids': [for (final item in items) _readInt(item, 'id')],
        'notes': '',
      });
      if (!mounted) return;
      _showSnack(context, 'Checklist completed.');
      setState(() {
        future = widget.api.get('/employee/checklists/${widget.checklistId}/');
      });
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tr(context, 'Checklist'))),
      body: ApiFutureBuilder(
        future: future,
        builder: (context, payload) {
          final checklist = _asMap(payload['checklist']);
          final items = _asList(checklist['items']);
          final completed = _readBool(checklist, 'completed_today');
          return _PageBody(
            children: [
              _HeroCard(
                title: _readString(checklist, 'title'),
                subtitle: _readString(checklist, 'frequency'),
                value: completed ? 'Done' : 'Open',
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Items',
                child: items.isEmpty
                    ? const Text('No checklist items.')
                    : Column(
                        children: [
                          for (final item in items)
                            CheckboxListTile(
                              value: true,
                              onChanged: null,
                              contentPadding: EdgeInsets.zero,
                              title: Text(_readString(item, 'title')),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: completed || submitting ? null : () => _completeChecklist(items),
                child: Text(completed ? 'Already Completed' : submitting ? 'Submitting...' : 'Complete Checklist'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({
    super.key,
    required this.api,
    required this.user,
  });

  final MobileApiClient api;
  final SessionUser user;

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: api.get('/business-owner/dashboard/'),
      builder: (context, payload) {
        final dashboard = _asMap(payload['dashboard']);
        final employees = _asList(dashboard['employees']);
        final courses = _asList(dashboard['assignable_courses']);
        return _PageBody(
          children: [
            const _SearchHeroBar(),
            const SizedBox(height: 16),
            _HeroCard(
              title: 'Workspace overview',
              subtitle: user.businessName,
              value: '${dashboard['employee_total'] ?? 0} team members',
            ),
            const SizedBox(height: 18),
            _MetricRow(
              metrics: [
                _MetricData('Employees', '${dashboard['employee_total'] ?? 0}'),
                _MetricData('Courses', '${dashboard['course_total'] ?? 0}'),
                _MetricData('Checklists', '${dashboard['checklist_total'] ?? 0}'),
              ],
            ),
            const SizedBox(height: 20),
            _HeaderRow(title: 'Your people', trailing: _sectionLink('View all')),
            const SizedBox(height: 14),
            if (employees.isEmpty)
              const _SectionCard(title: 'Employees', child: Text('No employees yet.'))
            else
              for (final item in employees.take(3)) ...[
                _LessonListCard(
                  title: _readString(item, 'display_name'),
                  subtitle: _readString(item, 'job_title').isEmpty ? _readString(item, 'username') : _readString(item, 'job_title'),
                  trailingIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
              ],
            const SizedBox(height: 6),
            _HeaderRow(title: 'Suggested course pushes', trailing: _sectionLink('View all')),
            const SizedBox(height: 14),
            if (courses.isEmpty)
              const _SectionCard(title: 'Courses', child: Text('No assignable courses.'))
            else
              for (final item in courses.take(2)) ...[
                _CoursePromoCard(
                  warm: courses.first == item,
                  tag: 'Workspace',
                  students: _readString(item, 'business_name'),
                  title: _readString(item, 'title'),
                ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
    );
  }
}

class OwnerEmployeesPage extends StatefulWidget {
  const OwnerEmployeesPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<OwnerEmployeesPage> createState() => _OwnerEmployeesPageState();
}

class _OwnerEmployeesPageState extends State<OwnerEmployeesPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/business-owner/employees/');
  }

  void _reload() {
    setState(() {
      future = widget.api.get('/business-owner/employees/');
    });
  }

  Future<void> _deactivateEmployee(Map<String, dynamic> employee) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_tr(context, 'Deactivate Employee')),
            content: Text('Disable ${_readString(employee, 'display_name')}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(_tr(context, 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(_tr(context, 'Deactivate')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await widget.api.post('/business-owner/employees/${_readInt(employee, 'id')}/deactivate/', {});
      if (!mounted) return;
      _showSnack(context, 'Employee deactivated.');
      _reload();
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showCreateEmployeeDialog() async {
    final usernameController = TextEditingController();
    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final jobTitleController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool saving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> submit() async {
              setInnerState(() {
                saving = true;
                errorText = null;
              });
              try {
                await widget.api.post('/business-owner/employees/create/', {
                  'username': usernameController.text.trim(),
                  'full_name': fullNameController.text.trim(),
                  'email': emailController.text.trim(),
                  'password': passwordController.text,
                  'job_title': jobTitleController.text.trim(),
                });
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                setInnerState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: Text(_tr(context, 'Create Employee')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: usernameController, decoration: InputDecoration(labelText: _tr(context, 'Username'))),
                    TextField(controller: fullNameController, decoration: InputDecoration(labelText: _tr(context, 'Full name'))),
                    TextField(controller: emailController, decoration: InputDecoration(labelText: _tr(context, 'Email'))),
                    TextField(controller: passwordController, decoration: InputDecoration(labelText: _tr(context, 'Password'))),
                    TextField(controller: jobTitleController, decoration: InputDecoration(labelText: _tr(context, 'Job title'))),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(false), child: Text(_tr(context, 'Cancel'))),
                FilledButton(onPressed: saving ? null : submit, child: Text(saving ? 'Saving...' : 'Create')),
              ],
            );
          },
        );
      },
    );
    if (created == true) {
      _showSnack(context, 'Employee created.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: future,
      builder: (context, payload) {
        final employees = _asList(payload['employees']);
        return _PageBody(
          children: [
            _HeaderRow(
              title: 'Employees',
              trailing: FilledButton.icon(
                onPressed: _showCreateEmployeeDialog,
                icon: const Icon(Icons.add),
                label: Text(_tr(context, 'Add')),
              ),
            ),
            const SizedBox(height: 16),
            if (employees.isEmpty)
              const _SectionCard(title: 'Employees', child: Text('No employees yet.'))
            else
              for (final item in employees) ...[
                _SectionCard(
                  title: _readString(item, 'display_name'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_readString(item, 'username')),
                      const SizedBox(height: 8),
                      Text(_readString(item, 'job_title')),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonal(
                          onPressed: () => _deactivateEmployee(_asMap(item)),
                          child: Text(_tr(context, 'Deactivate')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
    );
  }
}

class OwnerJobTitlesPage extends StatefulWidget {
  const OwnerJobTitlesPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<OwnerJobTitlesPage> createState() => _OwnerJobTitlesPageState();
}

class _OwnerJobTitlesPageState extends State<OwnerJobTitlesPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/business-owner/job-titles/');
  }

  void _reload() {
    setState(() {
      future = widget.api.get('/business-owner/job-titles/');
    });
  }

  Future<void> _showCreateJobTitleDialog() async {
    final nameController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool saving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> submit() async {
              setInnerState(() {
                saving = true;
                errorText = null;
              });
              try {
                await widget.api.post('/business-owner/job-titles/create/', {
                  'name': nameController.text.trim(),
                });
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                setInnerState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: Text(_tr(context, 'Create Job Title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: _tr(context, 'Title name')),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(false),
                  child: Text(_tr(context, 'Cancel')),
                ),
                FilledButton(
                  onPressed: saving ? null : submit,
                  child: Text(saving ? 'Saving...' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
    if (created == true) {
      _showSnack(context, 'Job title created.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: future,
      builder: (context, payload) {
        final jobTitles = _asList(payload['job_titles']);
        return _PageBody(
          children: [
            _HeaderRow(
              title: 'Job Titles',
              trailing: FilledButton.icon(
                onPressed: _showCreateJobTitleDialog,
                icon: const Icon(Icons.add),
                label: Text(_tr(context, 'Add')),
              ),
            ),
            const SizedBox(height: 16),
            if (jobTitles.isEmpty)
              const _SectionCard(title: 'Job Titles', child: Text('No job titles created.'))
            else
              for (final item in jobTitles) ...[
                _SectionCard(
                  title: _readString(item, 'name'),
                  child: Text('${_readInt(item, 'employee_count')} active employees'),
                ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
    );
  }
}

class OwnerCoursesPage extends StatefulWidget {
  const OwnerCoursesPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<OwnerCoursesPage> createState() => _OwnerCoursesPageState();
}

class _OwnerCoursesPageState extends State<OwnerCoursesPage> {
  late Future<Map<String, dynamic>> coursesFuture;
  late Future<Map<String, dynamic>> employeesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      coursesFuture = widget.api.get('/business-owner/courses/');
      employeesFuture = widget.api.get('/business-owner/employees/');
    });
  }

  Future<void> _showCreateCourseDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final minutesController = TextEditingController(text: '15');
    final contentTitleController = TextEditingController();
    final contentBodyController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool saving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> submit() async {
              setInnerState(() {
                saving = true;
                errorText = null;
              });
              try {
                await widget.api.post('/business-owner/courses/create/', {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'estimated_minutes': int.tryParse(minutesController.text.trim()) ?? 15,
                  'is_active': true,
                  'content_items': [
                    {
                      'title': contentTitleController.text.trim(),
                      'body': contentBodyController.text.trim(),
                      'content_type': 'TEXT',
                    }
                  ],
                });
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                setInnerState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: Text(_tr(context, 'Create Course')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: InputDecoration(labelText: _tr(context, 'Title'))),
                    TextField(controller: descriptionController, decoration: InputDecoration(labelText: _tr(context, 'Description'))),
                    TextField(controller: minutesController, decoration: InputDecoration(labelText: _tr(context, 'Minutes'))),
                    TextField(controller: contentTitleController, decoration: InputDecoration(labelText: _tr(context, 'First content title'))),
                    TextField(controller: contentBodyController, decoration: InputDecoration(labelText: _tr(context, 'First content body'))),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(false), child: Text(_tr(context, 'Cancel'))),
                FilledButton(onPressed: saving ? null : submit, child: Text(saving ? 'Saving...' : 'Create')),
              ],
            );
          },
        );
      },
    );
    if (created == true) {
      _showSnack(context, 'Course created.');
      _reload();
    }
  }

  Future<void> _showAssignDialog(int courseId, List<dynamic> employees) async {
    final selectedIds = <int>{};
    final assigned = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool saving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> submit() async {
              setInnerState(() {
                saving = true;
                errorText = null;
              });
              try {
                await widget.api.post('/business-owner/courses/$courseId/assign/', {
                  'employee_ids': selectedIds.toList(),
                });
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                setInnerState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: Text(_tr(context, 'Assign Course')),
              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in employees)
                        CheckboxListTile(
                          value: selectedIds.contains(_readInt(item, 'id')),
                          onChanged: (checked) {
                            setInnerState(() {
                              final id = _readInt(item, 'id');
                              if (checked == true) {
                                selectedIds.add(id);
                              } else {
                                selectedIds.remove(id);
                              }
                            });
                          },
                          title: Text(_readString(item, 'display_name')),
                          subtitle: Text(_readString(item, 'job_title')),
                        ),
                      if (errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(errorText!, style: const TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(false), child: Text(_tr(context, 'Cancel'))),
                FilledButton(onPressed: saving ? null : submit, child: Text(saving ? 'Saving...' : 'Assign')),
              ],
            );
          },
        );
      },
    );
    if (assigned == true) {
      _showSnack(context, 'Course assigned.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future.wait([coursesFuture, employeesFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')));
        }
        final coursesPayload = snapshot.data![0];
        final employeesPayload = snapshot.data![1];
        final courses = _asList(coursesPayload['courses']);
        final employees = _asList(employeesPayload['employees']);
        return _PageBody(
          children: [
            _HeaderRow(
              title: 'Courses',
              trailing: FilledButton.icon(
                onPressed: _showCreateCourseDialog,
                icon: const Icon(Icons.add),
                label: Text(_tr(context, 'Add')),
              ),
            ),
            const SizedBox(height: 16),
            if (courses.isEmpty)
              const _SectionCard(title: 'Courses', child: Text('No courses available.'))
            else
              for (final item in courses) ...[
                _SectionCard(
                  title: _readString(item, 'title'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_readString(item, 'description')),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatusChip(label: '${_readInt(item, 'assignment_total')} assigned'),
                          _StatusChip(label: '${_readInt(item, 'estimated_minutes')} min'),
                          _StatusChip(label: _readBool(item, 'has_exam') ? 'Has exam' : 'No exam'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => OwnerCourseDetailScreen(
                                      api: widget.api,
                                      courseId: _readInt(item, 'id'),
                                    ),
                                  ),
                                );
                                _reload();
                              },
                              child: Text(_tr(context, 'Manage Content')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () => _showAssignDialog(_readInt(item, 'id'), employees),
                              child: Text(_tr(context, 'Assign')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
    );
  }
}

class OwnerCourseDetailScreen extends StatefulWidget {
  const OwnerCourseDetailScreen({
    super.key,
    required this.api,
    required this.courseId,
  });

  final MobileApiClient api;
  final int courseId;

  @override
  State<OwnerCourseDetailScreen> createState() => _OwnerCourseDetailScreenState();
}

class _OwnerCourseDetailScreenState extends State<OwnerCourseDetailScreen> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/business-owner/courses/${widget.courseId}/');
  }

  void _reload() {
    setState(() {
      future = widget.api.get('/business-owner/courses/${widget.courseId}/');
    });
  }

  Future<void> _showContentDialog({Map<String, dynamic>? item}) async {
    final isEditing = item != null;
    final titleController = TextEditingController(text: isEditing ? _readString(item, 'title') : '');
    final bodyController = TextEditingController(text: isEditing ? _readString(item, 'body') : '');
    final urlController = TextEditingController(text: isEditing ? _readString(item, 'material_url') : '');
    final orderController = TextEditingController(text: isEditing ? '${_readInt(item, 'order')}' : '1');
    String contentType = isEditing ? _readString(item, 'content_type') : 'TEXT';
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool saving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> submit() async {
              setInnerState(() {
                saving = true;
                errorText = null;
              });
              final payload = {
                'title': titleController.text.trim(),
                'body': bodyController.text.trim(),
                'material_url': urlController.text.trim(),
                'order': int.tryParse(orderController.text.trim()) ?? 1,
                'content_type': contentType,
              };
              try {
                if (isEditing) {
                  await widget.api.post('/business-owner/course-content/${_readInt(item, 'id')}/update/', payload);
                } else {
                  await widget.api.post('/business-owner/courses/${widget.courseId}/content/create/', payload);
                }
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                setInnerState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: Text(_tr(context, isEditing ? 'Edit Content' : 'Add Content')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: contentType,
                      decoration: InputDecoration(labelText: _tr(context, 'Content type')),
                      items: [
                        DropdownMenuItem(value: 'TEXT', child: Text(_tr(context, 'Text'))),
                        DropdownMenuItem(value: 'MATERIAL', child: Text(_tr(context, 'Link'))),
                        DropdownMenuItem(value: 'LESSON', child: Text(_tr(context, 'Lesson'))),
                      ],
                      onChanged: (value) {
                        setInnerState(() {
                          contentType = value ?? 'TEXT';
                        });
                      },
                    ),
                    TextField(controller: titleController, decoration: InputDecoration(labelText: _tr(context, 'Title'))),
                    TextField(
                      controller: bodyController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(labelText: _tr(context, 'Body')),
                    ),
                    TextField(controller: urlController, decoration: InputDecoration(labelText: _tr(context, 'Material URL'))),
                    TextField(controller: orderController, decoration: InputDecoration(labelText: _tr(context, 'Order'))),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(false),
                  child: Text(_tr(context, 'Cancel')),
                ),
                FilledButton(
                  onPressed: saving ? null : submit,
                  child: Text(saving ? 'Saving...' : isEditing ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
    if (changed == true) {
      _showSnack(context, isEditing ? 'Content updated.' : 'Content created.');
      _reload();
    }
  }

  Future<void> _deleteContent(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_tr(context, 'Delete Content')),
            content: Text('Delete "${_readString(item, 'title')}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(_tr(context, 'Cancel'))),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(_tr(context, 'Delete'))),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await widget.api.post('/business-owner/course-content/${_readInt(item, 'id')}/delete/', {});
      if (!mounted) return;
      _showSnack(context, 'Content deleted.');
      _reload();
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tr(context, 'Course Content'))),
      body: ApiFutureBuilder(
        future: future,
        builder: (context, payload) {
          final course = _asMap(payload['course']);
          final items = _asList(course['content_items']);
          return _PageBody(
            children: [
              _HeaderRow(
                title: _readString(course, 'title'),
                trailing: FilledButton.icon(
                  onPressed: () => _showContentDialog(),
                  icon: const Icon(Icons.add),
                  label: Text(_tr(context, 'Add')),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Course',
                child: Text(_readString(course, 'description')),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const _SectionCard(title: 'Content', child: Text('No content items yet.'))
              else
                for (final rawItem in items) ...[
                  _SectionCard(
                    title: _readString(rawItem, 'title'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_readString(rawItem, 'body').isNotEmpty) Text(_readString(rawItem, 'body')),
                        if (_readString(rawItem, 'material_url').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(_readString(rawItem, 'material_url')),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _StatusChip(label: _readString(rawItem, 'content_type')),
                            _StatusChip(label: 'Order ${_readInt(rawItem, 'order')}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () => _showContentDialog(item: _asMap(rawItem)),
                                child: Text(_tr(context, 'Edit')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () => _deleteContent(_asMap(rawItem)),
                                child: Text(_tr(context, 'Delete')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
            ],
          );
        },
      ),
    );
  }
}

class OwnerReportsPage extends StatelessWidget {
  const OwnerReportsPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: api.get('/business-owner/reports/'),
      builder: (context, payload) {
        final report = _asMap(payload['report']);
        return _PageBody(
          children: [
            _HeaderRow(title: 'Reports'),
            const SizedBox(height: 16),
            _MetricRow(
              metrics: [
                _MetricData('Tracked', '${report['tracked_employee_total'] ?? 0}'),
                _MetricData('Assigned', '${report['total_assigned'] ?? 0}'),
                _MetricData('Completed', '${report['total_completed'] ?? 0}'),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Progress',
              child: Text('Overall completion rate: ${report['overall_completion_rate'] ?? 0}%'),
            ),
          ],
        );
      },
    );
  }
}

class OwnerChecklistsPage extends StatefulWidget {
  const OwnerChecklistsPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<OwnerChecklistsPage> createState() => _OwnerChecklistsPageState();
}

class _OwnerChecklistsPageState extends State<OwnerChecklistsPage> {
  late Future<Map<String, dynamic>> checklistsFuture;
  late Future<Map<String, dynamic>> rulesFuture;
  late Future<Map<String, dynamic>> jobTitlesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      checklistsFuture = widget.api.get('/business-owner/checklists/');
      rulesFuture = widget.api.get('/business-owner/checklist-rules/');
      jobTitlesFuture = widget.api.get('/business-owner/job-titles/');
    });
  }

  Future<void> _showCreateChecklistDialog(List<dynamic> jobTitles) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final itemsController = TextEditingController();
    String frequency = 'DAILY';
    int? jobTitleId;
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool saving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> submit() async {
              setInnerState(() {
                saving = true;
                errorText = null;
              });
              try {
                await widget.api.post('/business-owner/checklists/create/', {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'frequency': frequency,
                  'is_active': true,
                  if (jobTitleId != null) 'job_title': jobTitleId,
                  'items': [
                    for (final line in itemsController.text.split('\n'))
                      if (line.trim().isNotEmpty) line.trim(),
                  ],
                });
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                setInnerState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: Text(_tr(context, 'Create Checklist')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: InputDecoration(labelText: _tr(context, 'Title'))),
                    TextField(controller: descriptionController, decoration: InputDecoration(labelText: _tr(context, 'Description'))),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: frequency,
                      decoration: InputDecoration(labelText: _tr(context, 'Frequency')),
                      items: [
                        DropdownMenuItem(value: 'DAILY', child: Text(_tr(context, 'Daily'))),
                        DropdownMenuItem(value: 'WEEKLY', child: Text(_tr(context, 'Weekly'))),
                        DropdownMenuItem(value: 'ON_DEMAND', child: Text(_tr(context, 'On demand'))),
                      ],
                      onChanged: (value) {
                        setInnerState(() {
                          frequency = value ?? 'DAILY';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: jobTitleId,
                      decoration: InputDecoration(labelText: _tr(context, 'Assign to job title')),
                      items: [
                        DropdownMenuItem<int?>(value: null, child: Text(_tr(context, 'No automatic assignment'))),
                        for (final rawTitle in jobTitles)
                          DropdownMenuItem<int?>(
                            value: _readInt(rawTitle, 'id'),
                            child: Text(_readString(rawTitle, 'name')),
                          ),
                      ],
                      onChanged: (value) {
                        setInnerState(() {
                          jobTitleId = value;
                        });
                      },
                    ),
                    TextField(
                      controller: itemsController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(labelText: _tr(context, 'Items, one per line')),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(false), child: Text(_tr(context, 'Cancel'))),
                FilledButton(onPressed: saving ? null : submit, child: Text(saving ? 'Saving...' : 'Create')),
              ],
            );
          },
        );
      },
    );
    if (created == true) {
      _showSnack(context, 'Checklist created.');
      _reload();
    }
  }

  Future<void> _showCreateRuleDialog(List<dynamic> checklists, List<dynamic> jobTitles) async {
    int? selectedChecklistId = checklists.isEmpty ? null : _readInt(checklists.first, 'id');
    int? selectedJobTitleId = jobTitles.isEmpty ? null : _readInt(jobTitles.first, 'id');
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool saving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> submit() async {
              setInnerState(() {
                saving = true;
                errorText = null;
              });
              try {
                await widget.api.post('/business-owner/checklist-rules/create/', {
                  'job_title': selectedJobTitleId,
                  'checklist': selectedChecklistId,
                });
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                setInnerState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: Text(_tr(context, 'Create Checklist Rule')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int?>(
                    initialValue: selectedJobTitleId,
                    decoration: InputDecoration(labelText: _tr(context, 'Job title')),
                    items: [
                      for (final rawTitle in jobTitles)
                        DropdownMenuItem<int?>(
                          value: _readInt(rawTitle, 'id'),
                          child: Text(_readString(rawTitle, 'name')),
                        ),
                    ],
                    onChanged: (value) {
                      setInnerState(() {
                        selectedJobTitleId = value;
                      });
                    },
                  ),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedChecklistId,
                    decoration: InputDecoration(labelText: _tr(context, 'Checklist')),
                    items: [
                      for (final rawChecklist in checklists)
                        DropdownMenuItem<int?>(
                          value: _readInt(rawChecklist, 'id'),
                          child: Text(_readString(rawChecklist, 'title')),
                        ),
                    ],
                    onChanged: (value) {
                      setInnerState(() {
                        selectedChecklistId = value;
                      });
                    },
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(false), child: Text(_tr(context, 'Cancel'))),
                FilledButton(onPressed: saving ? null : submit, child: Text(saving ? 'Saving...' : 'Create')),
              ],
            );
          },
        );
      },
    );
    if (created == true) {
      _showSnack(context, 'Checklist rule created.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future.wait([checklistsFuture, rulesFuture, jobTitlesFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')));
        }
        final checklists = _asList(snapshot.data![0]['checklists']);
        final rules = _asList(snapshot.data![1]['rules']);
        final jobTitles = _asList(snapshot.data![2]['job_titles']);
        return _PageBody(
          children: [
            _HeaderRow(
              title: 'Checklists',
              trailing: Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _showCreateChecklistDialog(jobTitles),
                    icon: const Icon(Icons.add),
                    label: Text(_tr(context, 'Add')),
                  ),
                  FilledButton.tonal(
                    onPressed: checklists.isEmpty || jobTitles.isEmpty
                        ? null
                        : () => _showCreateRuleDialog(checklists, jobTitles),
                    child: Text(_tr(context, 'Rule')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (checklists.isEmpty)
              const _SectionCard(title: 'Checklists', child: Text('No checklists created.'))
            else
              for (final item in checklists) ...[
                _SectionCard(
                  title: _readString(item, 'title'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_readString(item, 'description')),
                      const SizedBox(height: 12),
                      _StatusChip(label: _readString(item, 'frequency')),
                      const SizedBox(height: 12),
                      for (final checklistItem in _asList(item['items']))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('- ${_readString(checklistItem, 'title')}'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            _SectionCard(
              title: 'Assignment Rules',
              child: rules.isEmpty
                  ? const Text('No checklist rules yet.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final item in rules)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${_readPath(item, ['job_title', 'name'])} -> ${_readPath(item, ['checklist', 'title'])}',
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.api,
    required this.roleBasePath,
    required this.title,
  });

  final MobileApiClient api;
  final String roleBasePath;
  final String title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Future<Map<String, dynamic>> teamFuture;
  late Future<Map<String, dynamic>> privateFuture;
  bool showPrivate = false;
  int? selectedUserId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      teamFuture = widget.api.get('${widget.roleBasePath}/chat/team/');
      final suffix = selectedUserId == null ? '' : '?user_id=$selectedUserId';
      privateFuture = widget.api.get('${widget.roleBasePath}/chat/private/$suffix');
    });
  }

  Future<void> _sendTeamMessage() async {
    final controller = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool saving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> submit() async {
              setInnerState(() {
                saving = true;
                errorText = null;
              });
              try {
                await widget.api.post('${widget.roleBasePath}/chat/team/send/', {
                  'body': controller.text.trim(),
                });
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                setInnerState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: Text(_tr(context, 'Send Team Message')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(labelText: _tr(context, 'Message')),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(false), child: Text(_tr(context, 'Cancel'))),
                FilledButton(onPressed: saving ? null : submit, child: Text(saving ? _tr(context, 'Sending...') : _tr(context, 'Send'))),
              ],
            );
          },
        );
      },
    );
    if (sent == true) {
      _showSnack(context, 'Message sent.');
      _reload();
    }
  }

  Future<void> _sendPrivateMessage(List<dynamic> participants) async {
    int? recipientId = selectedUserId ?? (participants.isEmpty ? null : _readInt(participants.first, 'id'));
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool saving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> submit() async {
              setInnerState(() {
                saving = true;
                errorText = null;
              });
              try {
                await widget.api.post('${widget.roleBasePath}/chat/private/send/', {
                  'recipient_id': recipientId,
                  'body': controller.text.trim(),
                });
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                setInnerState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                  saving = false;
                });
              }
            }

            return Dialog(
              backgroundColor: const Color(0xFFF3FBF8),
              insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(22, 24, 22, MediaQuery.of(context).viewInsets.bottom + 22),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context, 'Send Private Message'),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 22),
                      DropdownButtonFormField<int?>(
                        initialValue: recipientId,
                        decoration: InputDecoration(labelText: _tr(context, 'Recipient')),
                        items: [
                          for (final item in participants)
                            DropdownMenuItem<int?>(
                              value: _readInt(item, 'id'),
                              child: Text(_readString(item, 'display_name')),
                            ),
                        ],
                        onChanged: (value) {
                          setInnerState(() {
                            recipientId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 5,
                        maxLines: 7,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: _tr(context, 'Message'),
                          alignLabelWithHint: true,
                          hintText: _tr(context, 'Write your message'),
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(color: Color(0xFFC54C2B), fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: saving ? null : () => Navigator.of(context).pop(false),
                          child: Text(_tr(context, 'Cancel')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving ? _tr(context, 'Sending...') : _tr(context, 'Send')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    focusNode.dispose();
    if (sent == true) {
      _showSnack(context, 'Private message sent.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future.wait([teamFuture, privateFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')));
        }
        final teamPayload = snapshot.data![0];
        final privatePayload = snapshot.data![1];
        final teamMessages = _asList(teamPayload['messages']);
        final participants = _asList(privatePayload['participants']);
        final conversations = _asList(privatePayload['conversations']);
        final privateMessages = _asList(privatePayload['messages']);
        final selectedUser = _asMap(privatePayload['selected_user']);
        return _PageBody(
          children: [
            Row(
              children: [
                Expanded(
                  child: _HeaderRow(title: widget.title),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: _surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    onPressed: showPrivate ? () => _sendPrivateMessage(participants) : _sendTeamMessage,
                    icon: Icon(showPrivate ? Icons.edit_outlined : Icons.send_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _surfaceAlt,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showPrivate = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: showPrivate ? Colors.transparent : _surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(child: Text(_tr(context, 'Team'))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showPrivate = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: showPrivate ? _surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(child: Text(_tr(context, 'Private'))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!showPrivate)
              if (teamMessages.isEmpty)
                _SectionCard(title: _tr(context, 'Team Messages'), child: Text(_tr(context, 'No team messages yet.')))
              else
                for (final item in teamMessages) ...[
                  _ChatMessageRow(
                    name: _readPath(item, ['sender', 'display_name']),
                    body: _readString(item, 'body'),
                    meta: _readPath(item, ['read_receipt', 'label']),
                    own: false,
                  ),
                  const SizedBox(height: 14),
                ]
            else ...[
              _SectionCard(
                title: 'People',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int?>(
                      initialValue: selectedUser.isEmpty ? null : _readInt(selectedUser, 'id'),
                      decoration: InputDecoration(labelText: _tr(context, 'Person')),
                      items: [
                        for (final item in participants)
                          DropdownMenuItem<int?>(
                            value: _readInt(item, 'id'),
                            child: Text(_readString(item, 'display_name')),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedUserId = value;
                          final suffix = value == null ? '' : '?user_id=$value';
                          privateFuture = widget.api.get('${widget.roleBasePath}/chat/private/$suffix');
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (conversations.isNotEmpty)
                      for (final item in conversations.take(5))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ConversationRow(
                            name: _readPath(item, ['partner', 'display_name']),
                            subtitle: _asMap(item['latest_message']).isEmpty
                                ? 'No messages yet'
                                : _readString(_asMap(item['latest_message']), 'body'),
                            unreadCount: _readInt(item, 'unread_count'),
                            selected: selectedUser.isNotEmpty &&
                                _readInt(_asMap(item['partner']), 'id') == _readInt(selectedUser, 'id'),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (privateMessages.isEmpty)
                _SectionCard(
                  title: selectedUser.isEmpty ? 'Messages' : _readString(selectedUser, 'display_name'),
                  child: Text(_tr(context, 'No private messages yet.')),
                )
              else
                for (final item in privateMessages) ...[
                  _ChatMessageRow(
                    name: _readPath(item, ['sender', 'display_name']),
                    body: _readString(item, 'body'),
                    meta: _readPath(item, ['read_receipt', 'label']),
                    own: selectedUser.isNotEmpty &&
                        _readInt(_asMap(item['sender']), 'id') != _readInt(selectedUser, 'id'),
                  ),
                  const SizedBox(height: 14),
                ],
            ],
          ],
        );
      },
    );
  }
}

class ApiFutureBuilder extends StatelessWidget {
  const ApiFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
  });

  final Future<Map<String, dynamic>> future;
  final Widget Function(BuildContext context, Map<String, dynamic> payload) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
          );
        }
        return builder(context, snapshot.data ?? <String, dynamic>{});
      },
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 120),
            children: children,
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandTeal, _brandTealDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _tr(context, title),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _tr(context, subtitle),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, height: 1.15),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final metric in metrics) SizedBox(width: 210, child: _MetricCard(data: metric)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.show_chart_rounded, size: 22, color: _brandTeal),
            ),
            const SizedBox(height: 18),
            Text(
              data.value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tr(context, data.label),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value);

  final String label;
  final String value;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr(context, title),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _ink,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _tr(context, title),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _ink,
              fontSize: 20,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

Widget _sectionLink(String label) {
  return Builder(
    builder: (context) => Text(
      _tr(context, label),
      style: const TextStyle(
        color: _brandTeal,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  );
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final initials = label
        .split(' ')
        .where((item) => item.trim().isNotEmpty)
        .take(2)
        .map((item) => item.trim()[0].toUpperCase())
        .join();
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: _brandTeal,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? 'SB' : initials,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SearchHeroBar extends StatelessWidget {
  const _SearchHeroBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _muted, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _tr(context, 'Search here...'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFFB2B6BE)),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: _surfaceAlt, shape: BoxShape.circle),
            child: const Icon(Icons.tune_rounded, color: _ink),
          ),
        ],
      ),
    );
  }
}

class _LessonProgressHeader extends StatelessWidget {
  const _LessonProgressHeader({
    required this.status,
    required this.progress,
  });

  final String status;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.close_rounded, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F3F7),
              color: _brandTeal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.more_vert_rounded),
      ],
    );
  }
}

class _LessonMediaCard extends StatelessWidget {
  const _LessonMediaCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: _brandTeal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Container(
                height: 228,
                color: const Color(0xFFE7F3F0),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.ondemand_video_rounded, size: 72, color: Color(0xFF5E6A7D)),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.bookmark_border_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 0.78,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.fullscreen_rounded, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoursePromoCard extends StatelessWidget {
  const _CoursePromoCard({
    required this.title,
    required this.tag,
    required this.students,
    this.warm = true,
  });

  final String title;
  final String tag;
  final String students;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: warm
              ? const [Color(0xFFF7C36F), Color(0xFFF9D99E)]
              : const [Color(0xFF3CA899), Color(0xFF1F8175)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: warm ? const Color(0x33FFFFFF) : const Color(0x22000000),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: warm ? const Color(0xFF8D6A17) : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  students,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: warm ? const Color(0xFF9E7B2E) : Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: warm ? _ink : Colors.white,
                  fontSize: 24,
                  height: 1.08,
                ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: warm ? const Color(0x33FFFFFF) : const Color(0x26FFFFFF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                warm ? Icons.draw_rounded : Icons.verified_user_outlined,
                size: 42,
                color: warm ? const Color(0xFF7E4E06) : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonListCard extends StatelessWidget {
  const _LessonListCard({
    required this.title,
    required this.subtitle,
    this.accent = const Color(0xFFEAF2FF),
    this.trailingIcon = Icons.play_arrow_rounded,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: _brandTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr(context, title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _tr(context, subtitle),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _muted),
                ),
                const SizedBox(height: 6),
                const Text('★★★★☆', style: TextStyle(color: Color(0xFFF7A928), letterSpacing: 1.2)),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: _brandTeal,
              shape: BoxShape.circle,
            ),
            child: Icon(trailingIcon, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.name,
    required this.subtitle,
    required this.unreadCount,
    this.selected = false,
  });

  final String name;
  final String subtitle;
  final int unreadCount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF7F9FC) : _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          _AvatarBadge(label: name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: _brandTeal, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatMessageRow extends StatelessWidget {
  const _ChatMessageRow({
    required this.name,
    required this.body,
    required this.meta,
    required this.own,
  });

  final String name;
  final String body;
  final String meta;
  final bool own;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: own ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!own) ...[
          _AvatarBadge(label: name),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: own ? const Color(0xFFEAF7F4) : _surfaceAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: own ? const Color(0xFFD0ECE6) : _line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!own) ...[
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                ],
                Text(body),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(meta, style: const TextStyle(color: _muted, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _tr(context, label),
        style: const TextStyle(
          color: _brandTealDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NotificationSummaryChip extends StatelessWidget {
  const _NotificationSummaryChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20, color: _brandTealDark),
          ),
          const SizedBox(height: 4),
          Text(
            _tr(context, label),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _brandTealDark),
          ),
        ],
      ),
    );
  }
}

class _CourseContentTile extends StatelessWidget {
  const _CourseContentTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEDE8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_tr(context, title), style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      _tr(context, subtitle),
                      style: const TextStyle(color: Color(0xFF61706C)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.bolt_rounded, size: 16),
      label: Text(_tr(context, label)),
      onPressed: onTap,
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECE8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC54C2B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _tr(context, message),
              style: const TextStyle(
                color: Color(0xFFC54C2B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(height: 14),
          Text(_tr(context, 'Loading workspace...')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECE8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFC54C2B)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tr(context, 'Could not load this screen'),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tr(context, message),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF61706C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

List<dynamic> _asList(Object? value) {
  return value is List ? value : const [];
}

String _readString(dynamic source, String key) {
  return (_asMap(source)[key] ?? '').toString();
}

int _readInt(dynamic source, String key) {
  final value = _asMap(source)[key];
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _readBool(dynamic source, String key) {
  final value = _asMap(source)[key];
  if (value is bool) {
    return value;
  }
  return value?.toString().toLowerCase() == 'true';
}

String _readPath(dynamic source, List<String> path) {
  dynamic current = source;
  for (final segment in path) {
    current = _asMap(current)[segment];
  }
  return (current ?? '').toString();
}

String _contentSubtitle(dynamic item) {
  final videoUrl = _readString(item, 'video_url');
  final pdfUrl = _readString(item, 'pdf_url');
  final materialUrl = _readString(item, 'material_url');
  if (videoUrl.isNotEmpty) {
    return 'Video lesson';
  }
  if (pdfUrl.isNotEmpty) {
    return 'PDF material';
  }
  if (materialUrl.isNotEmpty) {
    return materialUrl;
  }
  return _readString(item, 'body');
}

IconData _contentIcon(dynamic item) {
  final videoUrl = _readString(item, 'video_url');
  final pdfUrl = _readString(item, 'pdf_url');
  final materialUrl = _readString(item, 'material_url');
  if (videoUrl.isNotEmpty) {
    return Icons.play_circle_outline_rounded;
  }
  if (pdfUrl.isNotEmpty) {
    return Icons.picture_as_pdf_outlined;
  }
  if (materialUrl.isNotEmpty) {
    return Icons.language_rounded;
  }
  return Icons.article_outlined;
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
