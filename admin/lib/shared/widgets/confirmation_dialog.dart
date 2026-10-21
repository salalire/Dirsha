import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ConfirmationDialog extends StatefulWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.reasonFieldLabel,
    this.reasonRequired = false,
  });

  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final String? reasonFieldLabel;
  final bool reasonRequired;
  final Future<bool> Function(String? reason) onConfirm;

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _reasonError;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (widget.reasonRequired && _reasonController.text.trim().isEmpty) {
      setState(() => _reasonError = 'Please provide a reason.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _reasonError = null;
    });
    final reason =
        widget.reasonFieldLabel != null ? _reasonController.text.trim() : null;
    final success = await widget.onConfirm(reason);
    if (mounted) Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final confirmColor =
        widget.isDestructive ? AppColors.error : AppColors.primary;

    return AlertDialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(widget.title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cs.onSurface)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.content,
                style: TextStyle(
                    fontSize: 14, color: cs.onSurface.withAlpha(180))),
            if (widget.reasonFieldLabel != null) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _reasonController,
                enabled: !_isSubmitting,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: widget.reasonFieldLabel,
                  hintText: 'Enter reason…',
                  errorText: _reasonError,
                ),
                onChanged: (_) {
                  if (_reasonError != null) {
                    setState(() => _reasonError = null);
                  }
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleConfirm,
          style:
              ElevatedButton.styleFrom(backgroundColor: confirmColor),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.confirmLabel,
                  style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmLabel,
  required Future<bool> Function(String? reason) onConfirm,
  bool isDestructive = false,
  String? reasonFieldLabel,
  bool reasonRequired = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ConfirmationDialog(
      title: title,
      content: content,
      confirmLabel: confirmLabel,
      onConfirm: onConfirm,
      isDestructive: isDestructive,
      reasonFieldLabel: reasonFieldLabel,
      reasonRequired: reasonRequired,
    ),
  );
  return result ?? false;
}
