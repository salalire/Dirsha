import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/app_routes.dart';
import '../../../features/users/providers/users_provider.dart';
import '../../../features/companies/providers/companies_provider.dart';
import '../../../features/ipos/providers/ipos_provider.dart';
import '../../../features/users/models/user_application.dart';
import '../../../features/companies/models/company_application.dart';
import '../../../features/ipos/models/ipo_application.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().loadApplications();
      context.read<CompaniesProvider>().loadApplications();
      context.read<IposProvider>().loadApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          Text('Summary of pending administrative actions',
              style: TextStyle(
                  fontSize: 14, color: cs.onSurface.withAlpha(160))),
          const SizedBox(height: 24),
          _MetricCardsRow(),
          const SizedBox(height: 32),
          Text('Quick Actions',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 16),
          _QuickActions(),
          const SizedBox(height: 32),
          _RecentIpos(),
        ],
      ),
    );
  }
}

// ── Metric cards ──────────────────────────────────────────────────────────────

class _MetricCardsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        title: 'Pending User Reviews',
        icon: Icons.people_outline,
        color: const Color(0xFFDEEBFF),
        iconColor: AppColors.info,
        valueBuilder: (ctx) {
          final p = ctx.watch<UsersProvider>();
          if (p.isLoading) return '—';
          return p.applications
              .where((u) => u.status == UserApplicationStatus.pending)
              .length
              .toString();
        },
        onTap: () => context.go(AppRoutes.userReviews),
      ),
      _MetricCard(
        title: 'Pending Company Reviews',
        icon: Icons.business_outlined,
        color: const Color(0xFFD1FAE5),
        iconColor: AppColors.success,
        valueBuilder: (ctx) {
          final p = ctx.watch<CompaniesProvider>();
          if (p.isLoading) return '—';
          return p.applications
              .where((c) => c.status == CompanyApplicationStatus.pending)
              .length
              .toString();
        },
        onTap: () => context.go(AppRoutes.companyReviews),
      ),
      _MetricCard(
        title: 'IPOs Awaiting Review',
        icon: Icons.bar_chart_outlined,
        color: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFF92400E),
        valueBuilder: (ctx) {
          final p = ctx.watch<IposProvider>();
          if (p.isLoading) return '—';
          return p.applications.where((i) => i.isReviewable).length.toString();
        },
        onTap: () => context.go(AppRoutes.ipoManagement),
      ),
      _MetricCard(
        title: 'Approved IPOs',
        icon: Icons.check_circle_outline,
        color: const Color(0xFFDCFCE7),
        iconColor: AppColors.success,
        valueBuilder: (ctx) {
          final p = ctx.watch<IposProvider>();
          if (p.isLoading) return '—';
          return p.applications
              .where((i) => i.status == IpoStatus.approved)
              .length
              .toString();
        },
        onTap: () => context.go(AppRoutes.ipoManagement),
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (width > 800) {
        final cardWidth = (width - 48) / 4;
        return Row(
          children: cards
              .map((c) => SizedBox(width: cardWidth, child: c))
              .expand((w) => [w, const SizedBox(width: 16)])
              .toList()
            ..removeLast(),
        );
      } else if (width > 480) {
        final cardWidth = (width - 16) / 2;
        return Column(children: [
          Row(children: [
            SizedBox(width: cardWidth, child: cards[0]),
            const SizedBox(width: 16),
            SizedBox(width: cardWidth, child: cards[1]),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            SizedBox(width: cardWidth, child: cards[2]),
            const SizedBox(width: 16),
            SizedBox(width: cardWidth, child: cards[3]),
          ]),
        ]);
      } else {
        return Column(
          children: cards
              .expand((c) => [c, const SizedBox(height: 16)])
              .toList()
            ..removeLast(),
        );
      }
    });
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.valueBuilder,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String Function(BuildContext) valueBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.onSurface;
    final secondary = cs.onSurface.withAlpha(160);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: secondary),
                ],
              ),
              const SizedBox(height: 16),
              Text(valueBuilder(context),
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: primary)),
              const SizedBox(height: 4),
              Text(title,
                  style: TextStyle(fontSize: 12, color: secondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _QuickActionChip(
            label: 'Review IPO Applications',
            icon: Icons.bar_chart_outlined,
            onTap: () => context.go(AppRoutes.ipoManagement)),
        _QuickActionChip(
            label: 'Review User Applications',
            icon: Icons.people_outline,
            onTap: () => context.go(AppRoutes.userReviews)),
        _QuickActionChip(
            label: 'Review Company Applications',
            icon: Icons.business_outlined,
            onTap: () => context.go(AppRoutes.companyReviews)),
        _QuickActionChip(
            label: 'View Audit Log',
            icon: Icons.history_outlined,
            onTap: () => context.go(AppRoutes.audit)),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryLight),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}

// ── Recent IPOs ───────────────────────────────────────────────────────────────

class _RecentIpos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ipos = context.watch<IposProvider>();
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recent IPO Submissions',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const Spacer(),
            TextButton(
              onPressed: () => context.go(AppRoutes.ipoManagement),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ipos.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)))
              : ipos.applications.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('No IPO submissions yet.',
                            style: TextStyle(
                                color: cs.onSurface.withAlpha(160))),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ipos.applications.take(5).length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final ipo = ipos.applications[i];
                        return ListTile(
                          title: Text(ipo.offeringTitle,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                          subtitle: Text(ipo.companyName,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withAlpha(160))),
                          trailing: _ipoStatusChip(ipo.status),
                          onTap: () => context
                              .go(AppRoutes.ipoDetailPath(ipo.id)),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _ipoStatusChip(IpoStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case IpoStatus.submitted:
        bg = const Color(0xFFDEEBFF);
        fg = AppColors.info;
      case IpoStatus.underReview:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
      case IpoStatus.approved:
        bg = const Color(0xFFDCFCE7);
        fg = AppColors.success;
      case IpoStatus.rejected:
        bg = const Color(0xFFFEE2E2);
        fg = AppColors.error;
      default:
        bg = const Color(0xFFE5E7EB);
        fg = const Color(0xFF374151);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
