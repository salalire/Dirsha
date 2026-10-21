import 'package:flutter/material.dart';

class PermissionDeniedState extends StatelessWidget {
  const PermissionDeniedState({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final secondary = cs.onSurface.withAlpha(160);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: secondary),
            const SizedBox(height: 16),
            Text('Access Denied',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              message ??
                  'You do not have permission to view this resource.\n'
                      'Contact your system administrator if you believe this is an error.',
              style: TextStyle(fontSize: 14, color: secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
