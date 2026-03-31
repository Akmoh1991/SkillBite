import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/app_ui_primitives.dart';

class AppHeaderActionButton extends StatelessWidget {
  const AppHeaderActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    if (icon != null) {
      return FilledButton.icon(
        style: style,
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(tr(context, label)),
      );
    }
    return FilledButton(
      style: style,
      onPressed: onPressed,
      child: Text(tr(context, label)),
    );
  }
}

class AppHeaderTonalButton extends StatelessWidget {
  const AppHeaderTonalButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(tr(context, label)),
    );
  }
}

class AppAvatarBadge extends StatelessWidget {
  const AppAvatarBadge({
    super.key,
    required this.label,
    this.size = 52,
  });

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = label
        .split(' ')
        .where((item) => item.trim().isNotEmpty)
        .take(2)
        .map((item) => item.trim()[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: brandTeal,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? 'SB' : initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.34,
          ),
        ),
      ),
    );
  }
}

class AppLibraryCourseFallbackArt extends StatelessWidget {
  const AppLibraryCourseFallbackArt({super.key, required this.title});

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
                tr(context, title),
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

class AppConversationRow extends StatelessWidget {
  const AppConversationRow({
    super.key,
    required this.name,
    required this.subtitle,
    required this.unreadCount,
    this.selected = false,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final int unreadCount;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF7F9FC) : surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: lineColor),
          ),
          child: Row(
            children: [
              AppAvatarBadge(label: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: brandTeal,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppChatMessageRow extends StatelessWidget {
  const AppChatMessageRow({
    super.key,
    required this.name,
    required this.body,
    required this.meta,
    required this.own,
  });

  final String name;
  final String body;
  final String meta;
  final bool own;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: own ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!own) ...[
          AppAvatarBadge(label: name),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: own ? const Color(0xFFEAF7F4) : surfaceAltColor,
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: own ? const Color(0xFFD0ECE6) : lineColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!own) ...[
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(body),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    meta,
                    style: const TextStyle(color: mutedColor, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AppChatModeChip extends StatelessWidget {
  const AppChatModeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? surfaceColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x100F172A),
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selected ? inkColor : const Color(0xFF61706C),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppRecordDetailLine extends StatelessWidget {
  const AppRecordDetailLine({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF61706C)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF61706C),
                  height: 1.45,
                ),
          ),
        ),
      ],
    );
  }
}

class AppManagementRecordCard extends StatelessWidget {
  const AppManagementRecordCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.metadata = const [],
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.detail,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> metadata;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final safePrimaryActionLabel = (primaryActionLabel ?? '').trim();
    final safeSecondaryActionLabel = (secondaryActionLabel ?? '').trim();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: lineColor),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: brandTeal),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, title),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr(context, description),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (metadata.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in metadata)
                    if (item.trim().isNotEmpty) AppStatusChip(label: item),
                ],
              ),
            ],
            if (detail != null) ...[
              const SizedBox(height: 14),
              detail!,
            ],
            if (safePrimaryActionLabel.isNotEmpty ||
                safeSecondaryActionLabel.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (safePrimaryActionLabel.isNotEmpty)
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: onPrimaryAction,
                        child: Text(safePrimaryActionLabel),
                      ),
                    ),
                  if (safePrimaryActionLabel.isNotEmpty &&
                      safeSecondaryActionLabel.isNotEmpty)
                    const SizedBox(width: 12),
                  if (safeSecondaryActionLabel.isNotEmpty)
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: onSecondaryAction,
                        child: Text(safeSecondaryActionLabel),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppRuleAssignmentTile extends StatelessWidget {
  const AppRuleAssignmentTile({
    super.key,
    required this.jobTitle,
    required this.checklistTitle,
  });

  final String jobTitle;
  final String checklistTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lineColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_tree_rounded, color: brandTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, jobTitle),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  tr(context, checklistTitle),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right_rounded, color: mutedColor),
        ],
      ),
    );
  }
}
