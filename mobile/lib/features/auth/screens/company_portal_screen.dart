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
      backgroundColor: AppColors.backgroundPrimary,
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
              _buildHeader(),
              const SizedBox(height: 28),
              _buildInfoCard(),
              const SizedBox(height: 28),
              if (portalAvailable)
                _buildPortalButton(context)
              else
                _buildUnavailableState(),
              const SizedBox(height: 24),
              _buildBackToLogin(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            color: AppColors.textPrimary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Company onboarding', style: AppTextStyles.sectionHeading),
              const SizedBox(height: 4),
              Text(
                'For company representatives',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What to expect', style: AppTextStyles.labelSmall),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.assignment_outlined,
            text: 'Submit your company profile and supporting documents.',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.admin_panel_settings_outlined,
            text: 'An administrator will review and approve your application.',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.trending_up_outlined,
            text: 'Once approved, you can create and manage IPO applications.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Company onboarding is handled through a dedicated web '
                    'portal, not this mobile application. Displaying this '
                    'screen does not verify or approve your company.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.info,
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

  Widget _buildUnavailableState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 36,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          Text(
            'Company portal not yet available',
            style: AppTextStyles.emptyStateTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The company onboarding portal is being prepared. '
            'Please check back later or contact the Dirsha team '
            'for registration assistance.',
            style: AppTextStyles.emptyStateBody,
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
          style: AppTextStyles.bodySmall.copyWith(
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
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }
}
