import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';

const Color courseBrandTeal = brandTeal;
const Color courseBrandTealDark = brandTealDark;
const Color courseInk = inkColor;
const Color courseMuted = mutedColor;
const Color courseLine = lineColor;

bool courseIsArabic(BuildContext context) => isArabic(context);

String courseTr(BuildContext context, String english) => tr(context, english);

const Map<String, String> _courseArabicStrings = {
  'Courses': 'الدورات',
  'Pending courses': 'الدورات المعلقة',
  'Learning time': 'وقت التعلم',
  'Assigned courses': 'الدورات المسندة',
  'No assigned courses yet': 'لا توجد دورات مسندة بعد.',
  'New training will appear here when it is assigned.':
      'ستظهر الدورات الجديدة هنا عند إسنادها.',
  'min': 'دقيقة',
  'More courses': 'دورات إضافية',
  'No courses assigned.': 'لا توجد دورات مخصصة.',
  'No additional courses right now.': 'لا توجد دورات إضافية حالياً.',
  'Course': 'الدورة',
  'Practical course content with clear guidance and structured steps.':
      'محتوى تدريبي عملي بإرشادات واضحة وخطوات منظمة.',
  'History': 'السجل',
  'Learning History': 'سجل التعلم',
  'Completed': 'المكتمل',
  'Your completed learning will appear here': 'سيظهر التعلم المكتمل هنا.',
  'Finished training stays easy to revisit.':
      'يبقى التدريب المكتمل سهل الرجوع إليه.',
  'Minutes': 'الدقائق',
  'No completed courses yet.': 'لا توجد دورات مكتملة بعد.',
  'Details': 'التفاصيل',
  'Items': 'العناصر',
  'In progress': 'قيد التقدم',
  'Exam': 'الاختبار',
  'Lesson': 'الدرس',
  'No mobile content items.': 'لا توجد عناصر محتوى للجوال.',
  'More content': 'محتوى إضافي',
  'Continue': 'متابعة',
  'Completing...': 'جارٍ الإكمال...',
  'Course completed.': 'تم إكمال الدورة.',
  'No content URL available.': 'لا يوجد رابط متاح لهذا المحتوى.',
  'About the lesson': 'عن الدرس',
  'Could not load this video.': 'تعذر تحميل هذا الفيديو.',
  'Could not open this video externally.': 'تعذر فتح الفيديو خارج التطبيق.',
  'Could not load this file.': 'تعذر تحميل هذا الملف.',
  'Could not open this file externally.': 'تعذر فتح الملف خارج التطبيق.',
  'Could not load this screen': 'تعذر تحميل هذه الشاشة',
  'Try again': 'حاول مرة أخرى',
  'Loading workspace...': 'جارٍ تحميل مساحة العمل...',
  'Course Exam': 'اختبار الدورة',
  'Pass score': 'درجة النجاح',
  'Question': 'السؤال',
  'Your answer': 'إجابتك',
  'Submitting...': 'جارٍ الإرسال...',
  'Submit Exam': 'إرسال الاختبار',
  'Review the lesson content, then continue to the exam when you are ready.':
      'راجع محتوى الدرس ثم انتقل إلى الاختبار عندما تكون جاهزاً.',
  'Video lesson': 'درس فيديو',
  'PDF material': 'ملف PDF',
  'If this PDF does not preview properly inside the app, use the open button in the top bar.':
      'إذا لم يظهر ملف PDF بشكل صحيح داخل التطبيق فاستخدم زر الفتح في الشريط العلوي.',
};

Map<String, dynamic> courseAsMap(Object? value) {
  return asMap(value);
}

List<dynamic> courseAsList(Object? value) {
  return asList(value);
}

String courseReadString(dynamic source, String key) {
  return readString(source, key);
}

int courseReadInt(dynamic source, String key) {
  return readInt(source, key);
}

bool courseReadBool(dynamic source, String key) {
  return readBool(source, key);
}

