import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';
import 'package:video_player/video_player.dart';

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
          Flexible(
            fit: FlexFit.loose,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: trailing!,
            ),
          ),
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

class CourseLessonMediaCard extends StatefulWidget {
  const CourseLessonMediaCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.videoUrl = '',
    required this.mediaLabel,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String videoUrl;
  final String mediaLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<CourseLessonMediaCard> createState() => _CourseLessonMediaCardState();
}

class _CourseLessonMediaCardState extends State<CourseLessonMediaCard> {
  VideoPlayerController? _controller;
  bool _isInitializing = false;

  bool get _hasVideo => widget.videoUrl.trim().isNotEmpty;

  @override
  void didUpdateWidget(CourseLessonMediaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _controller = null;
      _isInitializing = false;
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (!_hasVideo) {
      widget.onTap();
      return;
    }

    final controller = _controller;
    if (controller == null) {
      await _initializeVideo();
      return;
    }

    if (!controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _initializeVideo() async {
    if (_isInitializing) {
      return;
    }

    final uri = Uri.tryParse(widget.videoUrl.trim());
    if (uri == null) {
      _showVideoLoadError();
      return;
    }

    setState(() {
      _isInitializing = true;
    });

    final nextController = VideoPlayerController.networkUrl(uri);
    try {
      await nextController.initialize();
      await nextController.setLooping(false);
      if (!mounted) {
        await nextController.dispose();
        return;
      }

      final previousController = _controller;
      _controller = nextController;
      if (previousController != null) {
        await previousController.dispose();
      }

      setState(() {});
      await nextController.play();
    } catch (_) {
      await nextController.dispose();
      _showVideoLoadError();
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _showVideoLoadError() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(courseTr(context, 'Could not load this video.'))),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arabic = courseIsArabic(context);
    final safeTitle =
        widget.title.trim().isEmpty
            ? courseTr(context, 'Lesson')
            : widget.title.trim();
    final safeSubtitle = widget.subtitle.trim();
    final cardChild = Container(
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: _buildMediaHero(context, arabic, safeTitle),
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
    );

    if (_hasVideo) {
      return cardChild;
    }

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(28),
      child: cardChild,
    );
  }

  Widget _buildMediaHero(BuildContext context, bool arabic, String safeTitle) {
    final controller = _controller;
    final isVideoReady = controller?.value.isInitialized ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isVideoReady && controller != null)
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.black),
              child: Center(
                child: AspectRatio(
                  aspectRatio:
                      controller.value.aspectRatio == 0
                          ? 16 / 9
                          : controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          )
        else ...[
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
        ],
        Positioned(
          top: 18,
          right: arabic ? 18 : null,
          left: arabic ? null : 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                Icon(widget.icon, size: 18, color: courseBrandTealDark),
                const SizedBox(width: 8),
                Text(
                  courseTr(context, widget.mediaLabel),
                  style: const TextStyle(
                    color: courseBrandTealDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isVideoReady)
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
              ),
            ),
          ),
        Center(child: _buildMediaActionButton()),
        if (isVideoReady && controller != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: _buildVideoControls(controller),
          )
        else ...[
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
      ],
    );
  }

  Widget _buildVideoControls(VideoPlayerController controller) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final duration = value.duration;
        final position =
            value.position > duration ? duration : value.position;
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              GestureDetector(
                onTap: _handlePrimaryAction,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white.withValues(alpha: 0.38),
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_formatVideoTime(position)} / ${_formatVideoTime(duration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatVideoTime(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildMediaActionButton() {
    if (!_hasVideo) {
      return _buildCircularMediaButton(
        child: Icon(
          widget.icon == Icons.picture_as_pdf_outlined
              ? Icons.picture_as_pdf_rounded
              : widget.icon == Icons.language_rounded
                  ? Icons.open_in_browser_rounded
                  : Icons.play_arrow_rounded,
          size: 46,
          color: courseBrandTealDark,
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _buildCircularMediaButton(
        onTap: _handlePrimaryAction,
        child:
            _isInitializing
                ? const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      courseBrandTealDark,
                    ),
                  ),
                )
                : const Icon(
                  Icons.play_arrow_rounded,
                  size: 46,
                  color: courseBrandTealDark,
                ),
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final isPlaying = value.isPlaying;
        return IgnorePointer(
          ignoring: isPlaying,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isPlaying ? 0 : 1,
            child: _buildCircularMediaButton(
              onTap: _handlePrimaryAction,
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 46,
                color: courseBrandTealDark,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircularMediaButton({
    required Widget child,
    VoidCallback? onTap,
  }) {
    final button = Container(
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
      child: Center(child: child),
    );

    if (onTap == null) {
      return button;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: button,
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
    this.eyebrow = '',
    this.topChipLabel,
    this.sideChipLabel,
    this.onTap,
  });

  final String imageUrl;
  final String title;
  final String description;
  final List<String> metadata;
  final String eyebrow;
  final String? topChipLabel;
  final String? sideChipLabel;
  final VoidCallback? onTap;

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
    final safeTopChipLabel = topChipLabel?.trim() ?? '';
    final safeSideChipLabel = sideChipLabel?.trim() ?? '';
    final visibleMetadata =
        metadata.where((item) => item.trim().isNotEmpty).toList(growable: false);
    final cardBody = Ink(
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
                if (safeTopChipLabel.isNotEmpty) ...[
                  CourseStatusChip(label: safeTopChipLabel),
                  const SizedBox(height: 10),
                ],
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
                        color: courseBrandTealDark,
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
                if (visibleMetadata.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in visibleMetadata)
                        CourseStatusChip(label: courseTr(context, item)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: safeSideChipLabel.isNotEmpty
                ? CourseStatusChip(label: safeSideChipLabel)
                : const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9AA6B2),
                  ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: onTap == null
          ? cardBody
          : InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: onTap,
              child: cardBody,
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
    this.titleColor,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  final String? title;
  final Color? titleColor;
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: titleColor),
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
