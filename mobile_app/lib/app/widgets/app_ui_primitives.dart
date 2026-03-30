import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/app_ui_patterns.dart';

class AppRoundIconButton extends StatelessWidget {
  const AppRoundIconButton({
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
          child: Icon(icon, color: inkColor, size: 20),
        ),
      ),
    );
  }
}

class ApiFutureBuilder extends StatelessWidget {
  const ApiFutureBuilder({
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
          return const AppLoadingState();
        }
        if (snapshot.hasError) {
          return AppErrorState(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
          );
        }
        return builder(context, snapshot.data ?? <String, dynamic>{});
      },
    );
  }
}

class AppPageBody extends StatelessWidget {
  const AppPageBody({
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

class AppPageSliverBody extends StatelessWidget {
  const AppPageSliverBody({super.key, required this.slivers});

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

class AppPageSliverSection extends StatelessWidget {
  const AppPageSliverSection({
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

class AppPageSliverList extends StatelessWidget {
  const AppPageSliverList({
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

class AppDashboardMetricRow extends StatelessWidget {
  const AppDashboardMetricRow({super.key, required this.metrics});

  final List<AppDashboardMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            SizedBox(
              width: 188,
              child: _AppDashboardMetricCard(data: metrics[i]),
            ),
            if (i < metrics.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _AppDashboardMetricCard extends StatelessWidget {
  const _AppDashboardMetricCard({required this.data});

  final AppDashboardMetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: lineColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, size: 22, color: brandTeal),
          ),
          const SizedBox(height: 12),
          Text(data.value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            tr(context, data.label),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class AppDashboardMetricData {
  const AppDashboardMetricData(this.label, this.value, {required this.icon});

  final String label;
  final String value;
  final IconData icon;
}

class AppOptimizedCourseCardImage extends StatelessWidget {
  const AppOptimizedCourseCardImage({
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
            ? AppLibraryCourseFallbackArt(title: title)
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
                      return AppLibraryCourseFallbackArt(title: title);
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        AppLibraryCourseFallbackArt(title: title),
                  );
                },
              ),
      ),
    );
  }
}

class AppCoursePromoCard extends StatelessWidget {
  const AppCoursePromoCard({
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
            border: Border.all(color: lineColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppOptimizedCourseCardImage(
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
                      tr(context, eyebrow),
                      style: const TextStyle(
                        color: brandTealDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    tr(context, meta),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                tr(context, title),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      height: 1.12,
                    ),
              ),
              if (supporting.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  tr(context, supporting),
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
                  child: Icon(icon, color: brandTeal),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppLessonTile extends StatelessWidget {
  const AppLessonTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
    this.accent = const Color(0xFFEAF2FF),
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData trailingIcon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: lineColor),
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(trailingIcon, color: brandTeal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, title),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(context, subtitle),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: mutedColor),
          ],
        ),
      ),
    );
  }
}

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
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
              tr(context, title),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: inkColor,
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

class AppHeaderRow extends StatelessWidget {
  const AppHeaderRow({
    super.key,
    required this.title,
    this.trailing,
    this.titleColor = inkColor,
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
            tr(context, title),
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

class AppSectionLink extends StatelessWidget {
  const AppSectionLink({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            tr(context, label),
            style: const TextStyle(
              color: brandTeal,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.label});

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
        tr(context, label),
        style: const TextStyle(
          color: brandTealDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AppNotificationSummaryChip extends StatelessWidget {
  const AppNotificationSummaryChip({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 20, color: brandTealDark),
          ),
          const SizedBox(height: 4),
          Text(
            tr(context, label),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: brandTealDark),
          ),
        ],
      ),
    );
  }
}

class AppInlineError extends StatelessWidget {
  const AppInlineError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECE8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC54C2B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr(context, message),
              style: const TextStyle(
                color: Color(0xFFC54C2B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key});

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
          Text(tr(context, 'Loading workspace...')),
        ],
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.message});

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
                    tr(context, 'Could not load this screen'),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, message),
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
