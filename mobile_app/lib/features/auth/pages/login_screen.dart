import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/session/session_user.dart';
import 'package:skillbite_mobile/features/auth/pages/forgot_password_screen.dart';
import 'package:skillbite_mobile/features/auth/pages/register_screen.dart';
import 'package:skillbite_mobile/features/auth/widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.api,
    required this.onLoggedIn,
  });

  final MobileApiClient api;
  final ValueChanged<SessionUser> onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;
  bool passwordObscured = true;
  String? errorText;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => errorText = 'Username and password are required.');
      return;
    }
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      final user = await widget.api.login(username, password);
      widget.onLoggedIn(user);
    } catch (error) {
      setState(() {
        errorText = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _openForgotPassword() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ForgotPasswordScreen(api: widget.api)),
    );
  }

  Future<void> _openRegister() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          api: widget.api,
          onRegistered: widget.onLoggedIn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arabic = isArabic(context);
    return AuthScaffold(
      leading: const LanguageToggleButton(),
      trailing: const SizedBox(width: 52),
      title: tr(context, 'Sign in to SkillBite'),
      subtitle: tr(
        context,
        'Please enter your information to login to your account',
      ),
      footer: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Text(
              tr(context, 'Need an account?'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF4A5A6A),
                  ),
            ),
            TextButton(
              onPressed: _openRegister,
              child: Text(
                tr(context, 'Create Account'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: brandTeal,
                    ),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFieldLabel(label: tr(context, 'Username')),
          const SizedBox(height: 10),
          AuthTextField(
            controller: usernameController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            directionMode: arabic
                ? AppTextFieldDirectionMode.rtl
                : AppTextFieldDirectionMode.ltr,
            decoration: InputDecoration(
              hintText: tr(context, 'Enter your username'),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          AuthFieldLabel(label: tr(context, 'Password')),
          const SizedBox(height: 10),
          AuthTextField(
            controller: passwordController,
            keyboardType: TextInputType.visiblePassword,
            obscureText: passwordObscured,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            directionMode: AppTextFieldDirectionMode.ltr,
            decoration: InputDecoration(
              hintText: tr(context, 'Enter your password'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => passwordObscured = !passwordObscured);
                },
                icon: Icon(
                  passwordObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: _openForgotPassword,
              child: Text(
                tr(context, 'Forgot Password?'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: brandTeal,
                    ),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            AppInlineError(message: errorText!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: loading ? null : _submit,
              child: Text(
                loading ? tr(context, 'Signing in...') : tr(context, 'Log In'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
