// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/features/employee/courses/course_flow_support.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/course_video_screen.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/course_web_content_screen.dart';

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
  bool assigning = false;

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

  Future<void> _showAssignDialog() async {
    setState(() => assigning = true);
    List<dynamic> employees = const [];
    try {
      final payload = await widget.api.get('/business-owner/courses/');
      employees = courseAsList(payload['employees']);
    } catch (error) {
      if (!mounted) {
        return;
      }
      courseShowSnack(
          context, error.toString().replaceFirst('Exception: ', ''));
      setState(() => assigning = false);
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => assigning = false);

    if (employees.isEmpty) {
      courseShowSnack(context, 'لا يوجد موظفون متاحون للإسناد.');
      return;
    }

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
                    await widget.api.post(
                      '/business-owner/courses/${widget.courseId}/assign/',
                      {
                        'employee_ids': selectedIds.toList(),
                      },
                    );
                    if (!mounted) {
                      return;
                    }
                    Navigator.of(context).pop(true);
                  } catch (error) {
                    setInnerState(() {
                      errorText =
                          error.toString().replaceFirst('Exception: ', '');
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
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                    child: SizedBox(
                      width: 420,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'إسناد الدورة',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: saving
                                      ? null
                                      : () => Navigator.of(context).pop(false),
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: 'إغلاق',
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'اختر الموظفين الذين تريد إسناد هذه الدورة لهم.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
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
                                  border: Border.all(color: courseLine),
                                ),
                                child: CheckboxListTile(
                                  value: selectedIds
                                      .contains(courseReadInt(item, 'id')),
                                  onChanged: (checked) {
                                    setInnerState(() {
                                      final id = courseReadInt(item, 'id');
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
                                  title: Text(
                                      courseReadString(item, 'display_name')),
                                  subtitle: Text(
                                    courseReadString(item, 'job_title')
                                            .trim()
                                            .isEmpty
                                        ? 'لا يوجد مسمى وظيفي'
                                        : courseReadString(item, 'job_title'),
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
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: saving ? null : submit,
                                child: Text(saving ? 'جارٍ الحفظ...' : 'إسناد'),
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
        ) ??
        false;

    if (assigned == true && mounted) {
      courseShowSnack(context, 'تم إسناد الدورة.');
    }
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

  Widget _buildBody(BuildContext context, Map<String, dynamic> course) {
    final items = courseAsList(course['content_items']);
    final description = courseReadString(course, 'description');
    final estimatedMinutes = courseReadInt(course, 'estimated_minutes');
    final hasExam = courseReadBool(course, 'has_exam');
    final featuredContent = items.isEmpty ? null : courseAsMap(items.first);
    final courseTitle = courseReadString(course, 'title').trim().isEmpty
        ? 'الدورة'
        : courseReadString(course, 'title');

    return CoursePageBody(
      children: [
        CourseHeaderRow(
          title: courseTitle,
          titleColor: courseBrandTealDark,
          titleFontSize: 24,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CourseStatusChip(
              label: '$estimatedMinutes دقيقة',
            ),
            CourseStatusChip(
              label: '${items.length} عناصر',
            ),
            CourseStatusChip(label: hasExam ? 'الاختبار' : 'بدون اختبار'),
          ],
        ),
        const SizedBox(height: 24),
        if (featuredContent == null)
          const CourseSectionCard(
            title: 'الدرس',
            child: Text('لا توجد عناصر محتوى بعد.'),
          )
        else
          CourseLessonMediaCard(
            title: courseReadString(featuredContent, 'title').isEmpty
                ? courseTitle
                : courseReadString(featuredContent, 'title'),
            subtitle: description.isEmpty
                ? courseContentSubtitle(featuredContent)
                : description,
            videoUrl: widget.api.resolveUrl(
              courseReadString(featuredContent, 'video_url'),
            ),
            mediaLabel: coursePrimaryContentLabel(featuredContent),
            icon: courseContentIcon(featuredContent),
            onTap: () => _openContentItem(featuredContent),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: courseBrandTeal,
              minimumSize: const Size.fromHeight(58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            onPressed: assigning ? null : _showAssignDialog,
            child: Text(assigning ? 'جارٍ التحميل...' : 'إسناد الدورة'),
          ),
        ),
      ],
    );
  }

  Future<void> _showContentDialog({Map<String, dynamic>? item}) async {
    final isEditing = item != null;
    final titleController = TextEditingController(
      text: isEditing ? courseReadString(item, 'title') : '',
    );
    final bodyController = TextEditingController(
      text: isEditing ? courseReadString(item, 'body') : '',
    );
    final urlController = TextEditingController(
      text: isEditing ? courseReadString(item, 'material_url') : '',
    );
    final orderController = TextEditingController(
      text: isEditing ? '${courseReadInt(item, 'order')}' : '1',
    );
    String contentType =
        isEditing ? courseReadString(item, 'content_type') : 'TEXT';

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
                    '/business-owner/course-content/${courseReadInt(item, 'id')}/update/',
                    payload,
                  );
                } else {
                  await widget.api.post(
                    '/business-owner/courses/${widget.courseId}/content/create/',
                    payload,
                  );
                }
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
                      Text(
                        courseTr(
                          context,
                          isEditing ? 'تعديل المحتوى' : 'إضافة محتوى',
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        courseTr(
                          context,
                          'نظّم محتوى الدرس بعنوان واضح ووصف مناسب ونوع المحتوى الصحيح.',
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
                          labelText: 'نوع المحتوى',
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'TEXT',
                            child: const Text('نص'),
                          ),
                          DropdownMenuItem(
                            value: 'MATERIAL',
                            child: const Text('رابط'),
                          ),
                          DropdownMenuItem(
                            value: 'LESSON',
                            child: const Text('درس'),
                          ),
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
                        decoration: InputDecoration(
                          labelText: 'العنوان',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: bodyController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: 'الوصف',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                          labelText: 'رابط المحتوى',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: orderController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'الترتيب',
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
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(
                            saving
                                ? 'جارٍ الحفظ...'
                                : isEditing
                                    ? 'تحديث'
                                    : 'إنشاء',
                          ),
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
      courseShowSnack(
        context,
        isEditing ? 'تم تحديث المحتوى.' : 'تم إنشاء المحتوى.',
      );
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
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFC54C2B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حذف المحتوى',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'هل تريد حذف "${courseReadString(item, 'title')}"؟',
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
                      child: const Text('حذف'),
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
        '/business-owner/course-content/${courseReadInt(item, 'id')}/delete/',
        {},
      );
      if (!mounted) {
        return;
      }
      courseShowSnack(context, 'تم حذف المحتوى.');
      _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      courseShowSnack(
          context, error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التفاصيل')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildBody(context, widget.initialCourse ?? const {});
          }
          if (snapshot.hasError) {
            return CourseErrorState(
              message:
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
            );
          }
          final payload = snapshot.data ?? const <String, dynamic>{};
          return _buildBody(context, courseAsMap(payload['course']));
        },
      ),
    );
  }
}
