// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SkillBiteMobileApp());
}

class SkillBiteMobileApp extends StatefulWidget {
  const SkillBiteMobileApp({super.key});

  @override
  State<SkillBiteMobileApp> createState() => _SkillBiteMobileAppState();
}

class _SkillBiteMobileAppState extends State<SkillBiteMobileApp> {
  final MobileApiClient api = MobileApiClient(
    baseUrl: kIsWeb || defaultTargetPlatform == TargetPlatform.android
        ? 'http://127.0.0.1:8000/api/mobile/v1'
        : 'http://10.0.2.2:8000/api/mobile/v1',
  );
  SessionUser? sessionUser;

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillBite Mobile',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: sessionUser == null
          ? LoginScreen(api: api, onLoggedIn: _handleLogin)
          : RoleShell(
              api: api,
              user: sessionUser!,
              onLogout: _handleLogout,
            ),
    );
  }
}

ThemeData _buildTheme() {
  const seed = Color(0xFF0F766E);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    primary: seed,
    secondary: const Color(0xFFE9A33B),
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF4F1E8),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.2),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45),
      bodySmall: TextStyle(fontSize: 12, height: 1.4),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF11221F),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF11221F),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: const Color(0xFF12312C).withValues(alpha: 0.08)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.94),
      labelStyle: const TextStyle(color: Color(0xFF5D6D69)),
      hintStyle: const TextStyle(color: Color(0xFF90A09C)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: const Color(0xFF12312C).withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: seed, width: 1.4),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.96),
      indicatorColor: const Color(0xFFD7EFE8),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? seed : const Color(0xFF71807C),
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected) ? seed : const Color(0xFF71807C),
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F6F4),
      selectedColor: const Color(0xFFD7EFE8),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF24403A)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
  );
}

class MobileApiClient {
  MobileApiClient({required this.baseUrl});

  final String baseUrl;
  String? token;

