import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../models/audit_event.dart';
import '../providers/audit_provider.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  String? _outcomeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuditProvider>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditProvider>();
    final cs = Theme.of(context).colorScheme;
    final secondary = cs.onSurface.withAlpha(160);

    var events = provider.filteredEvents;
    if (_outcomeFilter != null && _outcomeFilter!.isNotEmpty) {
      events = events.where((e) => e.outcome.toLowerCase() == _outcomeFilter!.toLowerCase()).toList();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audit / Activity',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Immutable audit log permanently recorded in PostgreSQL (FR-ADM-02, FR-ADM-03)',
                      style: TextStyle(fontSize: 13, color: secondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () => context.read<AuditProvider>().loadEvents(action: provider.actionFilter),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => context.read<AuditProvider>().setSearchQuery(v),
                  decoration: const InputDecoration(
                    hintText: 'Search audit records by action, target, actor, or request ID…',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: provider.actionFilter,
                  hint: const Text('All Actions'),
                  borderRadius: BorderRadius.circular(8),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Actions')),
                    DropdownMenuItem(value: 'company.approve', child: Text('company.approve')),
                    DropdownMenuItem(value: 'broker.approve', child: Text('broker.approve')),
                    DropdownMenuItem(value: 'company.reject', child: Text('company.reject')),
                    DropdownMenuItem(value: 'broker.reject', child: Text('broker.reject')),
                    DropdownMenuItem(value: 'auth.login', child: Text('auth.login')),
                    DropdownMenuItem(value: 'ipo.approve', child: Text('ipo.approve')),
                    DropdownMenuItem(value: 'ipo.reject', child: Text('ipo.reject')),
                    DropdownMenuItem(value: 'user.verify', child: Text('user.verify')),
                  ],
                  onChanged: (v) => context.read<AuditProvider>().setActionFilter(v),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _outcomeFilter,
                  hint: const Text('All Outcomes'),
                  borderRadius: BorderRadius.circular(8),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Outcomes')),
                    DropdownMenuItem(value: 'success', child: Text('Success')),
                    DropdownMenuItem(value: 'failure', child: Text('Failure')),
                    DropdownMenuItem(value: 'denied', child: Text('Denied')),
                  ],
                  onChanged: (v) => setState(() => _outcomeFilter = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: provider.isLoading
                ? const LoadingIndicator(message: 'Loading audit trail from PostgreSQL…')
                : provider.errorMessage != null
                    ? ErrorState(
                        message: provider.errorMessage!,
                        onRetry: () => context.read<AuditProvider>().loadEvents(),
                      )
                    : events.isEmpty
                        ? EmptyState(
                            title: 'No audit records found',
                            subtitle: provider.searchQuery.isNotEmpty || provider.actionFilter != null || _outcomeFilter != null
                                ? 'Try adjusting your search query or filters.'
                                : 'No audit records have been generated yet.',
                            icon: Icons.history_outlined,
                          )
                        : _AuditTable(events: events),
          ),
        ],
      ),
    );
  }
}

class _AuditTable extends StatelessWidget {
  const _AuditTable({required this.events});
  final List<AuditEvent> events;

  String _fmt(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  void _showEventDetails(BuildContext context, AuditEvent ev) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security, size: 20),
            const SizedBox(width: 8),
            Text('Audit Event Details', style: TextStyle(fontSize: 18, color: cs.onSurface)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Event ID', ev.id),
                _detailRow('Timestamp', _fmt(ev.timestamp)),
                _detailRow('Action', ev.action),
                _detailRow('Outcome', ev.outcome),
                _detailRow('Actor Role', ev.actorRole),
                if (ev.actorId != null) _detailRow('Actor User ID', ev.actorId!),
                _detailRow('Target Resource', ev.targetResource),
                if (ev.referenceId != null) _detailRow('Correlation Request ID', ev.referenceId!),
                if (ev.metadata != null && ev.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withAlpha(120),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ev.metadata.toString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _actionColor(String action) {
    if (action.contains('approve') || action.contains('verify')) return AppColors.success;
    if (action.contains('reject')) return AppColors.error;
    if (action.contains('request')) return AppColors.primary;
    if (action.contains('login')) return const Color(0xFF6366F1);
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final cs = Theme.of(context).colorScheme;

    if (!isWide) {
      return ListView.separated(
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final ev = events[i];
          return Card(
            child: ListTile(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _actionColor(ev.action).withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _actionColor(ev.action).withAlpha(100)),
                    ),
                    child: Text(
                      ev.action,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _actionColor(ev.action),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _outcomeBadge(ev.outcome),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target: ${ev.targetResource}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmt(ev.timestamp)} • Actor: ${ev.actorRole}',
                      style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(160)),
                    ),
                  ],
                ),
              ),
              onTap: () => _showEventDetails(context, ev),
            ),
          );
        },
      );
    }

    return Card(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest),
            columns: const [
              DataColumn(label: Text('Timestamp')),
              DataColumn(label: Text('Action')),
              DataColumn(label: Text('Actor')),
              DataColumn(label: Text('Target Resource')),
              DataColumn(label: Text('Outcome')),
              DataColumn(label: Text('Request ID')),
              DataColumn(label: Text('')),
            ],
            rows: events.map((ev) {
              final color = _actionColor(ev.action);
              final reqId = ev.referenceId != null && ev.referenceId!.length > 8
                  ? '${ev.referenceId!.substring(0, 8)}…'
                  : (ev.referenceId ?? '—');

              return DataRow(
                cells: [
                  DataCell(Text(
                    _fmt(ev.timestamp),
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(200)),
                  )),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color.withAlpha(90)),
                      ),
                      child: Text(
                        ev.action,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                  ),
                  DataCell(Text(
                    ev.actorRole.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  )),
                  DataCell(
                    Tooltip(
                      message: ev.targetResource,
                      child: Text(
                        ev.targetResource.length > 32
                            ? '${ev.targetResource.substring(0, 32)}…'
                            : ev.targetResource,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                  DataCell(_outcomeBadge(ev.outcome)),
                  DataCell(
                    Tooltip(
                      message: ev.referenceId ?? 'N/A',
                      child: Text(
                        reqId,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: cs.onSurface.withAlpha(160),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 18),
                      tooltip: 'View Event Details',
                      onPressed: () => _showEventDetails(context, ev),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _outcomeBadge(String outcome) {
    final isSuccess = outcome.toLowerCase() == 'success';
    final color = isSuccess ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSuccess ? Icons.check : Icons.close, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            outcome.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
