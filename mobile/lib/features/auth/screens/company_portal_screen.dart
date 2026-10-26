import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';

/// Company applicant entry point — Option C.
///
/// Directs company representatives to the dedicated company onboarding
/// portal. This screen does NOT collect company information or submit
/// applications. The complete company onboarding workflow is a separate
/// portal owned by the backend and admin teams.
///
/// If [AppConfig.companyPortalUrl] is empty, the screen shows a clear
/// "not yet available" message rather than a broken link or an invented
/// destination.
///
/// Important:
/// - No company registration form is implemented here.
/// - No documents are uploaded through this screen.
/// - Displaying this screen does NOT verify or approve any company.
/// - The backend is the authoritative source for onboarding status.
class CompanyPortalScreen extends StatelessWidget {
  const CompanyPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final portalAvailable = AppConfig.companyPortalUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company onboarding'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              _buildHeader(context),
              const SizedBox(height: 28),
              _buildInfoCard(context),
              const SizedBox(height: 28),
              if (portalAvailable)
                _buildPortalButton(context)
              else
                _buildUnavailableState(context),
              const SizedBox(height: 24),
              _buildBackToLogin(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.brandEmerald,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.business_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Company onboarding', style: AppTextStyles.sectionHeadingOf(context)),
              const SizedBox(height: 4),
              Text(
                'For company representatives',
                style: AppTextStyles.bodySmallOf(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What to expect', style: AppTextStyles.labelSmallOf(context)),
          const SizedBox(height: 12),
          const _InfoRow(
            icon: Icons.assignment_outlined,
            text: 'Submit your company profile and supporting documents.',
          ),
          const SizedBox(height: 10),
          const _InfoRow(
            icon: Icons.admin_panel_settings_outlined,
            text: 'An administrator will review and approve your application.',
          ),
          const SizedBox(height: 10),
          const _InfoRow(
            icon: Icons.trending_up_outlined,
            text: 'Once approved, you can create and manage IPO applications.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.infoSurfaceOf(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.infoOf(context).withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.infoOf(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Company onboarding is handled through a dedicated web '
                    'portal, not this mobile application. Displaying this '
                    'screen does not verify or approve your company.',
                    style: AppTextStyles.labelSmallOf(context).copyWith(
                      color: AppColors.infoOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalButton(BuildContext context) {
    return DirshaButton(
      label: 'Open company portal',
      onPressed: () {
        // TODO(integration): Launch AppConfig.companyPortalUrl via
        // url_launcher once the portal URL is confirmed by the project owner.
        // For now, show a snackbar — the URL is configured but the
        // url_launcher package has not been added to avoid unnecessary
        // dependencies before the URL is finalized.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Company portal: ${AppConfig.companyPortalUrl}'),
          ),
        );
      },
      icon: Icons.open_in_new_rounded,
    );
  }

  Widget _buildUnavailableState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningSurfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warningOf(context).withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 36,
            color: AppColors.warningOf(context),
          ),
          const SizedBox(height: 12),
          Text(
            'Company portal not yet available',
            style: AppTextStyles.emptyStateTitleOf(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The company onboarding portal is being prepared. '
            'Please check back later or contact the Dirsha team '
            'for registration assistance.',
            style: AppTextStyles.emptyStateBodyOf(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLogin(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => context.go('/login'),
        child: Text(
          'Back to sign in',
          style: AppTextStyles.bodySmallOf(context).copyWith(
            color: AppColors.secondaryEmerald,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryEmerald),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTextStyles.bodySmallOf(context))),
      ],
    );
  }
}
