import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/features/auth/widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool saving = false;
  bool newPasswordObscured = true;
  bool confirmPasswordObscured = true;
  String? errorText;
  String? successText;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      saving = true;
      errorText = null;
      successText = null;
    });
    try {
      await widget.api.forgotPassword(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        newPassword: newPasswordController.text,
        confirmPassword: confirmPasswordController.text,
      );
      setState(() {
        successText =
            'Password updated. You can sign in with the new password now.';
      });
    } catch (error) {
      setState(() {
        errorText = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      leading: AppRoundIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
      trailing: const LanguageToggleButton(),
      title: tr(context, 'Reset Password'),
      subtitle: tr(
        context,
        'Reset your password using your username and the recovery email saved on your account.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthFieldLabel(label: tr(context, 'Username')),
          const SizedBox(height: 10),
          TextField(
            controller: usernameController,
            decoration: InputDecoration(
              hintText: tr(context, 'Enter your username'),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          AuthFieldLabel(label: tr(context, 'Recovery email')),
          const SizedBox(height: 10),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: tr(context, 'Enter your email'),
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          AuthFieldLabel(label: tr(context, 'New password')),
          const SizedBox(height: 10),
          TextField(
            controller: newPasswordController,
            obscureText: newPasswordObscured,
            decoration: InputDecoration(
              hintText: tr(context, 'New password'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => newPasswordObscured = !newPasswordObscured);
                },
                icon: Icon(
                  newPasswordObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuthFieldLabel(label: tr(context, 'Confirm password')),
          const SizedBox(height: 10),
          TextField(
            controller: confirmPasswordController,
            obscureText: confirmPasswordObscured,
            decoration: InputDecoration(
              hintText: tr(context, 'Confirm password'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(
                    () => confirmPasswordObscured = !confirmPasswordObscured,
                  );
                },
                icon: Icon(
                  confirmPasswordObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 16),
            AppInlineError(message: errorText!),
          ],
          if (successText != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                tr(context, successText!),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: brandTealDark),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving ? null : _submit,
            child: Text(
              saving ? tr(context, 'Updating...') : tr(context, 'Update Password'),
            ),
          ),
        ],
      ),
    );
  }
}
