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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
      ),
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

  Future<void> _submit() async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      final user = await widget.api.login(
        usernameController.text.trim(),
        passwordController.text,
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('SkillBite Mobile', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Employee and business-owner access through the new mobile API.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: loading ? null : _submit,
                    child: Text(loading ? 'Signing in...' : 'Sign in'),
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
        title: Text(widget.user.displayName),
        actions: [
          if (widget.user.businessName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: Text(widget.user.businessName)),
            ),
          IconButton(
            onPressed: () async => widget.onLogout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: destinations,
        onDestinationSelected: (value) => setState(() => index = value),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')),
            ),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
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
    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          Expanded(child: _MetricCard(data: metrics[i])),
          if (i < metrics.length - 1) const SizedBox(width: 12),
        ],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(data.value, style: Theme.of(context).textTheme.headlineSmall),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
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
        Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
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
    return Chip(label: Text(label));
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
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
