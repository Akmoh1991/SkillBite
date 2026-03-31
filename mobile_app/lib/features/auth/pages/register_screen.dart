import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/session/session_user.dart';
import 'package:skillbite_mobile/features/auth/widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.api,
    required this.onRegistered,
  });

  final MobileApiClient api;
  final ValueChanged<SessionUser> onRegistered;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const List<String> _regions = [
    'Eastern region',
    'Central region',
    'Western region',
    'Northern region',
    'Southern region',
  ];

  static const List<String> _secBusinessLines = [
    'Distribution Contractors',
    'National Grid Contractors',
    'Projects Contractors',
    'Generation Contractors',
    'Dawiyat Contractors',
    'HSSE Contractors',
    'Material Sector',
    'Facilities Sector',
  ];

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController fullNameArabicController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();
  String selectedRegion = _regions.first;
  String selectedSecBusinessLine = _secBusinessLines.first;
  bool saving = false;
  bool passwordObscured = true;
  String? errorText;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    fullNameController.dispose();
    fullNameArabicController.dispose();
    passwordController.dispose();
    companyNameController.dispose();
    phoneNumberController.dispose();
    idNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      saving = true;
      errorText = null;
    });
    try {
      final user = await widget.api.register(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        fullName: fullNameController.text.trim(),
        fullNameArabic: fullNameArabicController.text.trim().isEmpty
            ? fullNameController.text.trim()
            : fullNameArabicController.text.trim(),
        password: passwordController.text,
        companyName: companyNameController.text.trim(),
        phoneNumber: phoneNumberController.text.trim(),
        idNumber: idNumberController.text.trim(),
        region: selectedRegion,
        secBusinessLine: selectedSecBusinessLine,
      );
      widget.onRegistered(user);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => errorText = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthFieldLabel(label: label),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthFieldLabel(label: label),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(),
          items: [
            for (final option in options)
              DropdownMenuItem<String>(
                value: option,
                child: Text(tr(context, option)),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      leading: AppRoundIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
      trailing: const LanguageToggleButton(),
      title: tr(context, 'Create Account'),
      subtitle: tr(
        context,
        'Create your business owner account to start using SkillBite.',
      ),
      footer: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          textDirection:
              isArabic(context) ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Text(
              tr(context, 'Already have an account?'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF4A5A6A),
                  ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                tr(context, 'Log In'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: brandTeal,
                    ),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: usernameController,
            label: tr(context, 'Username'),
            hint: tr(context, 'Enter your username'),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: fullNameController,
            label: tr(context, 'Full Name'),
            hint: tr(context, 'Enter your full name'),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: fullNameArabicController,
            label: tr(context, 'Full Name'),
            hint: tr(context, 'Enter your full name'),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: emailController,
            label: tr(context, 'Email'),
            hint: tr(context, 'Enter your email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AuthFieldLabel(label: tr(context, 'Password')),
          const SizedBox(height: 10),
          TextField(
            controller: passwordController,
            obscureText: passwordObscured,
            decoration: InputDecoration(
              hintText: tr(context, 'Enter your password'),
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
          const SizedBox(height: 16),
          _buildTextField(
            controller: companyNameController,
            label: tr(context, 'Company Name'),
            hint: tr(context, 'Enter your company name'),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: phoneNumberController,
            label: tr(context, 'Phone Number'),
            hint: tr(context, 'Enter your phone number'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: idNumberController,
            label: tr(context, 'ID Number'),
            hint: tr(context, 'Enter your ID number'),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: tr(context, 'Region'),
            value: selectedRegion,
            options: _regions,
            onChanged: (value) {
              if (value != null) setState(() => selectedRegion = value);
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: tr(context, 'SEC Business Line'),
            value: selectedSecBusinessLine,
            options: _secBusinessLines,
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedSecBusinessLine = value);
              }
            },
          ),
          if (errorText != null) ...[
            const SizedBox(height: 16),
            AppInlineError(message: errorText!),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving ? null : _submit,
            child: Text(
              saving
                  ? tr(context, 'Creating account...')
                  : tr(context, 'Create account'),
            ),
          ),
        ],
      ),
    );
  }
}
