import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/broker_application.dart';
import '../providers/brokers_provider.dart';

class BrokersListScreen extends StatefulWidget {
  const BrokersListScreen({super.key});

  @override
  State<BrokersListScreen> createState() => _BrokersListScreenState();
}

class _BrokersListScreenState extends State<BrokersListScreen> {
  String _searchQuery = '';
  BrokerApplicationStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrokersProvider>().loadApplications();
    });
  }

  List<BrokerApplication> _filtered(List<BrokerApplication> all) {
    return all.where((b) {
      final matchesSearch = _searchQuery.isEmpty ||
          b.applicantName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (b.firmName != null &&
              b.firmName!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          b.licenseNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _filterStatus == null || b.status == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrokersProvider>();
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
                    hintText: 'Search by broker name, firm, license or ID…',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<BrokerApplicationStatus?>(
                  value: _filterStatus,
                  hint: const Text('All statuses'),
                  borderRadius: BorderRadius.circular(8),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All statuses')),
                    ...BrokerApplicationStatus.values.map(
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
                ? const LoadingIndicator(message: 'Loading broker applications…')
                : provider.errorMessage != null
                    ? ErrorState(
                        message: provider.errorMessage!,
                        onRetry: () =>
                            context.read<BrokersProvider>().loadApplications(),
                      )
                    : filtered.isEmpty
                        ? EmptyState(
                            title: 'No broker applications found',
                            subtitle: _searchQuery.isNotEmpty ||
                                    _filterStatus != null
                                ? 'Try adjusting your search or filter.'
                                : 'No broker applications have been submitted yet.',
                            icon: Icons.handshake_outlined,
                          )
                        : _BrokerTable(applications: filtered),
          ),
        ],
      ),
    );
  }
}

class _BrokerTable extends StatelessWidget {
  const _BrokerTable({required this.applications});
  final List<BrokerApplication> applications;

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
            _BrokerCard(application: applications[i]),
      );
    }

    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(cs.surfaceContainerHighest),
          columns: const [
            DataColumn(label: Text('Broker / Firm')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('License #')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Submitted')),
            DataColumn(label: Text('Docs')),
            DataColumn(label: Text('')),
          ],
          rows: applications.map((b) {
            return DataRow(cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      b.brokerType == 'firm' && b.firmName != null
                          ? b.firmName!
                          : b.applicantName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (b.brokerType == 'firm' && b.applicantName.isNotEmpty)
                      Text('Rep: ${b.applicantName}',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withAlpha(150))),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    b.brokerType.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(b.licenseNumber,
                        style: const TextStyle(fontSize: 12)),
                    if (b.isLicenseExpired) ...[
                      const SizedBox(width: 4),
                      const Tooltip(
                        message: 'License is expired!',
                        child: Icon(Icons.warning_amber_rounded,
                            size: 16, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ],
                ),
              ),
              DataCell(_statusBadge(b.status)),
              DataCell(Text(_fmt(b.submittedAt),
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withAlpha(160)))),
              DataCell(Text('${b.documents.length}',
                  style: const TextStyle(fontSize: 13))),
              DataCell(TextButton(
                onPressed: () =>
                    context.go(AppRoutes.brokerDetailPath(b.id)),
                child: const Text('Review'),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _statusBadge(BrokerApplicationStatus s) {
    switch (s) {
      case BrokerApplicationStatus.pending:
        return StatusBadge.pending();
      case BrokerApplicationStatus.underReview:
        return StatusBadge.underReview();
      case BrokerApplicationStatus.additionalInfoRequired:
        return StatusBadge.additionalInfoRequired();
      case BrokerApplicationStatus.approved:
        return StatusBadge.approved();
      case BrokerApplicationStatus.rejected:
        return StatusBadge.rejected();
    }
  }
}

class _BrokerCard extends StatelessWidget {
  const _BrokerCard({required this.application});
  final BrokerApplication application;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        title: Text(
            application.brokerType == 'firm' && application.firmName != null
                ? application.firmName!
                : application.applicantName,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
            'License: ${application.licenseNumber} • ${application.brokerType.toUpperCase()}',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withAlpha(160))),
        trailing: _statusBadge(application.status),
        onTap: () =>
            context.go(AppRoutes.brokerDetailPath(application.id)),
      ),
    );
  }

  Widget _statusBadge(BrokerApplicationStatus s) {
    switch (s) {
      case BrokerApplicationStatus.pending:
        return StatusBadge.pending();
      case BrokerApplicationStatus.underReview:
        return StatusBadge.underReview();
      case BrokerApplicationStatus.additionalInfoRequired:
        return StatusBadge.additionalInfoRequired();
      case BrokerApplicationStatus.approved:
        return StatusBadge.approved();
      case BrokerApplicationStatus.rejected:
        return StatusBadge.rejected();
    }
  }
}
