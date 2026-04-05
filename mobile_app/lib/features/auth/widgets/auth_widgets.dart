import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.leading,
    required this.trailing,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final Widget leading;
  final Widget trailing;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4FBF8), Color(0xFFF8FBFA)],
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [leading, trailing],
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 152,
                          height: 72,
                          child: Image.asset(
                            'assets/SkillBite_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: brandTeal,
                                fontSize: 28,
                                height: 1.08,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFF64748B),
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x120F172A),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: 14),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: isArabic(context) ? TextAlign.right : TextAlign.left,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
    );
  }
}

class AuthOrb extends StatelessWidget {
  const AuthOrb({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF13A36E)],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.96)),
    );
  }
}

class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: brandTeal,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      onPressed: () {
        AppLanguageController.onChange?.call(
          isArabic(context) ? AppLanguage.en : AppLanguage.ar,
        );
      },
      icon: const Icon(Icons.language_rounded),
      label: Text(isArabic(context) ? 'English' : tr(context, 'Arabic')),
    );
  }
}
