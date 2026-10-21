import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/role_badge.dart';
import '../models/user_application.dart';
import '../providers/users_provider.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  String _searchQuery = '';
  UserApplicationStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().loadApplications();
    });
  }

  List<UserApplication> _filtered(List<UserApplication> all) {
    return all.where((u) {
      final matchesSearch = _searchQuery.isEmpty ||
          u.displayName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _filterStatus == null || u.status == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsersProvider>();
    final filtered = _filtered(provider.applications);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterBar(
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            filterStatus: _filterStatus,
            onFilterChanged: (v) => setState(() => _filterStatus = v),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.isLoading
                ? const LoadingIndicator(
                    message: 'Loading user applications…')
                : provider.errorMessage != null
                    ? ErrorState(
                        message: provider.errorMessage!,
                        onRetry: () => context
                            .read<UsersProvider>()
                            .loadApplications(),
                      )
                    : filtered.isEmpty
                        ? EmptyState(
                            title: 'No user applications found',
                            subtitle: _searchQuery.isNotEmpty ||
                                    _filterStatus != null
                                ? 'Try adjusting your search or filter.'
                                : 'No applications have been submitted yet.',
                            icon: Icons.people_outline,
                          )
                        : _UserTable(applications: filtered),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.onSearchChanged,
    required this.filterStatus,
    required this.onFilterChanged,
  });

  final ValueChanged<String> onSearchChanged;
  final UserApplicationStatus? filterStatus;
  final ValueChanged<UserApplicationStatus?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search by name, email or ID…',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButtonHideUnderline(
          child: DropdownButton<UserApplicationStatus?>(
            value: filterStatus,
            hint: const Text('All statuses'),
            borderRadius: BorderRadius.circular(8),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('All statuses')),
              ...UserApplicationStatus.values.map(
                (s) => DropdownMenuItem(value: s, child: Text(s.label)),
              ),
            ],
            onChanged: onFilterChanged,
          ),
        ),
      ],
    );
  }
}

class _UserTable extends StatelessWidget {
  const _UserTable({required this.applications});
  final List<UserApplication> applications;

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final cs = Theme.of(context).colorScheme;

    if (!isWide) {
      return ListView.separated(
        itemCount: applications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) =>
            _UserCard(application: applications[i]),
      );
    }

    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(cs.surfaceContainerHighest),
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Application Status')),
            DataColumn(label: Text('Submitted')),
            DataColumn(label: Text('')),
          ],
          rows: applications.map((u) {
            return DataRow(cells: [
              DataCell(Text(u.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(u.email,
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withAlpha(200)))),
              DataCell(RoleBadge(role: u.role)),
              DataCell(_statusBadge(u.status)),
              DataCell(Text(_fmtDate(u.submittedAt),
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(160)))),
              DataCell(TextButton(
                onPressed: () =>
                    context.go(AppRoutes.userDetailPath(u.id)),
                child: const Text('Review'),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _statusBadge(UserApplicationStatus status) {
    switch (status) {
      case UserApplicationStatus.pending:
        return StatusBadge.pending();
      case UserApplicationStatus.underReview:
        return StatusBadge.underReview();
      case UserApplicationStatus.approved:
        return StatusBadge.approved();
      case UserApplicationStatus.rejected:
        return StatusBadge.rejected();
      case UserApplicationStatus.suspended:
        return StatusBadge.suspended();
    }
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.application});
  final UserApplication application;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        title: Text(application.displayName,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(application.email,
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(160))),
            ),
            const SizedBox(width: 8),
            RoleBadge(role: application.role),
          ],
        ),
        trailing: _statusBadge(application.status),
        onTap: () =>
            context.go(AppRoutes.userDetailPath(application.id)),
      ),
    );
  }

  Widget _statusBadge(UserApplicationStatus status) {
    switch (status) {
      case UserApplicationStatus.pending:
        return StatusBadge.pending();
      case UserApplicationStatus.underReview:
        return StatusBadge.underReview();
      case UserApplicationStatus.approved:
        return StatusBadge.approved();
      case UserApplicationStatus.rejected:
        return StatusBadge.rejected();
      case UserApplicationStatus.suspended:
        return StatusBadge.suspended();
    }
  }
}