  Future<SessionUser> login(String username, String password) async {
    final payload = await post('/auth/login/', {
      'username': username,
      'password': password,
      'device_name': 'flutter-dev',
    }, includeAuth: false);
    token = payload['token'] as String?;
    return SessionUser.fromJson(payload['user'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers());
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, Object body, {bool includeAuth = true}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(includeAuth: includeAuth),
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  Map<String, String> _headers({bool includeAuth = true}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (includeAuth && token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF4EF), Color(0xFFF4F1E8)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -120,
              right: -40,
              child: _BackdropOrb(size: 260, color: Color(0xFFB9E1D6)),
            ),
            const Positioned(
              top: 140,
              left: -70,
              child: _BackdropOrb(size: 180, color: Color(0xFFE8C98E)),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9EEE8),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.auto_stories_rounded, size: 28),
                            ),
                            const SizedBox(height: 18),
                            Text('SkillBite Mobile', style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 10),
                            Text(
                              'Employee and business-owner access through the new mobile API.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFF556560),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8F4),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Demo Access',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _DemoChip(
                                        label: 'Owner Demo',
                                        onTap: () {
                                          usernameController.text = 'demo_owner';
                                          passwordController.text = 'pass12345';
                                          setState(() => errorText = null);
                                        },
                                      ),
                                      _DemoChip(
                                        label: 'Employee Demo',
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
                            const SizedBox(height: 18),
                            TextField(
                              controller: usernameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              onSubmitted: (_) => loading ? null : _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                            ),
                            if (errorText != null) ...[
                              const SizedBox(height: 12),
                              _InlineError(message: errorText!),
                            ],
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: loading ? null : _submit,
                              icon: Icon(loading ? Icons.hourglass_top_rounded : Icons.arrow_forward_rounded),
                              label: Text(loading ? 'Signing in...' : 'Sign in'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final ownerMode = widget.user.role == 'business_owner';
    final pages = ownerMode
        ? [
            OwnerDashboardPage(api: widget.api, user: widget.user),
            OwnerEmployeesPage(api: widget.api),
            OwnerCoursesPage(api: widget.api),
            OwnerReportsPage(api: widget.api),
            OwnerChecklistsPage(api: widget.api),
          ]
        : [
            EmployeeDashboardPage(api: widget.api, user: widget.user),
            EmployeeCoursesPage(api: widget.api),
            EmployeeChecklistsPage(api: widget.api),
          ];
    final destinations = ownerMode
        ? const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Employees'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Courses'),
            NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Reports'),
            NavigationDestination(icon: Icon(Icons.checklist_outlined), label: 'Checklists'),
          ]
        : const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Courses'),
            NavigationDestination(icon: Icon(Icons.checklist_outlined), label: 'Checklists'),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.user.displayName),
            Text(
              ownerMode ? 'Business owner workspace' : 'Employee workspace',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6A7A76),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.user.businessName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF12312C).withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    widget.user.businessName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: () async => widget.onLogout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF4EF), Color(0xFFF4F1E8)],
          ),
        ),
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: NavigationBar(
            selectedIndex: index,
            destinations: destinations,
            onDestinationSelected: (value) => setState(() => index = value),
          ),
        ),
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
        return _PageBody(
          children: [
            _HeroCard(
              title: 'Employee',
              subtitle: user.businessName,
              value: user.displayName,
            ),
            const SizedBox(height: 16),
            _MetricRow(
              metrics: [
                _MetricData('Completed', '${dashboard['completed_course_count'] ?? 0}'),
                _MetricData('Active Courses', '${dashboard['active_course_count'] ?? 0}'),
                _MetricData('Checklists', '${dashboard['assigned_checklist_count'] ?? 0}'),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Current Courses',
              child: assignments.isEmpty
                  ? const Text('No active courses.')
                  : Column(
                      children: [
                        for (final item in assignments)
                          _SimpleListTile(
                            title: _readPath(item, ['course', 'title']),
                            subtitle: _readString(item, 'status_label'),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Today Checklists',
              child: checklists.isEmpty
                  ? const Text('No checklists assigned.')
                  : Column(
                      children: [
                        for (final item in checklists)
                          _SimpleListTile(
                            title: _readString(item, 'title'),
                            subtitle: _readBool(item, 'completed_today') ? 'Completed today' : 'Pending',
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
      appBar: AppBar(title: const Text('Course')),
      body: ApiFutureBuilder(
        future: future,
        builder: (context, payload) {
          final assignment = _asMap(payload['course_assignment']);
          final course = _asMap(assignment['course']);
          final contentItems = _asList(course['content_items']);
          final hasExam = _readBool(course, 'has_exam');
          return _PageBody(
            children: [
              _HeroCard(
                title: _readString(course, 'title'),
                subtitle: _readString(assignment, 'status_label'),
                value: '${_readInt(course, 'estimated_minutes')} min',
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Description',
                child: Text(_readString(course, 'description')),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Content',
                child: contentItems.isEmpty
                    ? const Text('No mobile content items.')
                    : Column(
                        children: [
                          for (final item in contentItems)
                            _SimpleListTile(
                              title: _readString(item, 'title'),
                              subtitle: _contentSubtitle(item),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Actions',
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: hasExam || submitting ? null : _completeCourse,
                        child: Text(
                          hasExam ? 'Exam Required' : submitting ? 'Completing...' : 'Mark Complete',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
      appBar: AppBar(title: const Text('Checklist')),
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
        return _PageBody(
          children: [
            _HeroCard(
              title: 'Business Owner',
              subtitle: user.businessName,
              value: user.displayName,
            ),
            const SizedBox(height: 16),
            _MetricRow(
              metrics: [
                _MetricData('Employees', '${dashboard['employee_total'] ?? 0}'),
                _MetricData('Courses', '${dashboard['course_total'] ?? 0}'),
                _MetricData('Checklists', '${dashboard['checklist_total'] ?? 0}'),
              ],
            ),
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
              title: const Text('Create Employee'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
                    TextField(controller: fullNameController, decoration: const InputDecoration(labelText: 'Full name')),
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                    TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password')),
                    TextField(controller: jobTitleController, decoration: const InputDecoration(labelText: 'Job title')),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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
                label: const Text('Add'),
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
              title: const Text('Create Course'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                    TextField(controller: minutesController, decoration: const InputDecoration(labelText: 'Minutes')),
                    TextField(controller: contentTitleController, decoration: const InputDecoration(labelText: 'First content title')),
                    TextField(controller: contentBodyController, decoration: const InputDecoration(labelText: 'First content body')),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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
              title: const Text('Assign Course'),
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
                TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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
                label: const Text('Add'),
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonal(
                          onPressed: () => _showAssignDialog(_readInt(item, 'id'), employees),
                          child: const Text('Assign to Employees'),
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
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/business-owner/checklists/');
  }

  void _reload() {
    setState(() {
      future = widget.api.get('/business-owner/checklists/');
    });
  }

  Future<void> _showCreateChecklistDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final itemsController = TextEditingController();
    String frequency = 'DAILY';
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
              title: const Text('Create Checklist'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: frequency,
                      decoration: const InputDecoration(labelText: 'Frequency'),
                      items: const [
                        DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                        DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                        DropdownMenuItem(value: 'ON_DEMAND', child: Text('On demand')),
                      ],
                      onChanged: (value) {
                        setInnerState(() {
                          frequency = value ?? 'DAILY';
                        });
                      },
                    ),
                    TextField(
                      controller: itemsController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Items, one per line'),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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
              trailing: FilledButton.icon(
                onPressed: _showCreateChecklistDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF184C49)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'SkillBite',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
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
                color: const Color(0xFFE4F1EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.show_chart_rounded, size: 22),
            ),
            const SizedBox(height: 18),
            Text(
              data.value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF122421),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5C6B67),
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF122421),
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
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF122421),
            ),
          ),
        ),
        if (trailing != null) trailing!,
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
        color: const Color(0xFFE8F3EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1D4B43),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SimpleListTile extends StatelessWidget {
  const _SimpleListTile({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEDE8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF61706C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.05)],
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
      label: Text(label),
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
              message,
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          SizedBox(height: 14),
          Text('Loading workspace...'),
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
                    'Could not load this screen',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
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

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
