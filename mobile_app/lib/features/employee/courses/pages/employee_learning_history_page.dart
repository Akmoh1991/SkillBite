import 'package:flutter/material.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/features/employee/courses/course_flow_support.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/employee_course_detail_screen.dart';

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
    return CourseApiFutureBuilder(
      future: future,
      builder: (context, payload) {
        final history = courseAsList(payload['learning_history']);
        return CoursePageSliverBody(
          slivers: [
            CoursePageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CourseHeaderRow(
                    title: 'Learning History',
                    titleColor: courseBrandTealDark,
                    titleFontSize: 26,
                    trailing: CourseRoundIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: _reload,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            if (history.isEmpty)
              const CoursePageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: CourseSectionCard(
                  title: 'History',
                  child: Text('No completed courses yet.'),
                ),
              )
            else
              CoursePageSliverList(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = courseAsMap(history[index]);
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
                      metadata: [
                        '${courseReadPath(item, [
                              'course',
                              'estimated_minutes'
                            ])} ${courseTr(context, 'min')}',
                        '${courseReadPath(item, [
                              'course',
                              'content_item_total'
                            ])} ${courseTr(context, 'Items')}',
                      ],
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
