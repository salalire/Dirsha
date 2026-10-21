import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../routing/app_routes.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/widgets/mock_banner.dart';
import '../../shared/widgets/dirsha_logo.dart';

/// The main application shell — persistent sidebar + top bar.
/// Responds to both narrow-screen (drawer) and wide-screen (sidebar) layouts.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child, required this.currentPath});

  final Widget child;
  final String currentPath;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _sidebarExpanded = true;

  static const double _sidebarWidthExpanded = 240;
  static const double _sidebarWidthCollapsed = 68;
  static const double _narrowBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < _narrowBreakpoint;
    final isDark = context.watch<ThemeProvider>().isDark;

    if (isNarrow && _sidebarExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _sidebarExpanded = false);
      });
    }

    // Top bar and content area background adapts to theme
    final topBarBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final topBarBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final scaffoldBg =
        isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: scaffoldBg,
      drawer: isNarrow
          ? Drawer(
              backgroundColor: AppColors.sidebarBackground,
              child: _SidebarContent(
                currentPath: widget.currentPath,
                expanded: true,
                onToggle: () {},
              ),
            )
          : null,
      body: Column(
        children: [
          const MockDataBanner(),
          Expanded(
            child: Row(
              children: [
                if (!isNarrow)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _sidebarExpanded
                        ? _sidebarWidthExpanded
                        : _sidebarWidthCollapsed,
                    child: _SidebarContent(
                      currentPath: widget.currentPath,
                      expanded: _sidebarExpanded,
                      onToggle: () => setState(
                          () => _sidebarExpanded = !_sidebarExpanded),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        currentPath: widget.currentPath,
                        isNarrow: isNarrow,
                        topBarBg: topBarBg,
                        topBarBorder: topBarBorder,
                        isDark: isDark,
                      ),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────────────────

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.currentPath,
    required this.expanded,
    required this.onToggle,
  });

  final String currentPath;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          // ── Brand area ──────────────────────────────────────────────────
          SizedBox(
            height: 68,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: expanded ? 16 : 10, vertical: 10),
              child: expanded
                  ? DirshaLogoWithText(
                      logoSize: 38,
                      textColor: Colors.white,
                      subtitleColor: AppColors.sidebarText,
                      subtitle: 'Admin Dashboard',
                    )
                  : const Center(child: DirshaLogo(size: 38)),
            ),
          ),
          const Divider(color: Color(0xFF1A6B52), height: 1),
          const SizedBox(height: 8),

          // ── Nav items ───────────────────────────────────────────────────
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: AppRoutes.dashboard,
            currentPath: currentPath,
            expanded: expanded,
          ),
          _NavItem(
            icon: Icons.people_outline,
            label: 'User Reviews',
            route: AppRoutes.userReviews,
            currentPath: currentPath,
            expanded: expanded,
          ),
          _NavItem(
            icon: Icons.business_outlined,
            label: 'Company Reviews',
            route: AppRoutes.companyReviews,
            currentPath: currentPath,
            expanded: expanded,
          ),
          _NavItem(
            icon: Icons.bar_chart_outlined,
            label: 'IPO Management',
            route: AppRoutes.ipoManagement,
            currentPath: currentPath,
            expanded: expanded,
          ),
          _NavItem(
            icon: Icons.history_outlined,
            label: 'Audit / Activity',
            route: AppRoutes.audit,
            currentPath: currentPath,
            expanded: expanded,
          ),

          const Spacer(),
          const Divider(color: Color(0xFF1A6B52), height: 1),

          // ── Collapse toggle ─────────────────────────────────────────────
          InkWell(
            onTap: onToggle,
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      expanded ? Icons.chevron_left : Icons.chevron_right,
                      color: AppColors.sidebarText,
                      size: 20,
                    ),
                    if (expanded) ...[
                      const SizedBox(width: 12),
                      const Text('Collapse',
                          style: TextStyle(
                              color: AppColors.sidebarText, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentPath,
    required this.expanded,
  });

  final IconData icon;
  final String label;
  final String route;
  final String currentPath;
  final bool expanded;

  bool get _isActive => currentPath.startsWith(route);

  @override
  Widget build(BuildContext context) {
    final isActive = _isActive;
    return Semantics(
      label: label,
      selected: isActive,
      child: InkWell(
        onTap: () => context.go(route),
        child: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.sidebarActive : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: isActive
                      ? AppColors.sidebarActiveText
                      : AppColors.sidebarText),
              if (expanded) ...[
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.sidebarActiveText
                          : AppColors.sidebarText,
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentPath,
    required this.isNarrow,
    required this.topBarBg,
    required this.topBarBorder,
    required this.isDark,
  });

  final String currentPath;
  final bool isNarrow;
  final Color topBarBg;
  final Color topBarBorder;
  final bool isDark;

  String get _pageTitle {
    if (currentPath.startsWith(AppRoutes.ipoManagement)) return 'IPO Management';
    if (currentPath.startsWith(AppRoutes.userReviews)) return 'User Reviews';
    if (currentPath.startsWith(AppRoutes.companyReviews)) return 'Company Reviews';
    if (currentPath.startsWith(AppRoutes.audit)) return 'Audit / Activity';
    return 'Dashboard';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: topBarBg,
        border: Border(bottom: BorderSide(color: topBarBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isNarrow)
            IconButton(
              icon: Icon(Icons.menu, color: textColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Open navigation menu',
            ),
          Text(_pageTitle,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
          const Spacer(),
          const MockModeBadge(),
          const SizedBox(width: 12),

          // ── Dark mode toggle ─────────────────────────────────────────────
          Tooltip(
            message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            child: IconButton(
              onPressed: theme.toggle,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    RotationTransition(
                        turns: anim,
                        child: FadeTransition(opacity: anim, child: child)),
                child: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  key: ValueKey(isDark),
                  color: isDark ? AppColors.accent : AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Account menu ─────────────────────────────────────────────────
          PopupMenuButton<String>(
            tooltip: 'Account menu',
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (auth.user?.displayName.isNotEmpty == true
                            ? auth.user!.displayName[0]
                            : 'A')
                        .toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(auth.user?.displayName ?? 'Admin',
                    style: TextStyle(fontSize: 14, color: textColor)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: subColor),
              ],
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.user?.displayName ?? 'Admin',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(auth.user?.email ?? '',
                        style: TextStyle(fontSize: 12, color: subColor)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'sign_out',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Sign Out',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'sign_out') {
                await context.read<AdminAuthProvider>().signOut();
                if (context.mounted) context.go(AppRoutes.signIn);
              }
            },
          ),
        ],
      ),
    );
  }
}
