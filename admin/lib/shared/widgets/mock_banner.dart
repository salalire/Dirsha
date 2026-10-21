import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A clearly visible banner shown at the top of pages that use mock data.
///
/// This ensures mock data is NEVER mistaken for real administrative records.
/// Must be shown on every screen backed by a mock repository.
class MockDataBanner extends StatelessWidget {
  const MockDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFEF3C7),
      child: const Row(
        children: [
          Icon(Icons.science_outlined, size: 16, color: Color(0xFF92400E)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'DEVELOPMENT MODE — All data on this page is mock/demo data. '
              'It does not represent real users, companies, or financial records.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Smaller inline mock label for cards and detail sections.
class MockLabel extends StatelessWidget {
  const MockLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: const Text(
        'DEMO DATA',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF92400E),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Compact banner for the top AppBar area
class MockModeBadge extends StatelessWidget {
  const MockModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.accent),
      ),
      child: const Text(
        'DEMO MODE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF92400E),
        ),
      ),
    );
  }
}
