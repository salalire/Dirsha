import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../portfolio/providers/portfolio_provider.dart';
import '../../subscriptions/models/subscription_models.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../../wallet/providers/wallet_provider.dart';

/// Investor profile and account screen.
///
/// Displays real authenticated user data from [AuthProvider],
/// investment summary stats, permitted profile editing (name, phone),
/// settings, and sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Account & Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => auth.refreshUser(),
          ),
        ],
      ),
      body: user == null
          ? const LoadingIndicator.fullScreen(message: 'Loading profile…')
          : RefreshIndicator(
              color: AppColors.secondaryEmerald,
              backgroundColor: AppColors.cardSurface,
              onRefresh: () async {
                await Future.wait([
                  auth.refreshUser(),
                  context.read<WalletProvider>().refresh(),
                  context.read<PortfolioProvider>().refresh(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (AppConfig.useMockRepositories && !AppConfig.isProduction)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: MockDataBanner(detail: 'Profile using mock data'),
                      ),
                    _UserHeaderCard(user: user),
                    const SizedBox(height: 16),
                    _AccountOverviewCard(user: user),
                    const SizedBox(height: 16),
                    _ProfileDetailsCard(user: user),
                    const SizedBox(height: 16),
                    _SettingsAndSecurityCard(user: user),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header Card
// ---------------------------------------------------------------------------

class _UserHeaderCard extends StatelessWidget {
  const _UserHeaderCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final initials = user.fullName.isNotEmpty
        ? user.fullName
            .trim()
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.brandEmerald,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondaryEmerald, width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.screenTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : 'Investor',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brandEmerald.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.secondaryEmerald),
                      ),
                      child: Text(
                        user.role,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: user.isActive
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: user.isActive ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      child: Text(
                        user.accountStatus,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: user.isActive ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account Overview Card (Financial Quick Metrics)
// ---------------------------------------------------------------------------

class _AccountOverviewCard extends StatelessWidget {
  const _AccountOverviewCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final subs = context.watch<SubscriptionProvider>();

    final available = wallet.summary?.available;
    final totalPortfolioMinor = portfolio.portfolio?.summary.totalValuationMinor;
    final activeSubsCount = subs.subscriptions
        .where((s) => s.status == SubscriptionStatus.reserved)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Overview',
            style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Available Funds',
                  value: available != null
                      ? Formatters.money(available, symbol: 'ETB')
                      : '—',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.secondaryEmerald,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Portfolio Value',
                  value: totalPortfolioMinor != null
                      ? Formatters.money(Money(totalPortfolioMinor), symbol: 'ETB')
                      : '—',
                  icon: Icons.pie_chart_outline_rounded,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Active Subscriptions',
                  value: '$activeSubsCount offering(s)',
                  icon: Icons.business_center_outlined,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Verification',
                  value: user.verificationStatus,
                  icon: Icons.verified_user_outlined,
                  color: user.isVerified ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile Details Card (Editable Fields)
// ---------------------------------------------------------------------------

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Information',
                style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
              ),
              TextButton.icon(
                onPressed: () => _showEditProfileBottomSheet(context, user),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondaryEmerald,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Full Name',
            value: user.fullName.isNotEmpty ? user.fullName : '—',
          ),
          const Divider(color: AppColors.border, height: 20),
          _DetailRow(
            label: 'Email Address',
            value: user.email,
            trailingIcon: Icons.lock_outline,
            trailingTooltip: 'Email cannot be modified directly',
          ),
          const Divider(color: AppColors.border, height: 20),
          _DetailRow(
            label: 'Phone Number',
            value: user.phone.isNotEmpty ? user.phone : 'Not provided',
          ),
          const Divider(color: AppColors.border, height: 20),
          _DetailRow(
            label: 'Account Role',
            value: user.role,
          ),
          if (user.createdAt != null) ...[
            const Divider(color: AppColors.border, height: 20),
            _DetailRow(
              label: 'Member Since',
              value: Formatters.dateShort(user.createdAt!),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditProfileBottomSheet(BuildContext context, UserProfile user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _EditProfileSheet(user: user),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.trailingIcon,
    this.trailingTooltip,
  });

  final String label;
  final String value;
  final IconData? trailingIcon;
  final String? trailingTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (trailingIcon != null)
          Tooltip(
            message: trailingTooltip ?? '',
            child: Icon(
              trailingIcon,
              size: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Edit Profile Bottom Sheet
// ---------------------------------------------------------------------------

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});

  final UserProfile user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      fullName: newName.isNotEmpty ? newName : null,
      phone: newPhone.isNotEmpty ? newPhone : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to update profile'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profile',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DirshaTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              prefixIcon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Full name cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DirshaTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '+251 91 123 4567',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final phoneRegex = RegExp(r'^\+?[0-9 ()-]{7,20}$');
                  if (!phoneRegex.hasMatch(v.trim())) {
                    return 'Please enter a valid phone number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            DirshaButton(
              label: 'Save Changes',
              isLoading: _isSaving,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings and Security Card
// ---------------------------------------------------------------------------

class _SettingsAndSecurityCard extends StatelessWidget {
  const _SettingsAndSecurityCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Material(
      color: AppColors.cardSurface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            'Settings & Security',
            style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Dark Mode',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              'Toggle application theme',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            secondary: Icon(
              theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.textSecondary,
            ),
            value: theme.isDark,
            activeThumbColor: AppColors.secondaryEmerald,
            onChanged: (_) => theme.toggleTheme(),
          ),
          const Divider(color: AppColors.border, height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.info,
            ),
            title: Text(
              'Platform Environment',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              'Simulated Prototype (ETB test funds only)',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const Divider(color: AppColors.border, height: 24),
          DirshaButton(
            label: 'Sign Out',
            variant: DirshaBtnVariant.danger,
            onPressed: () async {
              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Sign out',
                message: 'Are you sure you want to sign out?',
                confirmLabel: 'Sign out',
                isDangerous: true,
              );
              if (confirmed == true && context.mounted) {
                await context.read<AuthProvider>().logout();
              }
            },
          ),
        ],
      ),
    ),
  );
}
}
