import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Full-screen or centered loading state.
///
/// Use [LoadingIndicator.fullScreen] when loading replaces the entire page.
/// Use [LoadingIndicator.inline] for smaller sections within a page.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator.fullScreen({super.key, this.message})
    : _inline = false;

  const LoadingIndicator.inline({super.key, this.message}) : _inline = true;

  final String? message;
  final bool _inline;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.secondaryEmerald,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 14),
          Text(
            message!,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (_inline) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(24), child: content),
      );
    }

    return Center(child: content);
  }
}

/// A skeleton shimmer placeholder for list items while data loads.
/// Uses a simple animated opacity rather than a third-party shimmer
/// package to keep dependencies minimal.
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key, this.height = 100, this.borderRadius = 16});

  final double height;
  final double borderRadius;

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.cardSurfaceOf(context),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
      ),
    );
  }
}
