import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/company_application.dart';
import '../providers/companies_provider.dart';

class CompaniesListScreen extends StatefulWidget {
  const CompaniesListScreen({super.key});

  @override
  State<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends State<CompaniesListScreen> {
  String _searchQuery = '';
  CompanyApplicationStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompaniesProvider>().loadApplications();
    });
  }

  List<CompanyApplication> _filtered(List<CompanyApplication> all) {
    return all.where((c) {
      final matchesSearch = _searchQuery.isEmpty ||
          c.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.representativeName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          c.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _filterStatus == null || c.status == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompaniesProvider>();
    final filtered = _filtered(provider.applications);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: 'Search by company name, representative or ID…',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<CompanyApplicationStatus?>(
                  value: _filterStatus,
                  hint: const Text('All statuses'),
                  borderRadius: BorderRadius.circular(8),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All statuses')),
                    ...CompanyApplicationStatus.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filterStatus = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.isLoading
                ? const LoadingIndicator(message: 'Loading company applications…')
                : provider.errorMessage != null
                    ? ErrorState(
                        message: provider.errorMessage!,
                        onRetry: () =>
                            context.read<CompaniesProvider>().loadApplications(),
                      )
                    : filtered.isEmpty
                        ? EmptyState(
                            title: 'No company applications found',
                            subtitle: _searchQuery.isNotEmpty ||
                                    _filterStatus != null
                                ? 'Try adjusting your search or filter.'
                                : 'No company applications have been submitted yet.',
                            icon: Icons.business_outlined,
                          )
                        : _CompanyTable(applications: filtered),
          ),
        ],
      ),
    );
  }
}

class _CompanyTable extends StatelessWidget {
  const _CompanyTable({required this.applications});
  final List<CompanyApplication> applications;

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 750;
    final cs = Theme.of(context).colorScheme;

    if (!isWide) {
      return ListView.separated(
        itemCount: applications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) =>
            _CompanyCard(application: applications[i]),
      );
    }

    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(cs.surfaceContainerHighest),
          columns: const [
            DataColumn(label: Text('Company')),
            DataColumn(label: Text('Representative')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Submitted')),
            DataColumn(label: Text('Docs')),
            DataColumn(label: Text('')),
          ],
          rows: applications.map((c) {
            return DataRow(cells: [
              DataCell(Text(c.companyName,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(c.representativeName,
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurface.withAlpha(200)))),
              DataCell(_statusBadge(c.status)),
              DataCell(Text(_fmt(c.submittedAt),
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withAlpha(160)))),
              DataCell(Text('${c.documents.length}',
                  style: const TextStyle(fontSize: 13))),
              DataCell(TextButton(
                onPressed: () =>
                    context.go(AppRoutes.companyDetailPath(c.id)),
                child: const Text('Review'),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _statusBadge(CompanyApplicationStatus s) {
    switch (s) {
      case CompanyApplicationStatus.pending:
        return StatusBadge.pending();
      case CompanyApplicationStatus.underReview:
        return StatusBadge.underReview();
      case CompanyApplicationStatus.additionalInfoRequired:
        return StatusBadge.additionalInfoRequired();
      case CompanyApplicationStatus.approved:
        return StatusBadge.approved();
      case CompanyApplicationStatus.rejected:
        return StatusBadge.rejected();
      case CompanyApplicationStatus.suspended:
        return StatusBadge.suspended();
    }
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.application});
  final CompanyApplication application;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        title: Text(application.companyName,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(application.representativeName,
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withAlpha(160))),
        trailing: _statusBadge(application.status),
        onTap: () =>
            context.go(AppRoutes.companyDetailPath(application.id)),
      ),
    );
  }

  Widget _statusBadge(CompanyApplicationStatus s) {
    switch (s) {
      case CompanyApplicationStatus.pending:
        return StatusBadge.pending();
      case CompanyApplicationStatus.underReview:
        return StatusBadge.underReview();
      case CompanyApplicationStatus.additionalInfoRequired:
        return StatusBadge.additionalInfoRequired();
      case CompanyApplicationStatus.approved:
        return StatusBadge.approved();
      case CompanyApplicationStatus.rejected:
        return StatusBadge.rejected();
      case CompanyApplicationStatus.suspended:
        return StatusBadge.suspended();
    }
  }
}
