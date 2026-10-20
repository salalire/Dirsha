import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Visible banner shown at the top of a screen when mock data is active.
///
/// This ensures that development mock data is NEVER mistaken for real
/// live API data. Only rendered when [AppConfig.useMockRepositories] is
/// true and the environment is not production.
///
/// The banner must be removed (by connecting the real API) — not hidden —
/// before any screen is considered ready for production use.
class MockDataBanner extends StatelessWidget {
  const MockDataBanner({super.key, this.detail});

  /// Optional detail describing what is mocked on this specific screen.
  final String? detail;

  /// Returns null in production. Wrap usage in a null check or use
  /// [MockDataBanner.maybeWrap].
  static Widget? maybeWrap({String? detail}) {
    if (AppConfig.isProduction || !AppConfig.useMockRepositories) return null;
    return MockDataBanner(detail: detail);
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.isProduction) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.warningSurface,
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail != null
                  ? 'MOCK DATA — $detail'
                  : 'MOCK DATA — Not connected to live API',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
