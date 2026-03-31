import 'package:flutter/material.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/features/employee/courses/course_flow_support.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/employee_course_detail_screen.dart';

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
    return CourseApiFutureBuilder(
      future: future,
      builder: (context, payload) {
        final courses = courseAsList(payload['courses']);
        final featuredCourse =
            courses.isEmpty ? null : courseAsMap(courses.first);
        final moreCourses =
            courses.length > 1 ? courses.skip(1).toList() : const <dynamic>[];
        return CoursePageSliverBody(
          slivers: [
            CoursePageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CourseHeaderRow(
                    title: 'Courses',
                    titleColor: courseBrandTealDark,
                    titleFontSize: 26,
                    trailing: CourseRoundIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: _reload,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (featuredCourse != null) ...[
                    CoursePromoCard(
                      eyebrow: courseReadString(featuredCourse, 'status_label')
                              .isEmpty
                          ? 'Course'
                          : courseReadString(featuredCourse, 'status_label'),
                      title:
                          courseReadPath(featuredCourse, ['course', 'title']),
                      meta:
                          '${courseReadInt(courseAsMap(featuredCourse['course']), 'estimated_minutes')} ${courseTr(context, 'min')}',
                      supporting: courseReadPath(
                          featuredCourse, ['course', 'description']),
                      imageUrl: widget.api.resolveUrl(
                        courseReadPath(
                            featuredCourse, ['course', 'card_image_url']),
                      ),
                      onTap: () =>
                          _openAssignment(courseReadInt(featuredCourse, 'id')),
                    ),
                    if (moreCourses.isNotEmpty) const SizedBox(height: 20),
                  ],
                  if (moreCourses.isNotEmpty) ...[
                    CourseHeaderRow(
                      title: 'More courses',
                      titleColor: courseBrandTealDark,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            if (courses.isEmpty)
              const CoursePageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: CourseSectionCard(
                  title: 'Courses',
                  child: Text('No courses assigned.'),
                ),
              )
            else if (moreCourses.isEmpty)
              const CoursePageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: CourseSectionCard(
                  title: 'Courses',
                  child: Text('No additional courses right now.'),
                ),
              )
            else
              CoursePageSliverList(
                itemCount: moreCourses.length,
                itemBuilder: (context, index) {
                  final item = courseAsMap(moreCourses[index]);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CourseCompactListCard(
                      imageUrl: widget.api.resolveUrl(
                        courseReadPath(item, ['course', 'card_image_url']),
                      ),
                      eyebrow: courseReadString(item, 'status_label'),
                      title: courseReadPath(item, ['course', 'title']),
                      description:
                          courseReadPath(item, ['course', 'description']),
                      metadata: const [],
                      onTap: () => _openAssignment(courseReadInt(item, 'id')),
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
