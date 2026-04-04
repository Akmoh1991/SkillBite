// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/features/employee/courses/course_flow_support.dart';

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
        'attempt_token': courseReadString(exam, 'attempt_token'),
        'answers': answers,
      });
      if (!mounted) {
        return;
      }
      final payload = courseAsMap(result['result']);
      final passed = courseReadBool(payload, 'passed');
      courseShowSnack(
        context,
        passed
            ? 'Exam passed with ${courseReadInt(payload, 'score_percent')}%.'
            : 'Exam submitted: ${courseReadInt(payload, 'score_percent')}%.',
      );
      Navigator.of(context).pop(passed);
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
      appBar: AppBar(title: Text(courseTr(context, 'Exam'))),
      body: CourseApiFutureBuilder(
        future: future,
        builder: (context, payload) {
          final exam = courseAsMap(payload['exam']);
          final questions = courseAsList(exam['questions']);

          return CoursePageBody(
            children: [
              CourseHeaderRow(
                title: 'Course Exam',
                titleColor: courseBrandTealDark,
                titleFontSize: 26,
              ),
              const SizedBox(height: 8),
              Text(
                '${courseTr(context, 'Pass score')} ${courseReadInt(exam, 'passing_score_percent')}%  |  ${courseReadInt(exam, 'duration_minutes')} ${courseTr(context, 'min')}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: courseBrandTealDark,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 20),
              for (final rawQuestion in questions) ...[
                CourseSectionCard(
                  title:
                      '${courseTr(context, 'Question')} ${courseReadInt(rawQuestion, 'order')}',
                  titleColor: courseBrandTealDark,
                  child: _ExamQuestionCard(
                    question: courseAsMap(rawQuestion),
                    answers: answers,
                    controller: _controllerForQuestion(
                        courseReadInt(rawQuestion, 'id')),
                    onChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: submitting ? null : () => _submit(exam),
                child: Text(
                  submitting
                      ? courseTr(context, 'Submitting...')
                      : courseTr(context, 'Submit Exam'),
                ),
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
    final questionId = courseReadInt(question, 'id');
    final questionKey = questionId.toString();
    final questionType = courseReadString(question, 'question_type');
    final options = courseAsList(question['options']);
    final answer = answers[questionKey];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          courseReadString(question, 'question_text'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (questionType == 'MCQ_SINGLE' || questionType == 'TRUE_FALSE')
          for (final option in options)
            RadioListTile<String>(
              value: courseReadInt(option, 'id').toString(),
              groupValue: answer?.toString(),
              contentPadding: EdgeInsets.zero,
              title: Text(courseReadString(option, 'text')),
              onChanged: (value) {
                answers[questionKey] = value ?? '';
                onChanged();
              },
            ),
        if (questionType == 'MCQ_MULTI')
          for (final option in options)
            CheckboxListTile(
              value: (answer is List ? answer : const [])
                  .contains(courseReadInt(option, 'id').toString()),
              contentPadding: EdgeInsets.zero,
              title: Text(courseReadString(option, 'text')),
              onChanged: (checked) {
                final values = List<String>.from(
                    answer is List ? answer : const <String>[]);
                final optionId = courseReadInt(option, 'id').toString();
                if (checked == true) {
                  if (!values.contains(optionId)) {
                    values.add(optionId);
                  }
                } else {
                  values.remove(optionId);
                }
                answers[questionKey] = values;
                onChanged();
              },
            ),
        if (questionType == 'SHORT_ANSWER' || questionType == 'ESSAY')
          AppTextField(
            controller: controller,
            minLines: questionType == 'ESSAY' ? 4 : 2,
            maxLines: questionType == 'ESSAY' ? 8 : 3,
            onChanged: (value) {
              answers[questionKey] = value;
            },
            decoration: InputDecoration(
              labelText: courseTr(context, 'Your answer'),
              alignLabelWithHint: true,
            ),
          ),
      ],
    );
  }
}
