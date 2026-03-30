// ignore_for_file: use_build_context_synchronously

part of '../../../main.dart';

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
      _HeaderRow(
        title: 'Courses',
        titleColor: _brandTealDark,
        titleFontSize: 26,
        trailing: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _showCreateCourseDialog,
          child: Text(_tr(context, 'Add')),
        ),
      ),
      const SizedBox(height: 18),
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
