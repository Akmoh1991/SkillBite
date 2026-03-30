// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'app/theme/app_colors.dart';
import 'app/theme/app_theme.dart';
import 'core/api/mobile_api_client.dart';
import 'core/session/session_store.dart';
import 'core/session/session_user.dart';

part 'features/owner/owner_admin_flow.dart';
part 'features/chat/chat_page.dart';

const Color _brandTeal = AppColors.brandPrimary;
const Color _brandTealDark = AppColors.brandPrimaryDark;
const Color _ink = AppColors.ink;
const Color _muted = AppColors.muted;
const Color _surface = AppColors.surface;
const Color _surfaceAlt = AppColors.surfaceAlt;
const Color _line = AppColors.line;

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
  bool updateShouldNotify(_AppScope oldWidget) =>
      oldWidget.language != language;
}

bool _isArabic(BuildContext context) =>
    _AppScope.of(context).language == AppLanguage.ar;

String _tr(BuildContext context, String english) {
  if (!_isArabic(context)) {
    return english;
  }
  return _arabicStrings[english] ?? english;
}

const Map<String, String> _arabicStrings = {
  'Reset Password': 'إعادة تعيين كلمة المرور',
  'Reset your password using your username and the recovery email saved on your account.':
      'أعد تعيين كلمة المرور باستخدام اسم المستخدم والبريد الإلكتروني المسجل في الحساب.',
  'Username': 'اسم المستخدم',
  'Recovery email': 'البريد الإلكتروني للاستعادة',
  'New password': 'كلمة المرور الجديدة',
  'Confirm password': 'تأكيد كلمة المرور',
  'Password updated. You can sign in with the new password now.':
      'تم تحديث كلمة المرور. يمكنك تسجيل الدخول بكلمة المرور الجديدة الآن.',
  'Updating...': 'جارٍ التحديث...',
  'Update Password': 'تحديث كلمة المرور',
  'Username and password are required.': 'اسم المستخدم وكلمة المرور مطلوبان.',
  'Sign in to SkillBite': 'تسجيل الدخول',
  'Please enter your information below in order to login to your account':
      'يرجى إدخال بياناتك أدناه لتسجيل الدخول إلى حسابك',
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
  'Create Account': 'إنشاء حساب',
  'Create your business owner account to start using SkillBite.':
      'أنشئ حساب لبدء استخدام SkillBite',
  'Full Name': 'الاسم الكامل',
  'Enter your full name': 'أدخل اسمك الكامل',
  'Email': 'البريد الإلكتروني',
  'Enter your email': 'أدخل بريدك الإلكتروني',
  'Company Name': 'اسم الشركة',
  'Enter your company name': 'أدخل اسم الشركة',
  'Phone Number': 'رقم الجوال',
  'Enter your phone number': 'أدخل رقم الجوال',
  'ID Number': 'رقم الهوية',
  'Enter your ID number': 'أدخل رقم الهوية',
  'Region': 'المنطقة',
  'SEC Business Line': 'قطاع أعمال SEC',
  'Create account': 'إنشاء حساب',
  'Creating account...': 'جارٍ إنشاء الحساب...',
  'Already have an account?': 'لديك حساب بالفعل؟',
  'Eastern region': 'المنطقة الشرقية',
  'Central region': 'المنطقة الوسطى',
  'Western region': 'المنطقة الغربية',
  'Northern region': 'المنطقة الشمالية',
  'Southern region': 'المنطقة الجنوبية',
  'Distribution Contractors': 'مقاولو التوزيع',
  'National Grid Contractors': 'مقاولو الشبكة الوطنية',
  'Projects Contractors': 'مقاولو المشاريع',
  'Generation Contractors': 'مقاولو التوليد',
  'Dawiyat Contractors': 'مقاولو ضوئيات',
  'HSSE Contractors': 'مقاولو الصحة والسلامة والبيئة',
  'Material Sector': 'قطاع المواد',
  'Facilities Sector': 'قطاع المرافق',
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
  'Need an account? Ask your business owner or administrator.':
      'تحتاج إلى حساب؟ اطلبه من مالك النشاط أو المسؤول.',
  'Recipient': 'المستلم',
  'Write your message': 'اكتب رسالتك',
  'Team': 'الفريق',
  'Private': 'خاص',
  'Team Messages': 'رسائل الفريق',
  'No team messages yet.': 'لا توجد رسائل فريق بعد.',
  'People': 'الأشخاص',
  'Person': 'الشخص',
  'No private messages yet.': 'لا توجد رسائل خاصة بعد.',
  'Could not load this file.': 'تعذر تحميل هذا الملف.',
  'Loading workspace...': 'جارٍ تحميل مساحة العمل...',
  'Try again': 'حاول مرة أخرى',
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
  static const SessionStore _sessionStore = SessionStore();

  late final MobileApiClient api;
  SessionUser? sessionUser;
  AppLanguage language = AppLanguage.ar;
  bool restoringSession = true;

  @override
  void initState() {
    super.initState();
    final apiBaseUrlCandidates = buildApiBaseUrlCandidates();
    api = MobileApiClient(
      baseUrl: apiBaseUrlCandidates.first,
      fallbackBaseUrls: apiBaseUrlCandidates.skip(1).toList(),
    );
    unawaited(_restoreSession());
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
          sessionUser = SessionUser.fromJson(_asMap(payload['user']));
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
      final refreshedUser = SessionUser.fromJson(_asMap(payload['user']));
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
    debugPrint(
        'SkillBiteMobileApp build language=$language sessionUser=${sessionUser?.username}');
    return _AppScope(
      language: language,
      onLanguageChanged: _handleLanguageChanged,
      child: MaterialApp(
        title: 'SkillBite Mobile',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
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
        home: restoringSession
            ? const _LoadingState()
            : sessionUser == null
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
  bool passwordObscured = true;
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

  Future<void> _openRegister() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          api: widget.api,
          onRegistered: widget.onLoggedIn,
        ),
      ),
    );
  }

  Widget _buildNativeView(BuildContext context) {
    return _AuthScaffold(
      leading: const _LanguageToggleButton(),
      trailing: const _AuthOrb(icon: Icons.shield_rounded),
      title: _tr(context, 'Sign in to SkillBite'),
      subtitle: _tr(
        context,
        'Please enter your information below in order to login to your account',
      ),
      footer: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          textDirection:
              _isArabic(context) ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Text(
              'Need an account?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF4A5A6A),
                  ),
            ),
            InkWell(
              onTap: _openRegister,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    color: _brandTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthFieldLabel(label: _tr(context, 'Username')),
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
          _AuthFieldLabel(label: _tr(context, 'Password')),
          const SizedBox(height: 10),
          TextField(
            controller: passwordController,
            obscureText: passwordObscured,
            onSubmitted: (_) => loading ? null : _submit(),
            decoration: InputDecoration(
              hintText: _tr(context, 'Enter your password'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => passwordObscured = !passwordObscured);
                },
                icon: Icon(
                  passwordObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _openForgotPassword,
              child: Text(
                _tr(context, 'Forgot Password?'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: _brandTeal),
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
            child: Text(
              loading ? _tr(context, 'Signing in...') : _tr(context, 'Log In'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('LoginScreen build language=${_AppScope.of(context).language}');
    return _buildNativeView(context);
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.api,
    required this.onRegistered,
  });

  final MobileApiClient api;
  final ValueChanged<SessionUser> onRegistered;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const List<String> _regions = [
    'Eastern region',
    'Central region',
    'Western region',
    'Northern region',
    'Southern region',
  ];

  static const List<String> _secBusinessLines = [
    'Distribution Contractors',
    'National Grid Contractors',
    'Projects Contractors',
    'Generation Contractors',
    'Dawiyat Contractors',
    'HSSE Contractors',
    'Material Sector',
    'Facilities Sector',
  ];

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController fullNameArabicController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();
  String selectedRegion = _regions.first;
  String selectedSecBusinessLine = _secBusinessLines.first;

  bool saving = false;
  bool passwordObscured = true;
  String? errorText;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    fullNameController.dispose();
    fullNameArabicController.dispose();
    passwordController.dispose();
    companyNameController.dispose();
    phoneNumberController.dispose();
    idNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      saving = true;
      errorText = null;
    });
    try {
      final user = await widget.api.register(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        fullName: fullNameController.text.trim(),
        fullNameArabic: fullNameArabicController.text.trim().isEmpty
            ? fullNameController.text.trim()
            : fullNameArabicController.text.trim(),
        password: passwordController.text,
        companyName: companyNameController.text.trim(),
        phoneNumber: phoneNumberController.text.trim(),
        idNumber: idNumberController.text.trim(),
        region: selectedRegion,
        secBusinessLine: selectedSecBusinessLine,
      );
      widget.onRegistered(user);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(
            () => errorText = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthFieldLabel(label: label),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthFieldLabel(label: label),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: [
            for (final option in options)
              DropdownMenuItem<String>(
                value: option,
                child: Text(_tr(context, option)),
              ),
          ],
          onChanged: onChanged,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }

  Widget _buildNativeView(BuildContext context) {
    return _AuthScaffold(
      leading: _RoundIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
      trailing: const _LanguageToggleButton(),
      title: _tr(context, 'Create Account'),
      subtitle: _tr(
        context,
        'Create your business owner account to start using SkillBite.',
      ),
      footer: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          textDirection:
              _isArabic(context) ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Text(
              _tr(context, 'Already have an account?'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF4A5A6A),
                  ),
            ),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(
                  _tr(context, 'Log In'),
                  style: const TextStyle(
                    color: _brandTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: usernameController,
            label: _tr(context, 'Username'),
            hint: _tr(context, 'Enter your username'),
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: fullNameController,
            label: _tr(context, 'Full Name'),
            hint: _tr(context, 'Enter your full name'),
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: fullNameArabicController,
            label: _tr(context, 'Full Name'),
            hint: _tr(context, 'Enter your full name'),
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: emailController,
            label: _tr(context, 'Email'),
            hint: _tr(context, 'Enter your email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AuthFieldLabel(label: _tr(context, 'Password')),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: passwordObscured,
                decoration: InputDecoration(
                  hintText: _tr(context, 'Enter your password'),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => passwordObscured = !passwordObscured);
                    },
                    icon: Icon(
                      passwordObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: companyNameController,
            label: _tr(context, 'Company Name'),
            hint: _tr(context, 'Enter your company name'),
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: phoneNumberController,
            label: _tr(context, 'Phone Number'),
            hint: _tr(context, 'Enter your phone number'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: idNumberController,
            label: _tr(context, 'ID Number'),
            hint: _tr(context, 'Enter your ID number'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          _buildDropdownField(
            label: _tr(context, 'Region'),
            value: selectedRegion,
            options: _regions,
            onChanged: saving
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      selectedRegion = value;
                    });
                  },
          ),
          const SizedBox(height: 18),
          _buildDropdownField(
            label: _tr(context, 'SEC Business Line'),
            value: selectedSecBusinessLine,
            options: _secBusinessLines,
            onChanged: saving
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      selectedSecBusinessLine = value;
                    });
                  },
          ),
          if (errorText != null) ...[
            const SizedBox(height: 16),
            _InlineError(message: errorText!),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving ? null : _submit,
            child: Text(
              saving
                  ? _tr(context, 'Creating account...')
                  : _tr(context, 'Create account'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildNativeView(context);
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
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool saving = false;
  bool newPasswordObscured = true;
  bool confirmPasswordObscured = true;
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
        successText =
            'Password updated. You can sign in with the new password now.';
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

  Widget _buildNativeView(BuildContext context) {
    return _AuthScaffold(
      leading: _RoundIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
      trailing: const _LanguageToggleButton(),
      title: _tr(context, 'Reset Password'),
      subtitle: _tr(
        context,
        'Reset your password using your username and the recovery email saved on your account.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthFieldLabel(label: _tr(context, 'Username')),
          const SizedBox(height: 10),
          TextField(
            controller: usernameController,
            decoration: InputDecoration(
              hintText: _tr(context, 'Enter your username'),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          _AuthFieldLabel(label: _tr(context, 'Recovery email')),
          const SizedBox(height: 10),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: _tr(context, 'Enter your email'),
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          _AuthFieldLabel(label: _tr(context, 'New password')),
          const SizedBox(height: 10),
          TextField(
            controller: newPasswordController,
            obscureText: newPasswordObscured,
            decoration: InputDecoration(
              hintText: _tr(context, 'New password'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => newPasswordObscured = !newPasswordObscured);
                },
                icon: Icon(
                  newPasswordObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AuthFieldLabel(label: _tr(context, 'Confirm password')),
          const SizedBox(height: 10),
          TextField(
            controller: confirmPasswordController,
            obscureText: confirmPasswordObscured,
            decoration: InputDecoration(
              hintText: _tr(context, 'Confirm password'),
              prefixIcon: const Icon(Icons.verified_user_outlined),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(
                    () => confirmPasswordObscured = !confirmPasswordObscured,
                  );
                },
                icon: Icon(
                  confirmPasswordObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: _brandTealDark),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving ? null : _submit,
            child: Text(
              saving
                  ? _tr(context, 'Updating...')
                  : _tr(context, 'Update Password'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildNativeView(context);
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.leading,
    required this.trailing,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final Widget leading;
  final Widget trailing;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3FAF7), Color(0xFFF8FBFA)],
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [leading, trailing],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F766E), Color(0xFF13A36E)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x180F172A),
                          blurRadius: 32,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'SkillBite Mobile',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Image.asset(
                          'assets/SkillBite_logo.png',
                          width: 164,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 26,
                                height: 1.1,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.84),
                                    height: 1.45,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x120F172A),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: 18),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthFieldLabel extends StatelessWidget {
  const _AuthFieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: _ink, size: 20),
        ),
      ),
    );
  }
}

class _AuthOrb extends StatelessWidget {
  const _AuthOrb({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF13A36E)],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.96)),
    );
  }
}

class _LanguageToggleButton extends StatelessWidget {
  const _LanguageToggleButton();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: _brandTeal,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: () {
        final scope = _AppScope.of(context);
        scope.onLanguageChanged(
            _isArabic(context) ? AppLanguage.en : AppLanguage.ar);
      },
      icon: const Icon(Icons.language_rounded),
      label: Text(_isArabic(context) ? 'English' : _tr(context, 'Arabic')),
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
            NavigationDestination(
                icon: Icon(Icons.home_outlined), label: _tr(context, 'Home')),
            NavigationDestination(
                icon: Icon(Icons.group_outlined),
                label: _tr(context, 'Employees')),
            NavigationDestination(
                icon: Icon(Icons.badge_outlined),
                label: _tr(context, 'Titles')),
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                label: _tr(context, 'Courses')),
            NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                label: _tr(context, 'Reports')),
            NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                label: _tr(context, 'Checklists')),
            NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                label: _tr(context, 'Chat')),
          ]
        : [
            NavigationDestination(
                icon: Icon(Icons.home_outlined), label: _tr(context, 'Home')),
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                label: _tr(context, 'Courses')),
            NavigationDestination(
                icon: Icon(Icons.workspace_premium_outlined),
                label: _tr(context, 'History')),
            NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                label: _tr(context, 'Checklists')),
            NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                label: _tr(context, 'Chat')),
          ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        titleSpacing: 20,
        title: Row(
          children: [
            _AvatarBadge(label: widget.user.displayName, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.user.businessName.isEmpty
                        ? '@${widget.user.username}'
                        : widget.user.businessName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _muted,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _line),
              ),
              child: IconButton(
                onPressed: _openNotifications,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _line),
              ),
              child: IconButton(
                onPressed: () async => widget.onLogout(),
                icon: const Icon(Icons.logout_rounded),
              ),
            ),
          ),
        ],
      ),
      body: KeyedSubtree(
        key: ValueKey('${widget.user.role}-$index'),
        child: pages[index],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.only(top: 4),
          child: NavigationBar(
            selectedIndex: index,
            height: 72,
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
          return _PageSliverBody(
            slivers: [
              _PageSliverSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_tr(context, 'Activity for ')}${user.businessName}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: _muted),
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
                          label: user.role == 'employee'
                              ? _tr(context, 'Pending courses')
                              : _tr(context, 'Active employees'),
                          value: user.role == 'employee'
                              ? '${summary['pending_course_count'] ?? 0}'
                              : '${summary['active_employee_count'] ?? 0}',
                        ),
                        _NotificationSummaryChip(
                          label: user.role == 'employee'
                              ? _tr(context, 'Pending checklists')
                              : _tr(context, 'Active courses'),
                          value: user.role == 'employee'
                              ? '${summary['pending_checklist_count'] ?? 0}'
                              : '${summary['active_course_count'] ?? 0}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (notifications.isEmpty)
                _PageSliverSection(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  child: _SectionCard(
                    title: _tr(context, 'All caught up'),
                    child: Text(_tr(
                        context, 'There are no new notifications right now.')),
                  ),
                )
              else
                _PageSliverList(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _SectionCard(
                        title: _readString(item, 'title'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_readString(item, 'body')),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _StatusChip(
                                  label: _readString(item, 'kind')
                                      .replaceAll('_', ' '),
                                ),
                                const SizedBox(width: 8),
                                if (_readInt(item, 'unread_count') > 0)
                                  _StatusChip(
                                    label:
                                        '${_readInt(item, 'unread_count')} ${_tr(context, 'new')}',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
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

  Future<void> _openAssignmentCourse(
      BuildContext context, int assignmentId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeCourseDetailScreen(
          api: api,
          assignmentId: assignmentId,
        ),
      ),
    );
  }

  Future<void> _openChecklist(BuildContext context, int checklistId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeChecklistDetailScreen(
          api: api,
          checklistId: checklistId,
        ),
      ),
    );
  }

  Future<void> _openCoursesPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EmployeeCoursesPage(api: api)),
    );
  }

  Widget _buildNativeView(
    BuildContext context,
    Map<String, dynamic> dashboard,
    List<dynamic> assignments,
    List<dynamic> checklists,
  ) {
    return _PageBody(
      children: [
        _HeaderRow(
          title: 'Courses',
          titleColor: _brandTealDark,
          titleFontSize: 26,
          trailing: _sectionLink(
            'View all',
            onTap: () => _openCoursesPage(context),
          ),
        ),
        const SizedBox(height: 16),
        if (assignments.isEmpty)
          const _SectionCard(
              title: 'Courses', child: Text('No active courses.'))
        else
          for (final item in assignments.take(3)) ...[
            _NativeCoursePromoCard(
              eyebrow: _readString(item, 'status_label'),
              title: _readPath(item, ['course', 'title']),
              meta: '${_readPath(item, [
                    'course',
                    'estimated_minutes'
                  ])} ${_tr(context, 'min')}',
              supporting: _readString(_asMap(item['course']), 'description'),
              imageUrl:
                  api.resolveUrl(_readPath(item, ['course', 'card_image_url'])),
              icon: _readBool(_asMap(item['course']), 'has_exam')
                  ? Icons.verified_outlined
                  : Icons.play_circle_outline_rounded,
              onTap: () => _openAssignmentCourse(context, _readInt(item, 'id')),
            ),
            const SizedBox(height: 14),
          ],
        const SizedBox(height: 8),
        const _HeaderRow(
          title: 'Checklists',
          titleColor: _brandTealDark,
          titleFontSize: 26,
        ),
        const SizedBox(height: 14),
        if (checklists.isEmpty)
          const _SectionCard(
            title: 'Checklists',
            child: Text('No checklists assigned.'),
          )
        else
          for (final item in checklists.take(3)) ...[
            _NativeLessonTile(
              title: _readString(item, 'title'),
              subtitle: _readBool(item, 'completed_today')
                  ? 'Completed today'
                  : 'Pending checklist',
              accent: const Color(0xFFEAF7F4),
              trailingIcon: Icons.checklist_rounded,
              onTap: () => _openChecklist(context, _readInt(item, 'id')),
            ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: api.get('/employee/dashboard/'),
      builder: (context, payload) {
        final dashboard = _asMap(payload['dashboard']);
        final assignments = _asList(dashboard['dashboard_course_assignments']);
        final checklists = _asList(dashboard['assigned_checklists']);
        return _buildNativeView(context, dashboard, assignments, checklists);
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

  Future<void> _openAssignment(int assignmentId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeCourseDetailScreen(
          api: widget.api,
          assignmentId: assignmentId,
        ),
      ),
    );
    if (mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: future,
      builder: (context, payload) {
        final courses = _asList(payload['courses']);
        final featuredCourse = courses.isEmpty ? null : _asMap(courses.first);
        final moreCourses =
            courses.length > 1 ? courses.skip(1).toList() : const <dynamic>[];
        final activeCourses = courses.where((item) {
          final status = _readString(item, 'status_label').toLowerCase();
          return !status.contains('complete');
        }).length;
        final totalMinutes = courses.fold<int>(
          0,
          (sum, item) =>
              sum + _readInt(_asMap(item['course']), 'estimated_minutes'),
        );
        return _PageSliverBody(
          slivers: [
            _PageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeroCard(
                    title: _tr(context, 'Courses'),
                    subtitle: featuredCourse == null
                        ? 'No assigned courses yet'
                        : _readPath(featuredCourse, ['course', 'title']),
                    value: featuredCourse == null
                        ? 'New training will appear here when it is assigned.'
                        : '$activeCourses in progress - $totalMinutes ${_tr(context, 'min')} total',
                    icon: Icons.auto_stories_rounded,
                  ),
                  const SizedBox(height: 16),
                  _DashboardMetricRow(
                    metrics: [
                      _DashboardMetricData(
                        'Courses',
                        '${courses.length}',
                        icon: Icons.menu_book_rounded,
                      ),
                      _DashboardMetricData(
                        'Pending courses',
                        '$activeCourses',
                        icon: Icons.timelapse_rounded,
                      ),
                      _DashboardMetricData(
                        'Learning time',
                        '$totalMinutes ${_tr(context, 'min')}',
                        icon: Icons.schedule_rounded,
                      ),
                    ],
                  ),
                  if (featuredCourse != null) ...[
                    const SizedBox(height: 20),
                    _NativeCoursePromoCard(
                      eyebrow:
                          _readString(featuredCourse, 'status_label').isEmpty
                              ? 'Course'
                              : _readString(featuredCourse, 'status_label'),
                      title: _readPath(featuredCourse, ['course', 'title']),
                      meta:
                          '${_readInt(_asMap(featuredCourse['course']), 'estimated_minutes')} ${_tr(context, 'min')}',
                      supporting:
                          _readPath(featuredCourse, ['course', 'description']),
                      imageUrl: widget.api.resolveUrl(
                        _readPath(featuredCourse, ['course', 'card_image_url']),
                      ),
                      icon: Icons.play_circle_outline_rounded,
                      onTap: () =>
                          _openAssignment(_readInt(featuredCourse, 'id')),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _HeaderRow(
                    title: featuredCourse == null
                        ? 'Assigned courses'
                        : 'More courses',
                    trailing: _RoundIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: _reload,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (courses.isEmpty)
              const _PageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: _SectionCard(
                  title: 'Courses',
                  child: Text('No courses assigned.'),
                ),
              )
            else if (moreCourses.isEmpty)
              const _PageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: _SectionCard(
                  title: 'Courses',
                  child: Text('No additional courses right now.'),
                ),
              )
            else
              _PageSliverList(
                itemCount: moreCourses.length,
                itemBuilder: (context, index) {
                  final item = _asMap(moreCourses[index]);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _CompactCourseListCard(
                      imageUrl: widget.api.resolveUrl(
                        _readPath(item, ['course', 'card_image_url']),
                      ),
                      eyebrow: _readString(item, 'status_label'),
                      title: _readPath(item, ['course', 'title']),
                      description: _readPath(item, ['course', 'description']),
                      metadata: [
                        '${_readPath(item, [
                              'course',
                              'estimated_minutes'
                            ])} ${_tr(context, 'min')}',
                        '${_readPath(item, [
                              'course',
                              'content_item_total'
                            ])} ${_tr(context, 'Items')}',
                        _readPath(item, ['course', 'card_label']),
                      ],
                      onTap: () => _openAssignment(_readInt(item, 'id')),
                    ),
                  );
                },
              ),
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
  State<EmployeeLearningHistoryPage> createState() =>
      _EmployeeLearningHistoryPageState();
}

