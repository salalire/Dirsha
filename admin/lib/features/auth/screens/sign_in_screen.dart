import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/dirsha_logo.dart';
import '../providers/auth_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AdminAuthProvider>();
    auth.clearError();
    final success = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (success && mounted) context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCard(isDark),
                  const SizedBox(height: 16),
                  _buildDemoNote(isDark),
                ],
              ),
            ),
          ),
          // Dark mode toggle — top right corner
          Positioned(
            top: 16,
            right: 16,
            child: Tooltip(
              message: isDark ? 'Light mode' : 'Dark mode',
              child: IconButton(
                onPressed: theme.toggle,
                icon: Icon(
                  isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: isDark
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Card(
        color: cardBg,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo ──────────────────────────────────────────────────────
              const Center(child: DirshaLogo(size: 60)),
              const SizedBox(height: 20),
              Text(
                'Dirsha',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Admin Dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: subtitleColor),
              ),
              const SizedBox(height: 32),

              // ── Form ──────────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!v.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                      onChanged: (_) =>
                          context.read<AdminAuthProvider>().clearError(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(() =>
                              _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                      onChanged: (_) =>
                          context.read<AdminAuthProvider>().clearError(),
                    ),
                    const SizedBox(height: 24),

                    // Error banner
                    Consumer<AdminAuthProvider>(
                      builder: (_, auth, child) {
                        if (auth.errorMessage == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkErrorBg
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.error.withAlpha(100)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 18, color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(auth.errorMessage!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.error)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Sign in button
                    Consumer<AdminAuthProvider>(
                      builder: (_, auth, child) => ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoNote(bool isDark) {
    final bg = isDark ? const Color(0xFF2A1E00) : const Color(0xFFFEF3C7);
    final border =
        isDark ? const Color(0xFF78350F) : const Color(0xFFF59E0B);
    final textColor =
        isDark ? const Color(0xFFD4A72C) : const Color(0xFF92400E);
    final bodyColor =
        isDark ? const Color(0xFFBB8B3A) : const Color(0xFF78350F);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science_outlined, size: 16, color: textColor),
                const SizedBox(width: 6),
                Text('DEVELOPMENT MODE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Phase 1 prototype — mock authentication only. '
              'No real backend connection.',
              style: TextStyle(fontSize: 12, color: bodyColor),
            ),
            const SizedBox(height: 8),
            Text('Demo credentials:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: bodyColor)),
            Text('Email: admin@dirsha.dev\nPassword: demo1234',
                style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: bodyColor)),
          ],
        ),
      ),
    );
  }
}
