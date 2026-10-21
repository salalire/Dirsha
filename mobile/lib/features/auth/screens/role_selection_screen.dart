import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../router/app_router.dart';

/// Option C — account-entry role selection screen.
///
/// Presented when the user taps "Create account" from the login screen.
/// Directs each applicant type to the appropriate entry point:
///
///   Investor   → existing investor registration form (unchanged).
///   Company    → company portal entry screen (external portal, not a form).
///   Broker     → broker portal entry screen (external portal, not a form).
///
/// Security notes:
/// - Role selection here has NO effect on backend permissions.
/// - Selecting "Investor" does not grant admin or company access.
/// - All authorization is enforced by the backend on every request.
/// - The admin role is never offered here; admins are provisioned
///   server-side by the project owner.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Create account'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Who are you joining as?', style: AppTextStyles.screenTitle),
              const SizedBox(height: 8),
              Text(
                'Choose the account type that matches your role. '
                'Each type has a different registration process.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 32),
              _RoleCard(
                icon: Icons.person_outline_rounded,
                title: 'Investor',
                description:
                    'Browse IPO offerings, track your wallet, and manage '
                    'your investment portfolio.',
                onTap: () => context.push(AppRoutes.register),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.business_outlined,
                title: 'Company',
                description:
                    'Submit your company profile and IPO application '
                    'through the company onboarding portal.',
                onTap: () => context.push(AppRoutes.companyPortal),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.handshake_outlined,
                title: 'Broker',
                description:
                    'Apply as an approved broker and manage '
                    'investor relationships through the broker portal.',
                onTap: () => context.push(AppRoutes.brokerPortal),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTextStyles.bodySmall,
                  ),
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
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single role option card on the selection screen.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.brandEmerald,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