class _EmployeeLearningHistoryPageState
    extends State<EmployeeLearningHistoryPage> {
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

  Future<void> _openAssignment(int assignmentId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeCourseDetailScreen(
          api: widget.api,
          assignmentId: assignmentId,
        ),
      ),
    );
    if (mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: future,
      builder: (context, payload) {
        final history = _asList(payload['learning_history']);
        final totalMinutes = history.fold<int>(
          0,
          (sum, item) =>
              sum + _readInt(_asMap(item['course']), 'estimated_minutes'),
        );
        return _PageSliverBody(
          slivers: [
            _PageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeroCard(
                    title: 'Learning History',
                    subtitle: history.isEmpty
                        ? 'Your completed learning will appear here'
                        : '${history.length} completed courses',
                    value: history.isEmpty
                        ? 'Finished training stays easy to revisit.'
                        : '$totalMinutes ${_tr(context, 'min')} completed',
                    icon: Icons.workspace_premium_rounded,
                  ),
                  const SizedBox(height: 16),
                  _DashboardMetricRow(
                    metrics: [
                      _DashboardMetricData(
                        'Completed',
                        '${history.length}',
                        icon: Icons.task_alt_rounded,
                      ),
                      _DashboardMetricData(
                        'Minutes',
                        '$totalMinutes',
                        icon: Icons.schedule_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _HeaderRow(
                    title: 'Learning History',
                    trailing: _RoundIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: _reload,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (history.isEmpty)
              const _PageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: _SectionCard(
                  title: 'History',
                  child: Text('No completed courses yet.'),
                ),
              )
            else
              _PageSliverList(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = _asMap(history[index]);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _CompactCourseListCard(
                      imageUrl: widget.api.resolveUrl(
                        _readPath(item, ['course', 'card_image_url']),
                      ),
                      eyebrow: _readString(item, 'status_label'),
                      title: _readPath(item, ['course', 'title']),
                      description: _readPath(item, ['course', 'description']),
                      metadata: [
                        '${_readPath(item, [
                              'course',
                              'estimated_minutes'
                            ])} ${_tr(context, 'min')}',
                        '${_readPath(item, [
                              'course',
                              'content_item_total'
                            ])} ${_tr(context, 'Items')}',
                      ],
                      onTap: () => _openAssignment(_readInt(item, 'id')),
                    ),
                  );
                },
              ),
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
  State<EmployeeCourseDetailScreen> createState() =>
      _EmployeeCourseDetailScreenState();
}

