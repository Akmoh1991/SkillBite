// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';
import 'package:skillbite_mobile/features/owner/pages/owner_job_titles_page.dart';

String _tr(BuildContext context, String english) => tr(context, english);
Map<String, dynamic> _asMap(Object? value) => asMap(value);
List<dynamic> _asList(Object? value) => asList(value);
String _readString(dynamic source, String key) => readString(source, key);
int _readInt(dynamic source, String key) => readInt(source, key);
bool _readBool(dynamic source, String key) => readBool(source, key);
void _showSnack(BuildContext context, String message) =>
    showSnack(context, message);

const _brandTealDark = brandTealDark;

typedef _HeaderRow = AppHeaderRow;
typedef _HeaderActionButton = AppHeaderActionButton;
typedef _ManagementRecordCard = AppManagementRecordCard;
typedef _PageSliverBody = AppPageSliverBody;
typedef _PageSliverSection = AppPageSliverSection;
typedef _PageSliverList = AppPageSliverList;

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

  Future<void> _openEmployeeDetail(Map<String, dynamic> employee) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OwnerEmployeeDetailPage(
          employee: employee,
          onDeactivate: () => _deactivateEmployee(employee),
        ),
      ),
    );
    if (changed == true && mounted) {
      _reload();
    }
  }

  Future<void> _openJobTitlesPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerJobTitlesPage(api: widget.api),
      ),
    );
  }

  Future<void> _showAddChooserDialog() async {
    final selection = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF3FBF8),
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إضافة جديدة',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'اختر ما الذي تريد إضافته أولاً.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF61706C),
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).pop('employee'),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('إضافة موظف'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    alignment: Alignment.centerRight,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).pop('job_title'),
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('إضافة مسمى وظيفي'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    alignment: Alignment.centerRight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || selection == null) {
      return;
    }

    if (selection == 'employee') {
      await _showCreateEmployeeDialog();
    } else if (selection == 'job_title') {
      await _showCreateJobTitleDialog();
    }
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
                    child: const Icon(
                      Icons.person_off_rounded,
                      color: Color(0xFFC54C2B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تعطيل الموظف',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'هل تريد تعطيل ${_readString(employee, 'display_name')}؟',
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
                      child: const Text('إلغاء'),
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
                      child: const Text('تعطيل'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    try {
      await widget.api.post(
        '/business-owner/employees/${_readInt(employee, 'id')}/deactivate/',
        {},
      );
      if (!mounted) {
        return;
      }
      _showSnack(context, 'تم تعطيل الموظف.');
      _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
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
                if (!mounted) {
                  return;
                }
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
                borderRadius: BorderRadius.circular(32),
              ),
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
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'إغلاق',
                              iconSize: 34,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 40,
                                height: 40,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Align(
                                alignment: AlignmentDirectional.topEnd,
                                child: Text(
                                  'إضافة موظف',
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'أضف موظفاً جديداً وحدد بياناته الأساسية ليبدأ مباشرة.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: jobTitleController,
                        decoration: const InputDecoration(
                          labelText: 'المسمى الوظيفي',
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
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving ? 'جارٍ الحفظ...' : 'إنشاء'),
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
      _showSnack(context, 'تم إنشاء الموظف.');
      _reload();
    }
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
                if (!mounted) {
                  return;
                }
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
                borderRadius: BorderRadius.circular(32),
              ),
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
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'إغلاق',
                              iconSize: 34,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 40,
                                height: 40,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Align(
                                alignment: AlignmentDirectional.topEnd,
                                child: Text(
                                  'إضافة مسمى وظيفي',
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'أضف مسمى وظيفياً يمكن استخدامه مع الموظفين.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المسمى الوظيفي',
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
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving ? 'جارٍ الحفظ...' : 'إنشاء'),
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
      _showSnack(context, 'تم إنشاء المسمى الوظيفي.');
      _reload();
    }
  }

  Widget _buildEmployeeListItem(Map<String, dynamic> employee) {
    final name = _readString(employee, 'display_name').trim().isEmpty
        ? _readString(employee, 'username')
        : _readString(employee, 'display_name');
    final jobTitle = _readString(employee, 'job_title').trim();
    final isActive = _readBool(employee, 'is_active');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lineColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openEmployeeDetail(employee),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isActive ? Icons.person_rounded : Icons.person_off_rounded,
                  color: brandTeal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jobTitle.isEmpty
                          ? 'لم يتم تعيين مسمى وظيفي بعد.'
                          : jobTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: mutedColor,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppStatusChip(label: isActive ? 'نشط' : 'متوقف'),
                  const SizedBox(height: 12),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF95A3B4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: future,
      builder: (context, payload) {
        final employees = _asList(payload['employees']);
        return _PageSliverBody(
          slivers: [
            _PageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderRow(
                    title: 'الموظفون',
                    titleColor: _brandTealDark,
                    titleFontSize: 26,
                    trailing: _HeaderActionButton(
                      label: 'إضافة',
                      icon: Icons.add,
                      onPressed: _showAddChooserDialog,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppSectionLink(
                      label: 'Job titles',
                      onTap: _openJobTitlesPage,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (employees.isEmpty)
              _PageSliverSection(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: _ManagementRecordCard(
                  title: 'ابدأ بإضافة فريقك',
                  description:
                      'أنشئ أول موظف أو أضف مسمى وظيفياً لتنظيم فريقك بشكل أفضل.',
                  icon: Icons.person_add_alt_1_rounded,
                  secondaryActionLabel: 'إضافة',
                  onSecondaryAction: _showAddChooserDialog,
                ),
              )
            else
              _PageSliverList(
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final item = employees[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildEmployeeListItem(_asMap(item)),
                  );
                },
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              ),
          ],
        );
      },
    );
  }
}

class OwnerEmployeeDetailPage extends StatelessWidget {
  const OwnerEmployeeDetailPage({
    super.key,
    required this.employee,
    required this.onDeactivate,
  });

  final Map<String, dynamic> employee;
  final Future<void> Function() onDeactivate;

  @override
  Widget build(BuildContext context) {
    final name = _readString(employee, 'display_name').trim().isEmpty
        ? _readString(employee, 'username')
        : _readString(employee, 'display_name');
    final username = _readString(employee, 'username').trim();
    final email = _readString(employee, 'email').trim();
    final jobTitle = _readString(employee, 'job_title').trim();
    final isActive = _readBool(employee, 'is_active');

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الموظف')),
      body: _PageSliverBody(
        slivers: [
          _PageSliverSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: lineColor),
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
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF7F4),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                isActive
                                    ? Icons.person_rounded
                                    : Icons.person_off_rounded,
                                color: brandTeal,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    jobTitle.isEmpty
                                        ? 'لم يتم تعيين مسمى وظيفي بعد.'
                                        : jobTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(color: mutedColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppStatusChip(label: isActive ? 'نشط' : 'متوقف'),
                            if (username.isNotEmpty)
                              AppStatusChip(label: username),
                          ],
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            'البريد الإلكتروني',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            email,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: inkColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      await onDeactivate();
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC54C2B),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('تعطيل'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
