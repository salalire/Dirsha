import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!,
                style: TextStyle(color: cs.onSurface.withAlpha(160), fontSize: 14)),
          ],
        ],
      ),
    );
  }
}
