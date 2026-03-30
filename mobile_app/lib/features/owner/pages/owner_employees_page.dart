// ignore_for_file: use_build_context_synchronously

part of '../../../main.dart';

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
                  _HeaderRow(
                    title: 'Employees',
                    titleColor: _brandTealDark,
                    titleFontSize: 26,
                    trailing: _HeaderActionButton(
                      label: 'Add',
                      icon: Icons.add,
                      onPressed: _showCreateEmployeeDialog,
                    ),
                  ),
                  const SizedBox(height: 18),
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