class _EmployeeCourseDetailScreenState
    extends State<EmployeeCourseDetailScreen> {
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
    final materialUrl =
        widget.api.resolveUrl(_readString(item, 'material_url'));
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
        _readString(item, 'body').isNotEmpty
            ? _readString(item, 'body')
            : 'No content URL available.',
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
      await widget.api
          .post('/employee/courses/${widget.assignmentId}/complete/', {});
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
          final courseDescription = _readString(course, 'description');
          final statusLabel = _readString(assignment, 'status_label').isEmpty
              ? _tr(context, 'In progress')
              : _readString(assignment, 'status_label');
          final featuredContent =
              contentItems.isEmpty ? const <dynamic>[] : [contentItems.first];
          final remainingContent = contentItems.length > 1
              ? contentItems.skip(1).toList()
              : const <dynamic>[];
          return _PageBody(
            children: [
              _DashboardHeroCard(
                title: statusLabel,
                subtitle: _readString(course, 'title'),
                value:
                    '${contentItems.length} ${_tr(context, 'Items')} - ${_readInt(course, 'estimated_minutes')} ${_tr(context, 'min')}',
                icon: hasExam
                    ? Icons.quiz_rounded
                    : Icons.play_circle_outline_rounded,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(label: statusLabel),
                  _StatusChip(
                      label: '${contentItems.length} ${_tr(context, 'Items')}'),
                  if (hasExam) _StatusChip(label: _tr(context, 'Exam')),
                ],
              ),
              if (courseDescription.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Course',
                  child: Text(courseDescription),
                ),
              ],
              const SizedBox(height: 16),
              if (featuredContent.isEmpty)
                _SectionCard(
                    title: _tr(context, 'Lesson'),
                    child: Text(_tr(context, 'No mobile content items.')))
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
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontSize: 18),
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
              if (hasExam) ...[
                _SectionCard(
                  title: _tr(context, 'Exam'),
                  child: const Text(
                    'Review the lesson content, then continue to the exam when you are ready.',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: submitting
                    ? null
                    : hasExam
                        ? () async {
                            final changed =
                                await Navigator.of(context).push<bool>(
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
      final nextController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
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
                _LessonProgressHeader(
                    status: _tr(context, 'In progress'), progress: 0.26),
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
                        aspectRatio: controller!.value.aspectRatio == 0
                            ? 16 / 9
                            : controller!.value.aspectRatio,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22)),
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
                                controller!.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.35),
                                  thumbColor: Colors.white,
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: controller!
                                      .value.position.inMilliseconds
                                      .toDouble()
                                      .clamp(
                                        0,
                                        (controller!.value.duration
                                                        .inMilliseconds ==
                                                    0
                                                ? 1
                                                : controller!.value.duration
                                                    .inMilliseconds)
                                            .toDouble(),
                                      ),
                                  max: (controller!.value.duration
                                                  .inMilliseconds ==
                                              0
                                          ? 1
                                          : controller!
                                              .value.duration.inMilliseconds)
                                      .toDouble(),
                                  onChanged: (value) {
                                    controller!.seekTo(
                                        Duration(milliseconds: value.round()));
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final uri = Uri.parse(widget.videoUrl);
                                if (!await launchUrl(uri,
                                        mode: LaunchMode.externalApplication) &&
                                    mounted) {
                                  _showSnack(context,
                                      'Could not open this video externally.');
                                }
                              },
                              icon: const Icon(Icons.fullscreen_rounded,
                                  color: Colors.white),
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
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontSize: 18),
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
  String? errorText;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                loading = false;
                errorText = null;
              });
            }
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              loading = false;
              errorText = error.description.isEmpty
                  ? 'Could not load this file.'
                  : error.description;
            });
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
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
                  mounted) {
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
          if (loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xCCFFFFFF),
                child: _LoadingState(),
              ),
            ),
          if (errorText != null)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xF7F7FAFC),
                child: Center(
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
                              const Icon(
                                Icons.link_off_rounded,
                                size: 36,
                                color: Color(0xFFC54C2B),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _tr(context, 'Could not load this screen'),
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                errorText!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF61706C),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonal(
                                  onPressed: () {
                                    setState(() {
                                      loading = true;
                                      errorText = null;
                                    });
                                    controller
                                        .loadRequest(Uri.parse(widget.url));
                                  },
                                  child: Text(_tr(context, 'Try again')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
    future = widget.api
        .post('/employee/courses/${widget.assignmentId}/exam/start/', {});
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
      final result = await widget.api
          .post('/employee/courses/${widget.assignmentId}/exam/submit/', {
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
                subtitle:
                    'Pass score ${_readInt(exam, 'passing_score_percent')}%',
                value: '${_readInt(exam, 'duration_minutes')} min',
              ),
              const SizedBox(height: 16),
              for (final rawQuestion in questions) ...[
                _SectionCard(
                  title: 'Question ${_readInt(rawQuestion, 'order')}',
                  child: _ExamQuestionCard(
                    question: _asMap(rawQuestion),
                    answers: answers,
                    controller:
                        _controllerForQuestion(_readInt(rawQuestion, 'id')),
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
              value: (answer is List ? answer : const [])
                  .contains(_readInt(option, 'id').toString()),
              contentPadding: EdgeInsets.zero,
              title: Text(_readString(option, 'text')),
              onChanged: (checked) {
                final values = List<String>.from(
                    answer is List ? answer : const <String>[]);
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
        final completedToday = checklists
            .where((item) => _readBool(item, 'completed_today'))
            .length;
        final pendingCount = checklists.length - completedToday;
        return _PageSliverBody(
          slivers: [
            _PageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeroCard(
                    title: _tr(context, 'Checklists'),
                    subtitle: completedToday == 0
                        ? 'Stay on top of your operational routines'
                        : '$completedToday ${_tr(context, 'Completed today')}',
                    value: pendingCount == 0
                        ? 'All checklist work is up to date.'
                        : '$pendingCount ${_tr(context, 'Pending checklists')}',
                    icon: Icons.checklist_rounded,
                  ),
                  const SizedBox(height: 16),
                  _DashboardMetricRow(
                    metrics: [
                      _DashboardMetricData(
                        'Checklists',
                        '${checklists.length}',
                        icon: Icons.fact_check_outlined,
                      ),
                      _DashboardMetricData(
                        'Completed today',
                        '$completedToday',
                        icon: Icons.task_alt_rounded,
                      ),
                      _DashboardMetricData(
                        'Pending checklists',
                        '$pendingCount',
                        icon: Icons.pending_actions_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _HeaderRow(
                    title: 'Assigned checklists',
                    trailing: _RoundIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: _reload,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (checklists.isEmpty)
              const _PageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: _SectionCard(
                  title: 'Checklists',
                  child: Text('No checklists assigned.'),
                ),
              )
            else
              _PageSliverList(
                itemCount: checklists.length,
                itemBuilder: (context, index) {
                  final item = checklists[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _NativeLessonTile(
                      title: _readString(item, 'title'),
                      subtitle: _readBool(item, 'completed_today')
                          ? 'Completed today'
                          : 'Pending checklist',
                      accent: _readBool(item, 'completed_today')
                          ? const Color(0xFFEAF7F4)
                          : const Color(0xFFFFF1E7),
                      trailingIcon: _readBool(item, 'completed_today')
                          ? Icons.task_alt_rounded
                          : Icons.checklist_rounded,
                      onTap: () async {
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
                    ),
                  );
                },
              ),
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
  State<EmployeeChecklistDetailScreen> createState() =>
      _EmployeeChecklistDetailScreenState();
}

class _EmployeeChecklistDetailScreenState
    extends State<EmployeeChecklistDetailScreen> {
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
      await widget.api
          .post('/employee/checklists/${widget.checklistId}/complete/', {
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
          final description = _readString(checklist, 'description');
          final frequency = _readString(checklist, 'frequency');
          return _PageBody(
            children: [
              _DashboardHeroCard(
                title:
                    frequency.isEmpty ? _tr(context, 'Checklist') : frequency,
                subtitle: _readString(checklist, 'title'),
                value: completed
                    ? _tr(context, 'Completed today')
                    : '${items.length} items to review',
                icon: Icons.fact_check_rounded,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    label: completed ? 'Completed today' : 'Pending checklist',
                  ),
                  _StatusChip(
                      label: '${items.length} ${_tr(context, 'Items')}'),
                  if (frequency.isNotEmpty) _StatusChip(label: frequency),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: _tr(context, 'Checklist'),
                  child: Text(description),
                ),
              ],
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Items',
                child: items.isEmpty
                    ? const Text('No checklist items.')
                    : Column(
                        children: [
                          for (var index = 0; index < items.length; index++)
                            _ChecklistItemTile(
                              index: index + 1,
                              title: _readString(_asMap(items[index]), 'title'),
                              completed: completed,
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: completed || submitting
                    ? null
                    : () => _completeChecklist(items),
                child: Text(completed
                    ? 'Already Completed'
                    : submitting
                        ? 'Submitting...'
                        : 'Complete Checklist'),
              ),
            ],
          );
        },
      ),
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
  final Widget Function(BuildContext context, Map<String, dynamic> payload)
      builder;

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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7FBF9), Color(0xFFF2F7F5)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageSliverBody extends StatelessWidget {
  const _PageSliverBody({required this.slivers});

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7FBF9), Color(0xFFF2F7F5)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: CustomScrollView(
          cacheExtent: 900,
          slivers: slivers,
        ),
      ),
    );
  }
}

class _PageSliverSection extends StatelessWidget {
  const _PageSliverSection({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 0),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PageSliverList extends StatelessWidget {
  const _PageSliverList({
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 120),
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: itemBuilder(context, index),
            ),
          );
        }, childCount: itemCount),
      ),
    );
  }
}

class _DashboardHeroCard extends StatelessWidget {
  const _DashboardHeroCard({
    required this.title,
    this.subtitle = '',
    required this.value,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandTeal, Color(0xFF13A36E)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 15,
                      ),
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          height: 1.08,
                          fontSize: 22,
                        ),
                  ),
                  const SizedBox(height: 8),
                ] else
                  const SizedBox(height: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricRow extends StatelessWidget {
  const _DashboardMetricRow({required this.metrics});

  final List<_DashboardMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            SizedBox(
              width: 188,
              child: _DashboardMetricCard(data: metrics[i]),
            ),
            if (i < metrics.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({required this.data});

  final _DashboardMetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, size: 22, color: _brandTeal),
          ),
          const SizedBox(height: 12),
          Text(data.value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            _tr(context, data.label),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricData {
  const _DashboardMetricData(this.label, this.value, {required this.icon});

  final String label;
  final String value;
  final IconData icon;
}

class _OptimizedCourseCardImage extends StatelessWidget {
  const _OptimizedCourseCardImage({
    required this.imageUrl,
    required this.title,
    this.aspectRatio = 1.85,
    this.borderRadius = 22,
  });

  final String imageUrl;
  final String title;
  final double aspectRatio;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final trimmedImageUrl = imageUrl.trim();
    final hasImage = trimmedImageUrl.isNotEmpty &&
        (Uri.tryParse(trimmedImageUrl)?.hasScheme ?? false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: !hasImage
            ? _LibraryCourseFallbackArt(title: title)
            : LayoutBuilder(
                builder: (context, constraints) {
                  final dpr = MediaQuery.devicePixelRatioOf(context);
                  final width = constraints.hasBoundedWidth &&
                          constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : MediaQuery.sizeOf(context).width;
                  final targetWidth =
                      (width * dpr).clamp(320.0, 1280.0).round();

                  return Image.network(
                    trimmedImageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: targetWidth,
                    filterQuality: FilterQuality.low,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded || frame != null) {
                        return child;
                      }
                      return _LibraryCourseFallbackArt(title: title);
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        _LibraryCourseFallbackArt(title: title),
                  );
                },
              ),
      ),
    );
  }
}

class _NativeCoursePromoCard extends StatelessWidget {
  const _NativeCoursePromoCard({
    required this.eyebrow,
    required this.title,
    required this.meta,
    required this.icon,
    this.supporting = '',
    this.imageUrl = '',
    this.onTap,
  });

  final String eyebrow;
  final String title;
  final String meta;
  final String supporting;
  final IconData icon;
  final String imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x100F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OptimizedCourseCardImage(
                imageUrl: imageUrl,
                title: title,
                aspectRatio: 1.7,
                borderRadius: 22,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _tr(context, eyebrow),
                      style: const TextStyle(
                        color: _brandTealDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _tr(context, meta),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _muted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                _tr(context, title),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      height: 1.12,
                    ),
              ),
              if (supporting.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _tr(context, supporting),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 18),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: _brandTeal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NativeLessonTile extends StatelessWidget {
  const _NativeLessonTile({
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
    this.accent = const Color(0xFFEAF2FF),
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData trailingIcon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(trailingIcon, color: _brandTeal),
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
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _tr(context, subtitle),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
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
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _tr(context, subtitle),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white, height: 1.15),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
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
    this.titleColor = _ink,
    this.titleFontSize = 20,
  });

  final String title;
  final Widget? trailing;
  final Color titleColor;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _tr(context, title),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: titleColor,
                  fontSize: titleFontSize,
                ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

Widget _sectionLink(String label, {VoidCallback? onTap}) {
  return Builder(
    builder: (context) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            _tr(context, label),
            style: const TextStyle(
              color: _brandTeal,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),
  );
}

ButtonStyle _compactHeaderActionStyle() {
  return FilledButton.styleFrom(
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return FilledButton.icon(
        style: _compactHeaderActionStyle(),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(_tr(context, label)),
      );
    }
    return FilledButton(
      style: _compactHeaderActionStyle(),
      onPressed: onPressed,
      child: Text(_tr(context, label)),
    );
  }
}

class _HeaderTonalButton extends StatelessWidget {
  const _HeaderTonalButton({
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      style: _compactHeaderActionStyle(),
      onPressed: onPressed,
      child: Text(_tr(context, label)),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.label,
    this.size = 52,
  });

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = label
        .split(' ')
        .where((item) => item.trim().isNotEmpty)
        .take(2)
        .map((item) => item.trim()[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _brandTeal,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? 'SB' : initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.34,
          ),
        ),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
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
                            const Icon(Icons.ondemand_video_rounded,
                                size: 72, color: Color(0xFF5E6A7D)),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 18),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: _muted),
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
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
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

class _CompactCourseListCard extends StatelessWidget {
  const _CompactCourseListCard({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.metadata,
    required this.onTap,
    this.eyebrow = '',
  });

  final String imageUrl;
  final String title;
  final String description;
  final List<String> metadata;
  final VoidCallback onTap;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final safeTitle =
        title.trim().isEmpty ? _tr(context, 'Course') : title.trim();
    final safeDescription = description.trim().isEmpty
        ? _tr(
            context,
            'Practical course content with clear guidance and structured steps.',
          )
        : description.trim();
    final safeEyebrow = eyebrow.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x100F172A),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 102,
                child: _OptimizedCourseCardImage(
                  imageUrl: imageUrl,
                  title: safeTitle,
                  aspectRatio: 1.04,
                  borderRadius: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (safeEyebrow.isNotEmpty) ...[
                      Text(
                        _tr(context, safeEyebrow),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _muted,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      _tr(context, safeTitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tr(context, safeDescription),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF7B879B),
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in metadata)
                          if (item.trim().isNotEmpty)
                            _StatusChip(label: _tr(context, item)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA6B2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryCourseFallbackArt extends StatelessWidget {
  const _LibraryCourseFallbackArt({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCADFD9), Color(0xFF8FA9A3), Color(0xFF4C5D5A)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -30,
            right: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -24,
            left: -18,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _tr(context, title),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
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
    this.onTap,
  });

  final String name;
  final String subtitle;
  final int unreadCount;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
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
                  decoration: const BoxDecoration(
                    color: _brandTeal,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                ],
                Text(body),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(meta,
                      style: const TextStyle(color: _muted, fontSize: 12)),
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

class _ChatModeChip extends StatelessWidget {
  const _ChatModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _surface : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x100F172A),
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selected ? _ink : const Color(0xFF61706C),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordDetailLine extends StatelessWidget {
  const _RecordDetailLine({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF61706C)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF61706C),
                  height: 1.45,
                ),
          ),
        ),
      ],
    );
  }
}