String courseReadPath(dynamic source, List<String> path) {
  return readPath(source, path);
}

String courseContentSubtitle(dynamic item) {
  final videoUrl = courseReadString(item, 'video_url');
  final pdfUrl = courseReadString(item, 'pdf_url');
  final materialUrl = courseReadString(item, 'material_url');
  if (videoUrl.isNotEmpty) {
    return 'Video lesson';
  }
  if (pdfUrl.isNotEmpty) {
    return 'PDF material';
  }
  if (materialUrl.isNotEmpty) {
    return materialUrl;
  }
  return courseReadString(item, 'body');
}

IconData courseContentIcon(dynamic item) {
  final videoUrl = courseReadString(item, 'video_url');
  final pdfUrl = courseReadString(item, 'pdf_url');
  final materialUrl = courseReadString(item, 'material_url');
  if (videoUrl.isNotEmpty) {
    return Icons.play_circle_outline_rounded;
  }
  if (pdfUrl.isNotEmpty) {
    return Icons.picture_as_pdf_outlined;
  }
  if (materialUrl.isNotEmpty) {
    return Icons.language_rounded;
  }
  return Icons.article_outlined;
}

void courseShowSnack(BuildContext context, String message) {
  showSnack(context, message);
}

class CourseApiFutureBuilder extends StatelessWidget {
  const CourseApiFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
  });

  final Future<Map<String, dynamic>> future;
  final Widget Function(BuildContext context, Map<String, dynamic> payload)
      builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CourseLoadingState();
        }
        if (snapshot.hasError) {
          return CourseErrorState(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
          );
        }
        return builder(context, snapshot.data ?? <String, dynamic>{});
      },
    );
  }
}

class CoursePageBody extends StatelessWidget {
  const CoursePageBody({
    super.key,
    required this.children,
    this.bottomPadding = 120,
  });

  final List<Widget> children;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
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
        child: ListView(
          padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoursePageSliverBody extends StatelessWidget {
  const CoursePageSliverBody({super.key, required this.slivers});

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
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
          slivers: slivers,
        ),
      ),
    );
  }
}

class CoursePageSliverSection extends StatelessWidget {
  const CoursePageSliverSection({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 0),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: child,
          ),
        ),
      ),
    );
  }
}

class CoursePageSliverList extends StatelessWidget {
  const CoursePageSliverList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 120),
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: itemBuilder(context, index),
            ),
          );
        }, childCount: itemCount),
      ),
    );
  }
}

class CourseRoundIconButton extends StatelessWidget {
  const CourseRoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: courseInk, size: 20),
        ),
      ),
    );
  }
}

class CourseHeaderRow extends StatelessWidget {
  const CourseHeaderRow({
    super.key,
    required this.title,
    this.trailing,
    this.titleColor = courseInk,
    this.titleFontSize = 20,
  });

  final String title;
  final Widget? trailing;
  final Color titleColor;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            courseTr(context, title),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: titleColor,
                  fontSize: titleFontSize,
                ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class CourseSectionCard extends StatelessWidget {
  const CourseSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              courseTr(context, title),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: courseInk,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class CourseStatusChip extends StatelessWidget {
  const CourseStatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        courseTr(context, label),
        style: const TextStyle(
          color: courseBrandTealDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class CoursePromoCard extends StatelessWidget {
  const CoursePromoCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.meta,
    this.supporting = '',
    this.imageUrl = '',
    this.icon,
    this.onTap,
  });

  final String eyebrow;
  final String title;
  final String meta;
  final String supporting;
  final String imageUrl;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: courseLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CourseOptimizedCardImage(
                imageUrl: imageUrl,
                title: title,
                aspectRatio: 1.7,
                borderRadius: 22,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      courseTr(context, eyebrow),
                      style: const TextStyle(
                        color: courseBrandTealDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    courseTr(context, meta),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: courseMuted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                courseTr(context, title),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      height: 1.12,
                    ),
              ),
              if (supporting.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  courseTr(context, supporting),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (icon != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: courseBrandTeal),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CourseLessonProgressHeader extends StatelessWidget {
  const CourseLessonProgressHeader({
    super.key,
    required this.status,
    required this.progress,
  });

  final String status;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.close_rounded, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F3F7),
              color: courseBrandTeal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.more_vert_rounded),
      ],
    );
  }
}

