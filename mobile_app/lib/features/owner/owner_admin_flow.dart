// ignore_for_file: use_build_context_synchronously

part of '../../main.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({
    super.key,
    required this.api,
    required this.user,
  });

  final MobileApiClient api;
  final SessionUser user;

  Future<void> _openCoursesPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerCoursesExplorerScreen(api: api),
      ),
    );
  }

  Future<void> _openEmployeesPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerEmployeesPage(api: api),
      ),
    );
  }

  Future<void> _openCourse(
    BuildContext context,
    Map<String, dynamic> course,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerCourseDetailScreen(
          api: api,
          courseId: _readInt(course, 'id'),
          initialCourse: course,
        ),
      ),
    );
  }

  Widget _buildNativeView(
    BuildContext context,
    Map<String, dynamic> dashboard,
    List<dynamic> employees,
    List<dynamic> courses,
  ) {
    return _PageBody(
      children: [
        _DashboardHeroCard(
          title: _tr(context, 'Workspace overview'),
          subtitle: user.businessName,
          value:
              '${dashboard['employee_total'] ?? 0} ${_tr(context, 'Employees')}',
          icon: Icons.apartment_rounded,
        ),
        const SizedBox(height: 18),
        _DashboardMetricRow(
          metrics: [
            _DashboardMetricData(
              'Employees',
              '${dashboard['employee_total'] ?? 0}',
              icon: Icons.group_outlined,
            ),
            _DashboardMetricData(
              'Courses',
              '${dashboard['course_total'] ?? 0}',
              icon: Icons.menu_book_outlined,
            ),
            _DashboardMetricData(
              'Checklists',
              '${dashboard['checklist_total'] ?? 0}',
              icon: Icons.checklist_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _HeaderRow(
          title: 'Your people',
          trailing: _sectionLink(
            'View all',
            onTap: () => _openEmployeesPage(context),
          ),
        ),
        const SizedBox(height: 14),
        if (employees.isEmpty)
          const _SectionCard(
              title: 'Employees', child: Text('No employees yet.'))
        else
          for (final item in employees.take(3)) ...[
            _NativeLessonTile(
              title: _readString(item, 'display_name'),
              subtitle: _readString(item, 'job_title').isEmpty
                  ? _readString(item, 'username')
                  : _readString(item, 'job_title'),
              accent: const Color(0xFFEFF5FF),
              trailingIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
          ],
        const SizedBox(height: 6),
        _HeaderRow(
          title: 'Courses',
          trailing: _sectionLink(
            'View all',
            onTap: () => _openCoursesPage(context),
          ),
        ),
        const SizedBox(height: 14),
        if (courses.isEmpty)
          const _SectionCard(
              title: 'Courses', child: Text('No assignable courses.'))
        else
          for (final item in courses.take(3)) ...[
            _NativeCoursePromoCard(
              eyebrow: _readString(item, 'business_name').isEmpty
                  ? 'Shared'
                  : 'Workspace',
              title: _readString(item, 'title'),
              meta: _readString(item, 'business_name').isEmpty
                  ? user.businessName
                  : _readString(item, 'business_name'),
              supporting: _readString(item, 'description').isEmpty
                  ? _tr(context, 'Suggested course pushes')
                  : _readString(item, 'description'),
              imageUrl: api.resolveUrl(_readString(item, 'card_image_url')),
              icon: Icons.auto_awesome_motion_rounded,
              onTap: () => _openCourse(context, _asMap(item)),
            ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: api.get('/business-owner/dashboard/'),
      builder: (context, payload) {
        final dashboard = _asMap(payload['dashboard']);
        final employees = _asList(dashboard['employees']);
        final courses = _asList(dashboard['assignable_courses']);
        return _buildNativeView(context, dashboard, employees, courses);
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
          builder: (context) => Dialog(
            backgroundColor: const Color(0xFFFFF6F2),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE6DE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.person_off_rounded,
                        color: Color(0xFFC54C2B)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tr(context, 'Deactivate Employee'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Disable ${_readString(employee, 'display_name')}?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF61706C),
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(_tr(context, 'Cancel')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC54C2B),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(_tr(context, 'Deactivate')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await widget.api.post(
          '/business-owner/employees/${_readInt(employee, 'id')}/deactivate/',
          {});
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

            return Dialog(
              backgroundColor: const Color(0xFFF3FBF8),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  MediaQuery.of(context).viewInsets.bottom + 22,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context, 'Create Employee'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _tr(
                          context,
                          'Set up a new teammate with the right role details so they can start learning immediately.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Username')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: fullNameController,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Full name')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: emailController,
                        decoration:
                            InputDecoration(labelText: _tr(context, 'Email')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Password')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: jobTitleController,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Job title')),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFC54C2B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text(_tr(context, 'Cancel')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving ? 'Saving...' : 'Create'),
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
    usernameController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    jobTitleController.dispose();
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
        final activeEmployees =
            employees.where((item) => _readBool(item, 'is_active')).length;
        final titledEmployees = employees
            .where((item) => _readString(item, 'job_title').trim().isNotEmpty)
            .length;
        final untitledEmployees = employees.length - titledEmployees;
        return _PageSliverBody(
          slivers: [
            _PageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeroCard(
                    title: 'Team directory',
                    subtitle: 'Employees',
                    value:
                        '${employees.length} people across your business workspace',
                    icon: Icons.groups_rounded,
                  ),
                  const SizedBox(height: 16),
                  _DashboardMetricRow(
                    metrics: [
                      _DashboardMetricData(
                        'Active',
                        '$activeEmployees',
                        icon: Icons.verified_user_rounded,
                      ),
                      _DashboardMetricData(
                        'With role',
                        '$titledEmployees',
                        icon: Icons.badge_rounded,
                      ),
                      _DashboardMetricData(
                        'Needs title',
                        '$untitledEmployees',
                        icon: Icons.assignment_ind_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _HeaderRow(
                    title: 'Employees',
                    trailing: _HeaderActionButton(
                      label: 'Add',
                      icon: Icons.add,
                      onPressed: _showCreateEmployeeDialog,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (employees.isEmpty)
              _PageSliverSection(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: _ManagementRecordCard(
                  title: 'Build your team',
                  description:
                      'Create the first employee account to unlock training assignments, checklists, and reporting.',
                  icon: Icons.person_add_alt_1_rounded,
                  secondaryActionLabel: _tr(context, 'Create'),
                  onSecondaryAction: _showCreateEmployeeDialog,
                ),
              )
            else
              _PageSliverList(
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final item = employees[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ManagementRecordCard(
                      title: _readString(item, 'display_name'),
                      description: _readString(item, 'job_title').trim().isEmpty
                          ? 'Role title not assigned yet.'
                          : _readString(item, 'job_title'),
                      icon: _readBool(item, 'is_active')
                          ? Icons.person_rounded
                          : Icons.person_off_rounded,
                      metadata: [
                        _readBool(item, 'is_active') ? 'Active' : 'Paused',
                        _readString(item, 'username'),
                      ],
                      detail: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_readString(item, 'email').trim().isNotEmpty)
                            _RecordDetailLine(
                              icon: Icons.alternate_email_rounded,
                              label: _readString(item, 'email'),
                            ),
                          if (_readString(item, 'job_title')
                              .trim()
                              .isNotEmpty) ...[
                            if (_readString(item, 'email').trim().isNotEmpty)
                              const SizedBox(height: 10),
                            _RecordDetailLine(
                              icon: Icons.work_outline_rounded,
                              label: _readString(item, 'job_title'),
                            ),
                          ],
                        ],
                      ),
                      primaryActionLabel: _readBool(item, 'is_active')
                          ? _tr(context, 'Deactivate')
                          : null,
                      onPrimaryAction: _readBool(item, 'is_active')
                          ? () => _deactivateEmployee(_asMap(item))
                          : null,
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

            return Dialog(
              backgroundColor: const Color(0xFFF3FBF8),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  MediaQuery.of(context).viewInsets.bottom + 22,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context, 'Create Job Title'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _tr(
                          context,
                          'Create a reusable role title to keep employee setup and checklist assignment rules consistent.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Title name')),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFC54C2B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text(_tr(context, 'Cancel')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving ? 'Saving...' : 'Create'),
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
    nameController.dispose();
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
        final assignedPeople = jobTitles.fold<int>(
          0,
          (total, item) => total + _readInt(item, 'employee_count'),
        );
        final staffedTitles = jobTitles
            .where((item) => _readInt(item, 'employee_count') > 0)
            .length;
        final emptyTitles = jobTitles.length - staffedTitles;
        return _PageSliverBody(
          slivers: [
            _PageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeroCard(
                    title: 'Roles and titles',
                    subtitle: 'Job titles',
                    value:
                        '$assignedPeople active people mapped across ${jobTitles.length} titles',
                    icon: Icons.badge_rounded,
                  ),
                  const SizedBox(height: 16),
                  _DashboardMetricRow(
                    metrics: [
                      _DashboardMetricData(
                        'Titles',
                        '${jobTitles.length}',
                        icon: Icons.category_rounded,
                      ),
                      _DashboardMetricData(
                        'Staffed',
                        '$staffedTitles',
                        icon: Icons.people_alt_rounded,
                      ),
                      _DashboardMetricData(
                        'Unfilled',
                        '$emptyTitles',
                        icon: Icons.hourglass_empty_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _HeaderRow(
                    title: 'Job Titles',
                    trailing: _HeaderActionButton(
                      label: 'Add',
                      icon: Icons.add,
                      onPressed: _showCreateJobTitleDialog,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (jobTitles.isEmpty)
              _PageSliverSection(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: _ManagementRecordCard(
                  title: 'Create your first role',
                  description:
                      'Job titles make onboarding, checklist automation, and employee organization much cleaner.',
                  icon: Icons.badge_rounded,
                  secondaryActionLabel: _tr(context, 'Create'),
                  onSecondaryAction: _showCreateJobTitleDialog,
                ),
              )
            else
              _PageSliverList(
                itemCount: jobTitles.length,
                itemBuilder: (context, index) {
                  final item = jobTitles[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ManagementRecordCard(
                      title: _readString(item, 'name'),
                      description: _readInt(item, 'employee_count') == 0
                          ? 'No active employees are assigned to this title yet.'
                          : 'Use this title to keep assignment rules and employee setup aligned.',
                      icon: Icons.badge_outlined,
                      metadata: [
                        '${_readInt(item, 'employee_count')} active employees'
                      ],
                      detail: const _RecordDetailLine(
                        icon: Icons.rule_folder_outlined,
                        label:
                            'Keep course assignment and onboarding checklist rules anchored to clear job titles.',
                      ),
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

class OwnerCoursesPage extends StatefulWidget {
  const OwnerCoursesPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<OwnerCoursesPage> createState() => _OwnerCoursesPageState();
}

class OwnerCoursesExplorerScreen extends StatelessWidget {
  const OwnerCoursesExplorerScreen({
    super.key,
    required this.api,
  });

  final MobileApiClient api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tr(context, 'Courses'))),
      body: OwnerCoursesPage(api: api),
    );
  }
}

class _OwnerCoursesPageState extends State<OwnerCoursesPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      future = widget.api.get('/business-owner/courses/');
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
                  'estimated_minutes':
                      int.tryParse(minutesController.text.trim()) ?? 15,
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

            return Dialog(
              backgroundColor: const Color(0xFFF3FBF8),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  MediaQuery.of(context).viewInsets.bottom + 22,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context, 'Create Course'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _tr(
                          context,
                          'Launch a new course with a clear first lesson so employees can start immediately.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: titleController,
                        decoration:
                            InputDecoration(labelText: _tr(context, 'Title')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Description')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: minutesController,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: _tr(context, 'Minutes')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: contentTitleController,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'First content title')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: contentBodyController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: _tr(context, 'First content body'),
                          alignLabelWithHint: true,
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFC54C2B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text(_tr(context, 'Cancel')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving ? 'Saving...' : 'Create'),
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
    titleController.dispose();
    descriptionController.dispose();
    minutesController.dispose();
    contentTitleController.dispose();
    contentBodyController.dispose();
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
                await widget.api
                    .post('/business-owner/courses/$courseId/assign/', {
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

            return Dialog(
              backgroundColor: const Color(0xFFF3FBF8),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                child: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr(context, 'Assign Course'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _tr(
                            context,
                            'Choose who should receive this course now. You can select multiple employees at once.',
                          ),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF61706C),
                                    height: 1.45,
                                  ),
                        ),
                        const SizedBox(height: 18),
                        for (final item in employees) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: _line),
                            ),
                            child: CheckboxListTile(
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              title: Text(_readString(item, 'display_name')),
                              subtitle: Text(
                                _readString(item, 'job_title').trim().isEmpty
                                    ? 'No job title assigned'
                                    : _readString(item, 'job_title'),
                              ),
                            ),
                          ),
                        ],
                        if (errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              errorText!,
                              style: const TextStyle(
                                color: Color(0xFFC54C2B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: saving
                                ? null
                                : () => Navigator.of(context).pop(false),
                            child: Text(_tr(context, 'Cancel')),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: saving ? null : submit,
                            child: Text(saving ? 'Saving...' : 'Assign'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

  Widget _buildCourseCard(
    BuildContext context,
    Map<String, dynamic> item,
    List<dynamic> employees,
  ) {
    final title = _readString(item, 'title');
    final description = _readString(item, 'description').trim().isEmpty
        ? 'Practical course content with clear guidance and structured steps.'
        : _readString(item, 'description');
    final imageUrl = widget.api.resolveUrl(_readString(item, 'card_image_url'));
    final footnote = _readString(item, 'business_name').trim().isEmpty
        ? (_readBool(item, 'is_owned_by_business')
            ? 'Company course library'
            : 'Central course library')
        : _readString(item, 'business_name');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OwnerCourseDetailScreen(
                api: widget.api,
                courseId: _readInt(item, 'id'),
                initialCourse: _asMap(item),
              ),
            ),
          );
          _reload();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _line),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 118,
                    child: _OptimizedCourseCardImage(
                      imageUrl: imageUrl,
                      title: title,
                      aspectRatio: 1.18,
                      borderRadius: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                footnote,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: _muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF7F4),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _readBool(item, 'is_owned_by_business')
                                    ? _tr(context, 'Owned')
                                    : _tr(context, 'Shared'),
                                style: const TextStyle(
                                  color: _brandTealDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF7B879B),
                                    height: 1.45,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatusChip(
                              label:
                                  '${_readInt(item, 'estimated_minutes')} ${_tr(context, 'min')}',
                            ),
                            _StatusChip(
                              label:
                                  '${_readInt(item, 'content_item_total')} ${_tr(context, 'Items')}',
                            ),
                            if (_readString(item, 'card_label')
                                .trim()
                                .isNotEmpty)
                              _StatusChip(
                                  label: _readString(item, 'card_label')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OwnerCourseDetailScreen(
                            api: widget.api,
                            courseId: _readInt(item, 'id'),
                            initialCourse: _asMap(item),
                          ),
                        ),
                      );
                      _reload();
                    },
                    child: Text(_tr(context, 'Manage Content')),
                  ),
                  if (employees.isNotEmpty)
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          _showAssignDialog(_readInt(item, 'id'), employees),
                      child: Text(_tr(context, 'Assign')),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    Map<String, dynamic> summary = const {},
    List<dynamic> courses = const [],
    List<dynamic> ownedCourses = const [],
    List<dynamic> employees = const [],
    bool isLoading = false,
  }) {
    final visibleCourseTotal =
        summary['visible_course_total'] ?? courses.length;
    final ownedCourseTotal =
        summary['owned_course_total'] ?? ownedCourses.length;
    final companyCourses = [
      for (final item in courses)
        if (_readBool(item, 'is_owned_by_business')) item,
    ];
    final sharedCourses = [
      for (final item in courses)
        if (!_readBool(item, 'is_owned_by_business')) item,
    ];
    final overviewWidgets = <Widget>[
      _DashboardHeroCard(
        title: _tr(context, 'Courses'),
        subtitle: ownedCourseTotal == 0
            ? 'Build your first company course'
            : 'Manage your learning catalog',
        value: '$ownedCourseTotal owned - $visibleCourseTotal visible',
        icon: Icons.library_books_rounded,
      ),
      const SizedBox(height: 16),
      _DashboardMetricRow(
        metrics: [
          _DashboardMetricData(
            'Courses',
            '$visibleCourseTotal',
            icon: Icons.menu_book_rounded,
          ),
          _DashboardMetricData(
            'Employees',
            '${employees.length}',
            icon: Icons.groups_rounded,
          ),
          _DashboardMetricData(
            'Owned',
            '$ownedCourseTotal',
            icon: Icons.edit_note_rounded,
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: Text(
              _tr(context, 'Your courses'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _ink,
                    fontSize: 20,
                  ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _showCreateCourseDialog,
            child: Text(_tr(context, 'Add')),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ];

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
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: overviewWidgets,
                    ),
                  ),
                ),
              ),
            ),
            if (isLoading)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: _LoadingState(),
                    ),
                  ),
                ),
              )
            else if (courses.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverToBoxAdapter(
                  child: _ManagementRecordCard(
                    title: 'Create your first course',
                    description:
                        'Build a company-owned course with tailored content and then assign it to the right people.',
                    icon: Icons.auto_stories_rounded,
                    secondaryActionLabel: _tr(context, 'Create'),
                    onSecondaryAction: _showCreateCourseDialog,
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = _asMap(companyCourses[index]);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: RepaintBoundary(
                        child: _buildCourseCard(context, item, employees),
                      ),
                    );
                  }, childCount: companyCourses.length),
                ),
              ),
              if (sharedCourses.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Text(
                          _tr(context, 'Shared library'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: _ink,
                                fontSize: 20,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (sharedCourses.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _asMap(sharedCourses[index]);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RepaintBoundary(
                          child: _buildCourseCard(context, item, employees),
                        ),
                      );
                    }, childCount: sharedCourses.length),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildBody(context, isLoading: true);
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
          );
        }
        final payload = snapshot.data ?? const <String, dynamic>{};
        return _buildBody(
          context,
          summary: _asMap(payload['summary']),
          courses: _asList(payload['courses']),
          ownedCourses: _asList(payload['owned_courses']),
          employees: _asList(payload['employees']),
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
    this.initialCourse,
  });

  final MobileApiClient api;
  final int courseId;
  final Map<String, dynamic>? initialCourse;

  @override
  State<OwnerCourseDetailScreen> createState() =>
      _OwnerCourseDetailScreenState();
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

  Widget _buildContentItemCard(
      BuildContext context, Map<String, dynamic> rawItem) {
    final description = _readString(rawItem, 'body').isNotEmpty
        ? _readString(rawItem, 'body')
        : _readString(rawItem, 'material_url').isNotEmpty
            ? _readString(rawItem, 'material_url')
            : 'No body or link provided yet.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_contentIcon(rawItem), color: _brandTeal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _readString(rawItem, 'title'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(label: _readString(rawItem, 'content_type')),
                _StatusChip(label: 'Order ${_readInt(rawItem, 'order')}'),
                if (_readString(rawItem, 'material_url').isNotEmpty)
                  const _StatusChip(label: 'External link'),
              ],
            ),
            const SizedBox(height: 14),
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
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> course) {
    final items = _asList(course['content_items']);
    final description = _readString(course, 'description');
    final estimatedMinutes = _readInt(course, 'estimated_minutes');
    final hasExam = _readBool(course, 'has_exam');
    return _PageBody(
      children: [
        _DashboardHeroCard(
          title: _tr(context, 'Course Content'),
          subtitle: _readString(course, 'title').isEmpty
              ? _tr(context, 'Loading course...')
              : _readString(course, 'title'),
          value:
              '${items.length} ${_tr(context, 'Items')} - $estimatedMinutes ${_tr(context, 'min')}',
          icon: Icons.auto_stories_rounded,
        ),
        const SizedBox(height: 16),
        _DashboardMetricRow(
          metrics: [
            _DashboardMetricData(
              'Items',
              '${items.length}',
              icon: Icons.layers_rounded,
            ),
            _DashboardMetricData(
              'Minutes',
              '$estimatedMinutes',
              icon: Icons.schedule_rounded,
            ),
            _DashboardMetricData(
              hasExam ? 'Has exam' : 'No exam',
              hasExam ? 'Yes' : 'No',
              icon: hasExam
                  ? Icons.quiz_rounded
                  : Icons.check_circle_outline_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr(context, 'Course'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  description.isNotEmpty
                      ? description
                      : 'Add a concise description so learners understand the outcome before they open the content.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                        label: '$estimatedMinutes ${_tr(context, 'min')}'),
                    _StatusChip(
                        label: '${items.length} ${_tr(context, 'Items')}'),
                    _StatusChip(
                      label: hasExam
                          ? _tr(context, 'Has exam')
                          : _tr(context, 'No exam'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                _tr(context, 'Content library'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _ink,
                      fontSize: 20,
                    ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _showContentDialog(),
              child: Text(_tr(context, 'Add')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('No content items yet.'),
            ),
          )
        else
          for (final rawItem in items) ...[
            _buildContentItemCard(context, _asMap(rawItem)),
            const SizedBox(height: 16),
          ],
      ],
    );
  }

  Future<void> _showContentDialog({Map<String, dynamic>? item}) async {
    final isEditing = item != null;
    final titleController = TextEditingController(
        text: isEditing ? _readString(item, 'title') : '');
    final bodyController =
        TextEditingController(text: isEditing ? _readString(item, 'body') : '');
    final urlController = TextEditingController(
        text: isEditing ? _readString(item, 'material_url') : '');
    final orderController = TextEditingController(
        text: isEditing ? '${_readInt(item, 'order')}' : '1');
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
                  await widget.api.post(
                      '/business-owner/course-content/${_readInt(item, 'id')}/update/',
                      payload);
                } else {
                  await widget.api.post(
                      '/business-owner/courses/${widget.courseId}/content/create/',
                      payload);
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

            return Dialog(
              backgroundColor: const Color(0xFFF3FBF8),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  MediaQuery.of(context).viewInsets.bottom + 22,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context,
                            isEditing ? 'Edit Content' : 'Add Content'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _tr(
                          context,
                          'Shape the lesson flow with clear titles, useful context, and the right content type.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      DropdownButtonFormField<String>(
                        initialValue: contentType,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Content type')),
                        items: [
                          DropdownMenuItem(
                              value: 'TEXT', child: Text(_tr(context, 'Text'))),
                          DropdownMenuItem(
                              value: 'MATERIAL',
                              child: Text(_tr(context, 'Link'))),
                          DropdownMenuItem(
                              value: 'LESSON',
                              child: Text(_tr(context, 'Lesson'))),
                        ],
                        onChanged: (value) {
                          setInnerState(() {
                            contentType = value ?? 'TEXT';
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleController,
                        decoration:
                            InputDecoration(labelText: _tr(context, 'Title')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: bodyController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: _tr(context, 'Body'),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Material URL')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: orderController,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: _tr(context, 'Order')),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFC54C2B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text(_tr(context, 'Cancel')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving
                              ? 'Saving...'
                              : isEditing
                                  ? 'Update'
                                  : 'Create'),
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
    titleController.dispose();
    bodyController.dispose();
    urlController.dispose();
    orderController.dispose();
    if (changed == true) {
      _showSnack(context, isEditing ? 'Content updated.' : 'Content created.');
      _reload();
    }
  }

  Future<void> _deleteContent(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: const Color(0xFFFFF6F2),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE6DE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFC54C2B)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tr(context, 'Delete Content'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Delete "${_readString(item, 'title')}"?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF61706C),
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(_tr(context, 'Cancel')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC54C2B),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(_tr(context, 'Delete')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await widget.api.post(
          '/business-owner/course-content/${_readInt(item, 'id')}/delete/', {});
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildBody(context, widget.initialCourse ?? const {});
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message:
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
            );
          }
          final payload = snapshot.data ?? const <String, dynamic>{};
          return _buildBody(context, _asMap(payload['course']));
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
        final trackedEmployeeTotal = _readInt(report, 'tracked_employee_total');
        final totalAssigned = _readInt(report, 'total_assigned');
        final totalCompleted = _readInt(report, 'total_completed');
        final totalInProgress = _readInt(report, 'total_in_progress');
        final completionRate = _readInt(report, 'overall_completion_rate');
        final completionProgress =
            totalAssigned == 0 ? 0.0 : totalCompleted / totalAssigned;
        return _PageBody(
          children: [
            _DashboardHeroCard(
              title: 'Learning performance',
              subtitle: 'Reports',
              value: totalAssigned == 0
                  ? 'No course assignments have been tracked yet.'
                  : '$completionRate% overall completion across $trackedEmployeeTotal tracked employees',
              icon: Icons.insights_rounded,
            ),
            const SizedBox(height: 16),
            _DashboardMetricRow(
              metrics: [
                _DashboardMetricData(
                  'Tracked',
                  '$trackedEmployeeTotal',
                  icon: Icons.people_alt_rounded,
                ),
                _DashboardMetricData(
                  'Assigned',
                  '$totalAssigned',
                  icon: Icons.assignment_turned_in_rounded,
                ),
                _DashboardMetricData(
                  'Completed',
                  '$totalCompleted',
                  icon: Icons.task_alt_rounded,
                ),
                _DashboardMetricData(
                  'In progress',
                  '$totalInProgress',
                  icon: Icons.timelapse_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(22),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _tr(context, 'Completion overview'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      _StatusChip(label: '$completionRate% complete'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    totalAssigned == 0
                        ? _tr(
                            context,
                            'Once courses are assigned, you will see completion momentum and progress trends here.',
                          )
                        : _tr(
                            context,
                            'Track how many assignments are completed, still active, and where the next follow-up is needed.',
                          ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF61706C),
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: completionProgress.clamp(0, 1),
                      minHeight: 12,
                      backgroundColor: const Color(0xFFE7ECEF),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_brandTeal),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatusChip(label: '$totalCompleted completed'),
                      _StatusChip(
                          label: '${totalAssigned - totalCompleted} remaining'),
                      _StatusChip(label: '$totalInProgress in progress'),
                    ],
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

            return Dialog(
              backgroundColor: const Color(0xFFF3FBF8),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  MediaQuery.of(context).viewInsets.bottom + 22,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context, 'Create Checklist'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _tr(
                          context,
                          'Design a repeatable routine with clear steps so teams know exactly what good looks like.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: titleController,
                        decoration:
                            InputDecoration(labelText: _tr(context, 'Title')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Description')),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: frequency,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Frequency')),
                        items: [
                          DropdownMenuItem(
                              value: 'DAILY',
                              child: Text(_tr(context, 'Daily'))),
                          DropdownMenuItem(
                              value: 'WEEKLY',
                              child: Text(_tr(context, 'Weekly'))),
                          DropdownMenuItem(
                              value: 'ON_DEMAND',
                              child: Text(_tr(context, 'On demand'))),
                        ],
                        onChanged: (value) {
                          setInnerState(() {
                            frequency = value ?? 'DAILY';
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int?>(
                        initialValue: jobTitleId,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Assign to job title')),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child:
                                Text(_tr(context, 'No automatic assignment')),
                          ),
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
                      const SizedBox(height: 14),
                      TextField(
                        controller: itemsController,
                        minLines: 4,
                        maxLines: 7,
                        decoration: InputDecoration(
                          labelText: _tr(context, 'Items, one per line'),
                          alignLabelWithHint: true,
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFC54C2B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text(_tr(context, 'Cancel')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving ? 'Saving...' : 'Create'),
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
    titleController.dispose();
    descriptionController.dispose();
    itemsController.dispose();
    if (created == true) {
      _showSnack(context, 'Checklist created.');
      _reload();
    }
  }

  Future<void> _showCreateRuleDialog(
      List<dynamic> checklists, List<dynamic> jobTitles) async {
    int? selectedChecklistId =
        checklists.isEmpty ? null : _readInt(checklists.first, 'id');
    int? selectedJobTitleId =
        jobTitles.isEmpty ? null : _readInt(jobTitles.first, 'id');
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
                await widget.api
                    .post('/business-owner/checklist-rules/create/', {
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

            return Dialog(
              backgroundColor: const Color(0xFFF3FBF8),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  MediaQuery.of(context).viewInsets.bottom + 22,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context, 'Create Checklist Rule'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _tr(
                          context,
                          'Link a role to the right checklist so onboarding and recurring routines stay automatic.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      DropdownButtonFormField<int?>(
                        initialValue: selectedJobTitleId,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Job title')),
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
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int?>(
                        initialValue: selectedChecklistId,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Checklist')),
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
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFC54C2B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text(_tr(context, 'Cancel')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving ? 'Saving...' : 'Create'),
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
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
          );
        }
        final checklists = _asList(snapshot.data![0]['checklists']);
        final rules = _asList(snapshot.data![1]['rules']);
        final jobTitles = _asList(snapshot.data![2]['job_titles']);
        final automatedTitleCount = {
          for (final item in rules) _readPath(item, ['job_title', 'name']),
        }.where((name) => name.trim().isNotEmpty).length;
        return _PageSliverBody(
          slivers: [
            _PageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeroCard(
                    title: _tr(context, 'Checklists'),
                    subtitle: checklists.isEmpty
                        ? 'Design routines your team can trust'
                        : '${checklists.length} active checklist templates',
                    value: rules.isEmpty
                        ? 'No automation rules yet.'
                        : '${rules.length} rules across $automatedTitleCount job titles',
                    icon: Icons.fact_check_rounded,
                  ),
                  const SizedBox(height: 16),
                  _DashboardMetricRow(
                    metrics: [
                      _DashboardMetricData(
                        'Checklists',
                        '${checklists.length}',
                        icon: Icons.checklist_rounded,
                      ),
                      _DashboardMetricData(
                        'Rule',
                        '${rules.length}',
                        icon: Icons.account_tree_rounded,
                      ),
                      _DashboardMetricData(
                        'Titles',
                        '$automatedTitleCount',
                        icon: Icons.badge_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _HeaderRow(
                    title: 'Checklist library',
                    trailing: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeaderActionButton(
                          label: 'Add',
                          icon: Icons.add,
                          onPressed: () =>
                              _showCreateChecklistDialog(jobTitles),
                        ),
                        _HeaderTonalButton(
                          label: 'Rule',
                          onPressed: checklists.isEmpty || jobTitles.isEmpty
                              ? null
                              : () =>
                                  _showCreateRuleDialog(checklists, jobTitles),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (checklists.isEmpty)
              const _PageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: _SectionCard(
                  title: 'Checklists',
                  child: Text('No checklists created.'),
                ),
              )
            else
              _PageSliverList(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                itemCount: checklists.length,
                itemBuilder: (context, index) {
                  final item = checklists[index];
                  final checklistItems = _asList(item['items']);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ManagementRecordCard(
                      title: _readString(item, 'title'),
                      description: _readString(item, 'description').isEmpty
                          ? 'No checklist description yet.'
                          : _readString(item, 'description'),
                      icon: Icons.checklist_rounded,
                      metadata: [
                        _readString(item, 'frequency'),
                        '${checklistItems.length} ${_tr(context, 'Items')}',
                      ],
                      detail: Column(
                        children: [
                          for (final checklistItem in checklistItems.take(3))
                            _ChecklistItemTile(
                              index: checklistItems.indexOf(checklistItem) + 1,
                              title: _readString(checklistItem, 'title'),
                              checked: false,
                            ),
                          if (checklistItems.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '+${checklistItems.length - 3} more items',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            _PageSliverSection(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  _HeaderRow(title: 'Assignment rules'),
                  SizedBox(height: 16),
                ],
              ),
            ),
            if (rules.isEmpty)
              const _PageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: _SectionCard(
                  title: 'Assignment Rules',
                  child: Text('No checklist rules yet.'),
                ),
              )
            else
              _PageSliverList(
                itemCount: rules.length,
                itemBuilder: (context, index) {
                  final item = rules[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RuleAssignmentTile(
                      jobTitle: _readPath(item, ['job_title', 'name']),
                      checklistTitle: _readPath(item, ['checklist', 'title']),
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
