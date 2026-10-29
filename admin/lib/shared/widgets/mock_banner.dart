import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';

/// A clearly visible banner shown at the top of pages that use mock data.
///
/// This ensures mock data is NEVER mistaken for real administrative records.
/// Must be shown on every screen backed by a mock repository.
class MockDataBanner extends StatelessWidget {
  const MockDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Smaller inline mock label for cards and detail sections.
class MockLabel extends StatelessWidget {
  const MockLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Compact banner for the top AppBar area
class MockModeBadge extends StatelessWidget {
  const MockModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