class CourseLessonMediaCard extends StatelessWidget {
  const CourseLessonMediaCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: courseBrandTeal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: Container(
                height: 228,
                color: const Color(0xFFE7F3F0),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.ondemand_video_rounded,
                              size: 72,
                              color: Color(0xFF5E6A7D),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 18),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: courseMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bookmark_border_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 0.78,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.fullscreen_rounded, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseOptimizedCardImage extends StatelessWidget {
  const CourseOptimizedCardImage({
    super.key,
    required this.imageUrl,
    required this.title,
    this.aspectRatio = 1.85,
    this.borderRadius = 22,
  });

  final String imageUrl;
  final String title;
  final double aspectRatio;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final trimmedImageUrl = imageUrl.trim();
    final hasImage = trimmedImageUrl.isNotEmpty &&
        (Uri.tryParse(trimmedImageUrl)?.hasScheme ?? false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: !hasImage
            ? CourseLibraryFallbackArt(title: title)
            : LayoutBuilder(
                builder: (context, constraints) {
                  final dpr = MediaQuery.devicePixelRatioOf(context);
                  final width = constraints.hasBoundedWidth &&
                          constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : MediaQuery.sizeOf(context).width;
                  final targetWidth =
                      (width * dpr).clamp(320.0, 1280.0).round();

                  return Image.network(
                    trimmedImageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: targetWidth,
                    filterQuality: FilterQuality.low,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded || frame != null) {
                        return child;
                      }
                      return CourseLibraryFallbackArt(title: title);
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        CourseLibraryFallbackArt(title: title),
                  );
                },
              ),
      ),
    );
  }
}

class CourseCompactListCard extends StatelessWidget {
  const CourseCompactListCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.metadata,
    required this.onTap,
    this.eyebrow = '',
  });

  final String imageUrl;
  final String title;
  final String description;
  final List<String> metadata;
  final VoidCallback onTap;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final safeTitle =
        title.trim().isEmpty ? courseTr(context, 'Course') : title.trim();
    final safeDescription = description.trim().isEmpty
        ? courseTr(
            context,
            'Practical course content with clear guidance and structured steps.',
          )
        : description.trim();
    final safeEyebrow = eyebrow.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: courseLine),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 102,
                child: CourseOptimizedCardImage(
                  imageUrl: imageUrl,
                  title: safeTitle,
                  aspectRatio: 1.04,
                  borderRadius: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (safeEyebrow.isNotEmpty) ...[
                      Text(
                        courseTr(context, safeEyebrow),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: courseMuted,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      courseTr(context, safeTitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      courseTr(context, safeDescription),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF7B879B),
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in metadata)
                          if (item.trim().isNotEmpty)
                            CourseStatusChip(label: courseTr(context, item)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA6B2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseLibraryFallbackArt extends StatelessWidget {
  const CourseLibraryFallbackArt({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCADFD9), Color(0xFF8FA9A3), Color(0xFF4C5D5A)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -30,
            right: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -24,
            left: -18,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                courseTr(context, title),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CourseContentTile extends StatelessWidget {
  const CourseContentTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: courseLine),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEDE8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseTr(context, title),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      courseTr(context, subtitle),
                      style: const TextStyle(color: Color(0xFF61706C)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseLoadingState extends StatelessWidget {
  const CourseLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(height: 14),
          Text(courseTr(context, 'Loading workspace...')),
        ],
      ),
    );
  }
}

class CourseErrorState extends StatelessWidget {
  const CourseErrorState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECE8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: Color(0xFFC54C2B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    courseTr(context, 'Could not load this screen'),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    courseTr(context, message),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF61706C),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
