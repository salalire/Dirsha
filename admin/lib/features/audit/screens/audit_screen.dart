import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Audit / Activity placeholder screen.
/// PHASE 1 STATUS: Placeholder — /admin/audit endpoint not yet available.
/// BLOCKER: Member 2 (backend).
class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final secondary = cs.onSurface.withAlpha(160);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Audit / Activity',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          Text('Administrative activity log',
              style: TextStyle(fontSize: 14, color: secondary)),
          const SizedBox(height: 24),

          // Placeholder notice — amber on dark background, always legible
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3D2A00),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF92400E)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.construction_outlined,
                      color: Color(0xFFD4A72C), size: 20),
                  SizedBox(width: 8),
                  Text('PHASE 1 PLACEHOLDER',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD4A72C),
                          letterSpacing: 0.5)),
                ]),
                SizedBox(height: 12),
                Text(
                  'The audit log interface is under construction. '
                  'This page establishes the navigation structure for Phase 2 integration.',
                  style:
                      TextStyle(fontSize: 13, color: Color(0xFFBB8B3A)),
                ),
                SizedBox(height: 12),
                Text(
                  'Dependency: /admin/audit endpoint (Member 2 — Backend)',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFD4A72C),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text('Planned Audit Log Columns',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'When the /admin/audit endpoint is available, this page will display:',
                    style: TextStyle(fontSize: 13, color: secondary),
                  ),
                  const SizedBox(height: 16),
                  ..._plannedColumns.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Icon(Icons.check_box_outline_blank,
                              size: 16, color: cs.outline),
                          const SizedBox(width: 8),
                          Text(c,
                              style: TextStyle(
                                  fontSize: 13, color: cs.onSurface)),
                        ]),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text('Requirements Reference',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SrsRow(
                      id: 'FR-ADM-02',
                      text:
                          'Approval, rejection, suspension, and other privileged actions shall be audited.'),
                  _SrsRow(
                      id: 'FR-ADM-03',
                      text:
                          'Audit records shall include actor, action, target resource, timestamp, outcome, and reference ID.'),
                  _SrsRow(
                      id: 'FR-ADM-05',
                      text:
                          'The system shall avoid recording passwords, tokens, or unnecessary sensitive data in logs.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _plannedColumns = [
    'Event ID',
    'Actor role (e.g. admin)',
    'Action performed (e.g. IPO_APPROVED)',
    'Target resource (e.g. IPO ipo-001)',
    'Timestamp',
    'Outcome (success / failure)',
    'Reference / correlation ID',
  ];
}

class _SrsRow extends StatelessWidget {
  const _SrsRow({required this.id, required this.text});
  final String id;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.darkInfoBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(id,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF93C5FD))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: cs.onSurface)),
          ),
        ],
      ),
    );
  }
}
