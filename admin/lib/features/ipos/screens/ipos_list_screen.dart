import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/ipo_application.dart';
import '../providers/ipos_provider.dart';

class IposListScreen extends StatefulWidget {
  const IposListScreen({super.key});

  @override
  State<IposListScreen> createState() => _IposListScreenState();
}

class _IposListScreenState extends State<IposListScreen> {
  String _searchQuery = '';
  IpoStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IposProvider>().loadApplications();
    });
  }

  List<IpoApplication> _filtered(List<IpoApplication> all) {
    return all.where((i) {
      final matchesSearch = _searchQuery.isEmpty ||
          i.offeringTitle
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          i.companyName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          i.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _filterStatus == null || i.status == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IposProvider>();
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
                    hintText: 'Search by title, company or ID…',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<IpoStatus?>(
                  value: _filterStatus,
                  hint: const Text('All statuses'),
                  borderRadius: BorderRadius.circular(8),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All statuses')),
                    ...IpoStatus.values.map(
                      (s) => DropdownMenuItem(
                          value: s, child: Text(s.label)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filterStatus = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () =>
                    context.read<IposProvider>().loadApplications(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.isLoading
                ? const LoadingIndicator(
                    message: 'Loading IPO applications…')
                : provider.errorMessage != null
                    ? ErrorState(
                        message: provider.errorMessage!,
                        onRetry: () =>
                            context.read<IposProvider>().loadApplications(),
                      )
                    : filtered.isEmpty
                        ? EmptyState(
                            title: 'No IPO applications found',
                            subtitle: _searchQuery.isNotEmpty ||
                                    _filterStatus != null
                                ? 'Try adjusting your search or filter.'
                                : 'No IPO applications have been submitted yet.',
                            icon: Icons.bar_chart_outlined,
                          )
                        : _IpoTable(applications: filtered),
          ),
        ],
      ),
    );
  }
}

class _IpoTable extends StatelessWidget {
  const _IpoTable({required this.applications});
  final List<IpoApplication> applications;

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final cs = Theme.of(context).colorScheme;

    if (!isWide) {
      return ListView.separated(
        itemCount: applications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) =>
            _IpoCard(application: applications[i]),
      );
    }

    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(cs.surfaceContainerHighest),
          columns: const [
            DataColumn(label: Text('Offering Title')),
            DataColumn(label: Text('Company')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Submitted')),
            DataColumn(label: Text('')),
          ],
          rows: applications.map((ipo) {
            return DataRow(cells: [
              DataCell(ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(ipo.offeringTitle,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              )),
              DataCell(Text(ipo.companyName,
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withAlpha(200)))),
              DataCell(_statusBadge(ipo.status)),
              DataCell(Text(_fmt(ipo.submittedAt),
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(160)))),
              DataCell(TextButton(
                onPressed: () =>
                    context.go(AppRoutes.ipoDetailPath(ipo.id)),
                child: const Text('Review'),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _statusBadge(IpoStatus s) {
    switch (s) {
      case IpoStatus.submitted:
      case IpoStatus.underReview:
        return StatusBadge.underReview();
      case IpoStatus.approved:
        return StatusBadge.approved();
      case IpoStatus.rejected:
        return StatusBadge.rejected();
      case IpoStatus.open:
        return StatusBadge.open();
      case IpoStatus.closed:
        return StatusBadge.closed();
      default:
        return StatusBadge.fromLabel(s.label);
    }
  }
}

class _IpoCard extends StatelessWidget {
  const _IpoCard({required this.application});
  final IpoApplication application;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        title: Text(application.offeringTitle,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(application.companyName,
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withAlpha(160))),
        trailing: _statusBadge(application.status),
        onTap: () => context.go(AppRoutes.ipoDetailPath(application.id)),
      ),
    );
  }

  Widget _statusBadge(IpoStatus s) {
    switch (s) {
      case IpoStatus.approved:
        return StatusBadge.approved();
      case IpoStatus.rejected:
        return StatusBadge.rejected();
      case IpoStatus.open:
        return StatusBadge.open();
      default:
        return StatusBadge.fromLabel(s.label);
    }
  }
}
