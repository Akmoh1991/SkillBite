import 'package:flutter/material.dart';
import 'package:skillbite_mobile/features/employee/courses/course_flow_support.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class CourseVideoScreen extends StatefulWidget {
  const CourseVideoScreen({
    super.key,
    required this.title,
    required this.videoUrl,
  });

  final String title;
  final String videoUrl;

  @override
  State<CourseVideoScreen> createState() => _CourseVideoScreenState();
}

class _CourseVideoScreenState extends State<CourseVideoScreen> {
  VideoPlayerController? controller;
  String? errorText;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final nextController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await nextController.initialize();
      await nextController.setLooping(false);
      await nextController.play();
      if (!mounted) {
        await nextController.dispose();
        return;
      }
      setState(() {
        controller = nextController;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        errorText = 'Could not load this video.';
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: controller == null
          ? Center(
              child: errorText == null
                  ? const CourseLoadingState()
                  : CourseErrorState(message: errorText!),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                CourseLessonProgressHeader(
                  status: courseTr(context, 'In progress'),
                  progress: 0.26,
                ),
                const SizedBox(height: 18),
                Text(
                  courseTr(context, 'About the lesson'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                        color: courseBrandTeal,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: courseBrandTeal,
                  ),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: controller!.value.aspectRatio == 0
                            ? 16 / 9
                            : controller!.value.aspectRatio,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                          child: ColoredBox(
                            color: Colors.black,
                            child: VideoPlayer(controller!),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                final isPlaying = controller!.value.isPlaying;
                                setState(() {
                                  if (isPlaying) {
                                    controller!.pause();
                                  } else {
                                    controller!.play();
                                  }
                                });
                              },
                              icon: Icon(
                                controller!.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.35),
                                  thumbColor: Colors.white,
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: controller!
                                      .value.position.inMilliseconds
                                      .toDouble()
                                      .clamp(
                                        0,
                                        (controller!.value.duration
                                                        .inMilliseconds ==
                                                    0
                                                ? 1
                                                : controller!.value.duration
                                                    .inMilliseconds)
                                            .toDouble(),
                                      ),
                                  max: (controller!.value.duration
                                                  .inMilliseconds ==
                                              0
                                          ? 1
                                          : controller!
                                              .value.duration.inMilliseconds)
                                      .toDouble(),
                                  onChanged: (value) {
                                    controller!.seekTo(
                                      Duration(milliseconds: value.round()),
                                    );
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final errorMessage = courseTr(
                                  context,
                                  'Could not open this video externally.',
                                );
                                final uri = Uri.parse(widget.videoUrl);
                                final opened = await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                                if (!opened && mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(errorMessage)),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style:
                      FilledButton.styleFrom(backgroundColor: courseBrandTeal),
                  child: Text(courseTr(context, 'Continue')),
                ),
              ],
            ),
    );
  }
}
