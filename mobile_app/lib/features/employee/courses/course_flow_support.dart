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

String coursePrimaryContentLabel(dynamic item) {
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
    return 'Lesson';
  }
  return 'Lesson';
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
    this.bottomPadding = 104,
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
          padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPadding),
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
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.titleFontSize,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final double? titleFontSize;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                courseTr(context, title),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: titleColor ?? courseInk,
                      fontSize: titleFontSize,
                    ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  courseTr(context, subtitle!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: courseMuted,
                        height: 1.45,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 16),
          trailing!,
        ],
      ],
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
    required this.mediaLabel,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String mediaLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final arabic = courseIsArabic(context);
    final safeTitle =
        title.trim().isEmpty ? courseTr(context, 'Lesson') : title.trim();
    final safeSubtitle = subtitle.trim();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F4F1), Color(0xFFD9ECE7)],
          ),
          border: Border.all(color: courseLine),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF1FAF7),
                            Color(0xFFC7DFD7),
                            Color(0xFF81A59C),
                          ],
                          stops: [0, 0.6, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -46,
                      left: arabic ? null : -36,
                      right: arabic ? -36 : null,
                      child: Container(
                        width: 168,
                        height: 168,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -54,
                      left: arabic ? -24 : null,
                      right: arabic ? null : -24,
                      child: Container(
                        width: 204,
                        height: 204,
                        decoration: BoxDecoration(
                          color: courseBrandTealDark.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 18,
                      right: arabic ? 18 : null,
                      left: arabic ? null : 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x120F172A),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 18, color: courseBrandTealDark),
                            const SizedBox(width: 8),
                            Text(
                              courseTr(context, mediaLabel),
                              style: const TextStyle(
                                color: courseBrandTealDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 22,
                      left: arabic ? 20 : null,
                      right: arabic ? null : 20,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          courseTr(context, safeTitle),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: arabic ? TextAlign.right : TextAlign.left,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A0F172A),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon == Icons.picture_as_pdf_outlined
                              ? Icons.picture_as_pdf_rounded
                              : icon == Icons.language_rounded
                                  ? Icons.open_in_browser_rounded
                                  : Icons.play_arrow_rounded,
                          size: 46,
                          color: courseBrandTealDark,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: arabic ? null : 136,
                      right: arabic ? 136 : null,
                      child: Container(
                        width: 54,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: arabic ? null : 196,
                      right: arabic ? 196 : null,
                      child: Container(
                        width: 28,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.98),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F0F172A),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    courseTr(context, safeTitle),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: arabic ? TextAlign.right : TextAlign.left,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: courseBrandTealDark,
                          height: 1.12,
                          fontSize: 22,
                        ),
                  ),
                  if (safeSubtitle.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      courseTr(context, safeSubtitle),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: arabic ? TextAlign.right : TextAlign.left,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF5B6878),
                            height: 1.48,
                          ),
                    ),
                  ],
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
    final arabic = courseIsArabic(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: courseBrandTealDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: arabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseTr(context, title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: arabic ? TextAlign.right : TextAlign.left,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: courseInk,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      courseTr(context, subtitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: arabic ? TextAlign.right : TextAlign.left,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5B6878),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                arabic
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: const Color(0xFF95A3B4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseSectionCard extends StatelessWidget {
  const CourseSectionCard({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: courseLine),
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
            if ((title != null && title!.trim().isNotEmpty) ||
                (subtitle != null && subtitle!.trim().isNotEmpty) ||
                trailing != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null && title!.trim().isNotEmpty)
                          Text(
                            courseTr(context, title!),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        if (subtitle != null &&
                            subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            courseTr(context, subtitle!),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: courseMuted,
                                  height: 1.45,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 16),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 18),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class CourseStatusChip extends StatelessWidget {
  const CourseStatusChip({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD6EAE4)),
      ),
      child: Text(
        courseTr(context, label),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: courseBrandTealDark,
              fontWeight: FontWeight.w800,
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
  const CourseErrorState({
    super.key,
    required this.message,
  });

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
