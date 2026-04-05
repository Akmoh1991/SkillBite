// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';
import 'package:skillbite_mobile/features/employee/courses/course_flow_support.dart';
import 'package:skillbite_mobile/features/owner/pages/owner_course_detail_screen.dart';

String _tr(BuildContext context, String english) => courseTr(context, english);
Map<String, dynamic> _asMap(Object? value) => asMap(value);
List<dynamic> _asList(Object? value) => asList(value);
String _readString(dynamic source, String key) => readString(source, key);
int _readInt(dynamic source, String key) => readInt(source, key);
bool _readBool(dynamic source, String key) => readBool(source, key);
void _showSnack(BuildContext context, String message) =>
    showSnack(context, message);

const _line = courseLine;

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

  Future<void> _openCourse(Map<String, dynamic> course) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerCourseDetailScreen(
          api: widget.api,
          courseId: _readInt(course, 'id'),
          initialCourse: _asMap(course),
        ),
      ),
    );
    if (mounted) {
      _reload();
    }
  }

  Future<void> _showCreateCourseDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final minutesController = TextEditingController(text: '15');
    final contentTitleController = TextEditingController();
    final contentBodyController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      requestFocus: false,
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
              child: Padding(
                padding: EdgeInsets.fromLTRB(22, 24, 22, 22),
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
                          labelText: _tr(context, 'Description'),
                        ),
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
                          labelText: _tr(context, 'First content title'),
                        ),
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
    await Future<void>.delayed(const Duration(milliseconds: 250));
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
      requestFocus: false,
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
              child: Padding(
                padding: EdgeInsets.fromLTRB(22, 24, 22, 22),
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

  Widget _buildCourseActionRow(
    BuildContext context,
    Map<String, dynamic> item,
    List<dynamic> employees,
  ) {
    return const SizedBox.shrink();
  }

  Widget _buildCourseListItem(
    BuildContext context,
    Map<String, dynamic> item,
    List<dynamic> employees,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CourseCompactListCard(
          imageUrl: widget.api.resolveUrl(_readString(item, 'card_image_url')),
          title: _readString(item, 'title'),
          description: _readString(item, 'description'),
          metadata: const [],
          onTap: () => _openCourse(item),
        ),
        _buildCourseActionRow(context, item, employees),
      ],
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
        if (_readBool(item, 'is_owned_by_business')) _asMap(item),
    ];
    final sharedCourses = [
      for (final item in courses)
        if (!_readBool(item, 'is_owned_by_business')) _asMap(item),
    ];
    final featuredCompanyCourse =
        companyCourses.isEmpty ? null : _asMap(companyCourses.first);
    final moreCompanyCourses = companyCourses.length > 1
        ? companyCourses.skip(1).toList(growable: false)
        : const <dynamic>[];

    return CoursePageSliverBody(
      slivers: [
        CoursePageSliverSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CourseHeaderRow(
                title: 'الدورات',
                titleColor: courseBrandTealDark,
                titleFontSize: 26,
                crossAxisAlignment: CrossAxisAlignment.start,
                trailing: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _showCreateCourseDialog,
                  child: const Text('إضافة'),
                ),
              ),
              if (featuredCompanyCourse != null) ...[
                const SizedBox(height: 20),
                CoursePromoCard(
                  eyebrow: _readString(featuredCompanyCourse, 'card_label')
                          .trim()
                          .isNotEmpty
                      ? _readString(featuredCompanyCourse, 'card_label')
                      : 'مملوك',
                  title: _readString(featuredCompanyCourse, 'title'),
                  meta:
                      '${_readInt(featuredCompanyCourse, 'estimated_minutes')} دقيقة',
                  supporting: _readString(featuredCompanyCourse, 'description'),
                  imageUrl: widget.api.resolveUrl(
                    _readString(featuredCompanyCourse, 'card_image_url'),
                  ),
                  onTap: () => _openCourse(featuredCompanyCourse),
                ),
                _buildCourseActionRow(
                  context,
                  featuredCompanyCourse,
                  employees,
                ),
              ],
              if (moreCompanyCourses.isNotEmpty) ...[
                const SizedBox(height: 20),
                CourseHeaderRow(
                  title: 'دورات إضافية',
                  titleColor: courseBrandTealDark,
                ),
              ],
            ],
          ),
        ),
        if (isLoading)
          const CoursePageSliverSection(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
            child: CourseSectionCard(
              title: 'الدورات',
              child: CourseLoadingState(),
            ),
          )
        else if (courses.isEmpty)
          const CoursePageSliverSection(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
            child: CourseSectionCard(
              title: 'الدورات',
              child: Text('لا توجد دورات متاحة حالياً.'),
            ),
          )
        else ...[
          if (moreCompanyCourses.isNotEmpty)
            CoursePageSliverList(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              itemCount: moreCompanyCourses.length,
              itemBuilder: (context, index) {
                final item = _asMap(moreCompanyCourses[index]);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCourseListItem(context, item, employees),
                );
              },
            ),
          if (sharedCourses.isNotEmpty)
            CoursePageSliverSection(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: CourseHeaderRow(
                title: 'المكتبة المشتركة',
                titleColor: courseBrandTealDark,
              ),
            ),
          if (sharedCourses.isNotEmpty)
            CoursePageSliverList(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              itemCount: sharedCourses.length,
              itemBuilder: (context, index) {
                final item = _asMap(sharedCourses[index]);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCourseListItem(context, item, employees),
                );
              },
            ),
        ],
      ],
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
          return CourseErrorState(
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
