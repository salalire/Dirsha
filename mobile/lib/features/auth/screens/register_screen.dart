import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/auth_models.dart';
import '../providers/auth_provider.dart';

/// Investor account creation screen.
///
/// Collects the minimum required fields from the SRS:
///   firstName, lastName, email, phone, password, confirmPassword.
///
/// Client-side validation runs before submission. Backend validation is
/// authoritative and errors are displayed via [AuthProvider.errorMessage].
///
/// Phase 1 only collects what the SRS lists for basic registration.
/// KYC and document submission are deferred to later phases.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.read<AuthProvider>().clearError();
    if (!_formKey.currentState!.validate()) return;

    final request = RegisterRequest(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    final success = await context.read<AuthProvider>().register(request);
    if (success && mounted) {
      context.go('/home');
    }
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  String? _required(String? v, String fieldName) {
    if (v == null || v.trim().isEmpty) return '$fieldName is required.';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Phone number is required.';
    // Ethiopian numbers: +251 followed by 9 digits, or 09XXXXXXXX.
    final phoneRe = RegExp(r'^(\+2519\d{8}|09\d{8})$');
    if (!phoneRe.hasMatch(v.replaceAll(' ', ''))) {
      return 'Enter a valid Ethiopian phone number (e.g. +251911000000).';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Create account'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (AppConfig.useMockRepositories && !AppConfig.isProduction)
              const MockDataBanner(
                detail: 'Mock auth active — registration simulated locally.',
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Start your investment journey.',
                      style: AppTextStyles.authSubtitle,
                    ),
                    const SizedBox(height: 32),
                    _buildForm(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 24),
                    _buildSignInLink(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              if (auth.errorMessage != null) ...[
                _buildErrorBanner(auth.errorMessage!),
                const SizedBox(height: 20),
              ],

              // Name row
              Row(
                children: [
                  Expanded(
                    child: DirshaTextField(
                      label: 'First name',
                      controller: _firstNameController,
                      validator: (v) => _required(v, 'First name'),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_lastNameFocus),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DirshaTextField(
                      label: 'Last name',
                      controller: _lastNameController,
                      validator: (v) => _required(v, 'Last name'),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.familyName],
                      focusNode: _lastNameFocus,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_emailFocus),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DirshaTextField(
                label: 'Email',
                hint: 'your@email.com',
                controller: _emailController,
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                prefixIcon: Icons.email_outlined,
                focusNode: _emailFocus,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_phoneFocus),
              ),
              const SizedBox(height: 16),

              DirshaTextField(
                label: 'Phone number',
                hint: '+251911000000',
                controller: _phoneController,
                validator: _validatePhone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.phone_outlined,
                focusNode: _phoneFocus,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
              ),
              const SizedBox(height: 16),

              DirshaTextField(
                label: 'Password',
                controller: _passwordController,
                validator: _validatePassword,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                prefixIcon: Icons.lock_outline_rounded,
                focusNode: _passwordFocus,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_confirmFocus),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Min 8 characters, one uppercase letter, one number.',
                  style: AppTextStyles.labelSmall,
                ),
              ),
              const SizedBox(height: 16),

              DirshaTextField(
                label: 'Confirm password',
                controller: _confirmPasswordController,
                validator: _validateConfirmPassword,
                obscureText: true,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline_rounded,
                focusNode: _confirmFocus,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => DirshaButton(
        label: 'Create account',
        onPressed: _submit,
        isLoading: auth.isLoading,
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ', style: AppTextStyles.bodySmall),
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign in',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryEmerald,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