class _ChecklistItemTile extends StatelessWidget {
  const _ChecklistItemTile({
    required this.index,
    required this.title,
    required this.completed,
  });

  final int index;
  final String title;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFEAF7F4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: completed ? const Color(0xFFD2EBE4) : _line,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: completed ? _brandTeal : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: completed
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    )
                  : Text(
                      '$index',
                      style: const TextStyle(
                        color: _brandTealDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _tr(context, title),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementRecordCard extends StatelessWidget {
  const _ManagementRecordCard({
    required this.title,
    required this.description,
    required this.icon,
    this.metadata = const [],
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.detail,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> metadata;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final safePrimaryActionLabel = (primaryActionLabel ?? '').trim();
    final safeSecondaryActionLabel = (secondaryActionLabel ?? '').trim();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: _brandTeal),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context, title),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tr(context, description),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (metadata.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in metadata)
                    if (item.trim().isNotEmpty) _StatusChip(label: item),
                ],
              ),
            ],
            if (detail != null) ...[
              const SizedBox(height: 14),
              detail!,
            ],
            if (safePrimaryActionLabel.isNotEmpty ||
                safeSecondaryActionLabel.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (safePrimaryActionLabel.isNotEmpty)
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: onPrimaryAction,
                        child: Text(safePrimaryActionLabel),
                      ),
                    ),
                  if (safePrimaryActionLabel.isNotEmpty &&
                      safeSecondaryActionLabel.isNotEmpty)
                    const SizedBox(width: 12),
                  if (safeSecondaryActionLabel.isNotEmpty)
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: onSecondaryAction,
                        child: Text(safeSecondaryActionLabel),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RuleAssignmentTile extends StatelessWidget {
  const _RuleAssignmentTile({
    required this.jobTitle,
    required this.checklistTitle,
  });

  final String jobTitle;
  final String checklistTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_tree_rounded, color: _brandTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr(context, jobTitle),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _tr(context, checklistTitle),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right_rounded, color: _muted),
        ],
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
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 20, color: _brandTealDark),
          ),
          const SizedBox(height: 4),
          Text(
            _tr(context, label),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: _brandTealDark),
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
                    Text(_tr(context, title),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
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
                    child: const Icon(Icons.wifi_off_rounded,
                        color: Color(0xFFC54C2B)),
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
