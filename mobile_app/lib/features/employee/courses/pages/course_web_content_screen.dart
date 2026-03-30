import 'package:flutter/material.dart';
import 'package:skillbite_mobile/features/employee/courses/course_flow_support.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CourseWebContentScreen extends StatefulWidget {
  const CourseWebContentScreen({
    super.key,
    required this.title,
    required this.url,
    required this.isPdf,
  });

  final String title;
  final String url;
  final bool isPdf;

  @override
  State<CourseWebContentScreen> createState() => _CourseWebContentScreenState();
}

class _CourseWebContentScreenState extends State<CourseWebContentScreen> {
  late final WebViewController controller;
  bool loading = true;
  String? errorText;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                loading = false;
                errorText = null;
              });
            }
          },
          onWebResourceError: (error) {
            if (!mounted) {
              return;
            }
            setState(() {
              loading = false;
              errorText = error.description.isEmpty
                  ? 'Could not load this file.'
                  : error.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final errorMessage =
                  courseTr(context, 'Could not open this file externally.');
              final uri = Uri.parse(widget.url);
              final opened =
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (!opened && mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(errorMessage)),
                );
              }
            },
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xCCFFFFFF),
                child: CourseLoadingState(),
              ),
            ),
          if (errorText != null)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xF7F7FAFC),
                child: Center(
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
                              const Icon(
                                Icons.link_off_rounded,
                                size: 36,
                                color: Color(0xFFC54C2B),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                courseTr(context, 'Could not load this screen'),
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                errorText!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: const Color(0xFF61706C)),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonal(
                                  onPressed: () {
                                    setState(() {
                                      loading = true;
                                      errorText = null;
                                    });
                                    controller
                                        .loadRequest(Uri.parse(widget.url));
                                  },
                                  child: Text(courseTr(context, 'Try again')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (widget.isPdf)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    courseTr(
                      context,
                      'If this PDF does not preview properly inside the app, use the open button in the top bar.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
