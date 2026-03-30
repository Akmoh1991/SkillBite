// ignore_for_file: use_build_context_synchronously

part of '../../../main.dart';

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
        _HeaderRow(
          title: _readString(course, 'title').isEmpty
              ? 'Course'
              : _readString(course, 'title'),
          titleColor: _brandTealDark,
          titleFontSize: 26,
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _muted,
                  height: 1.5,
                ),
          ),
        ],
        const SizedBox(height: 18),
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
