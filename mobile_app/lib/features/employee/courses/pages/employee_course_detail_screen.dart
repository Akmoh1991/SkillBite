import 'package:flutter/material.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/features/employee/courses/course_flow_support.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/course_video_screen.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/course_web_content_screen.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/employee_exam_screen.dart';

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
    final title = courseReadString(item, 'title');
    final videoUrl = widget.api.resolveUrl(courseReadString(item, 'video_url'));
    final pdfUrl = widget.api.resolveUrl(courseReadString(item, 'pdf_url'));
    final materialUrl =
        widget.api.resolveUrl(courseReadString(item, 'material_url'));

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
      courseShowSnack(
        context,
        courseReadString(item, 'body').isNotEmpty
            ? courseReadString(item, 'body')
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
      if (!mounted) {
        return;
      }
      courseShowSnack(context, 'Course completed.');
      _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      courseShowSnack(
          context, error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(courseTr(context, 'Details'))),
      body: CourseApiFutureBuilder(
        future: future,
        builder: (context, payload) {
          final assignment = courseAsMap(payload['course_assignment']);
          final course = courseAsMap(assignment['course']);
          final courseTitle = courseReadString(course, 'title');
          final contentItems = courseAsList(course['content_items']);
          final hasExam = courseReadBool(course, 'has_exam');
          final statusLabel =
              courseReadString(assignment, 'status_label').isEmpty
                  ? courseTr(context, 'In progress')
                  : courseReadString(assignment, 'status_label');
          final featuredContent =
              contentItems.isEmpty ? const <dynamic>[] : [contentItems.first];
          final remainingContent = contentItems.length > 1
              ? contentItems.skip(1).toList()
              : const <dynamic>[];

          return CoursePageBody(
            children: [
              CourseHeaderRow(
                title: courseTitle.isEmpty ? 'Course' : courseTitle,
                titleColor: courseBrandTealDark,
                titleFontSize: 26,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CourseStatusChip(label: statusLabel),
                  CourseStatusChip(
                    label:
                        '${contentItems.length} ${courseTr(context, 'Items')}',
                  ),
                  if (hasExam) const CourseStatusChip(label: 'Exam'),
                ],
              ),
              const SizedBox(height: 16),
              if (featuredContent.isEmpty)
                const CourseSectionCard(
                  title: 'Lesson',
                  child: Text('No mobile content items.'),
                )
              else
                CourseLessonMediaCard(
                  title: courseReadString(course, 'title'),
                  subtitle: courseReadString(course, 'description').isEmpty
                      ? courseContentSubtitle(featuredContent.first)
                      : courseReadString(course, 'description'),
                  onTap: () =>
                      _openContentItem(courseAsMap(featuredContent.first)),
                ),
              const SizedBox(height: 18),
              if (remainingContent.isNotEmpty) ...[
                CourseSectionCard(
                  title: 'More content',
                  child: Column(
                    children: [
                      for (final item in remainingContent)
                        CourseContentTile(
                          title: courseReadString(item, 'title'),
                          subtitle: courseContentSubtitle(item),
                          icon: courseContentIcon(item),
                          onTap: () => _openContentItem(courseAsMap(item)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (hasExam) ...[
                const CourseSectionCard(
                  title: 'Exam',
                  child: Text(
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
                style: FilledButton.styleFrom(backgroundColor: courseBrandTeal),
                child: Text(
                  hasExam
                      ? courseTr(context, 'Continue')
                      : submitting
                          ? courseTr(context, 'Completing...')
                          : courseTr(context, 'Continue'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
