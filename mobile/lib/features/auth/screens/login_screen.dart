import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/auth_models.dart';
import '../providers/auth_provider.dart';

/// Investor sign-in screen.
///
/// Performs client-side validation before submitting. Backend validation
/// is authoritative — error messages from the backend are surfaced via
/// [AuthProvider.errorMessage].
///
/// Security:
/// - Password field uses obscureText; value is never stored in state.
/// - Form data is not logged.
/// - The mock-credentials hint is only shown when useMockRepositories is true.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Clear any previous provider-level error before a new attempt.
    context.read<AuthProvider>().clearError();

    if (!_formKey.currentState!.validate()) return;

    final request = LoginRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final success = await context.read<AuthProvider>().login(request);
    if (success && mounted) {
      context.go('/home');
    }
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required.';
    // Basic structure check — backend performs the authoritative validation.
    final emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRe.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Mock data banner — only visible when mocks are active.
            if (AppConfig.useMockRepositories && !AppConfig.isProduction)
              MockDataBanner(
                detail: 'Mock auth active. Use investor@dirsha.dev / Demo1234!',
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 56),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildForm(),
                    const SizedBox(height: 8),
                    _buildForgotPassword(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 24),
                    _buildSignUpLink(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App wordmark
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandEmerald,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppConfig.appName,
              style: AppTextStyles.authHeadline.copyWith(fontSize: 22),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text('Welcome back', style: AppTextStyles.authHeadline),
        const SizedBox(height: 8),
        Text(
          'Sign in to your investor account.',
          style: AppTextStyles.authSubtitle,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Backend-level error banner
              if (auth.errorMessage != null) ...[
                _buildErrorBanner(auth.errorMessage!),
                const SizedBox(height: 20),
              ],

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
                    FocusScope.of(context).requestFocus(_passwordFocus),
              ),
              const SizedBox(height: 16),

              DirshaTextField(
                label: 'Password',
                controller: _passwordController,
                validator: _validatePassword,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                prefixIcon: Icons.lock_outline_rounded,
                focusNode: _passwordFocus,
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

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Forgot-password flow is out of scope for Phase 1.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset is not yet available.'),
            ),
          );
        },
        child: Text(
          'Forgot password?',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.secondaryEmerald,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return DirshaButton(
          label: 'Sign in',
          onPressed: _submit,
          isLoading: auth.isLoading,
        );
      },
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ", style: AppTextStyles.bodySmall),
        TextButton(
          onPressed: () => context.push('/register'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Create account',
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
