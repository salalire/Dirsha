import 'package:flutter/material.dart';
import 'dart:math' as math;

/// The Dirsha logo — a deep-green rounded square containing a white
/// trending-up stock chart arrow, matching the official brand image.
///
/// Use [DirshaLogo] anywhere the logo is needed.
/// The [size] parameter controls the width/height of the square.
class DirshaLogo extends StatelessWidget {
  const DirshaLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Deep Emerald — same as the brand image
        color: const Color(0xFF064E3B),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.18),
        child: CustomPaint(
          painter: _TrendingArrowPainter(),
        ),
      ),
    );
  }
}

/// Draws the white trending-up arrow exactly as in the Dirsha brand:
/// - A zigzag line that goes down then sharply up-right
/// - An arrowhead pointing upper-right at the end
class _TrendingArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // ── Trending line path ─────────────────────────────────────────────────
    // Start bottom-left, dip slightly, then surge up to top-right
    final linePath = Path()
      ..moveTo(w * 0.0, h * 0.72)         // start: bottom-left
      ..lineTo(w * 0.28, h * 0.85)        // small dip
      ..lineTo(w * 0.55, h * 0.42)        // mid surge
      ..lineTo(w * 0.78, h * 0.58)        // small pullback
      ..lineTo(w * 1.0, h * 0.15);        // end: top-right (arrow tip)

    canvas.drawPath(linePath, paint);

    // ── Arrowhead at top-right ─────────────────────────────────────────────
    final tipX = w * 1.0;
    final tipY = h * 0.15;

    // Arrow direction angle: pointing upper-right (~45° from horizontal)
    const angle = -math.pi / 4; // -45°
    final arrowLen = w * 0.28;
    const spread = math.pi / 5; // 36° spread between wings

    final arrow = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Left wing of arrowhead
    canvas.drawLine(
      Offset(tipX, tipY),
      Offset(
        tipX + arrowLen * math.cos(angle + math.pi - spread),
        tipY + arrowLen * math.sin(angle + math.pi - spread),
      ),
      arrow,
    );
    // Right wing of arrowhead
    canvas.drawLine(
      Offset(tipX, tipY),
      Offset(
        tipX + arrowLen * math.cos(angle + math.pi + spread),
        tipY + arrowLen * math.sin(angle + math.pi + spread),
      ),
      arrow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Inline logo + wordmark row — used in the sign-in screen and sidebar.
class DirshaLogoWithText extends StatelessWidget {
  const DirshaLogoWithText({
    super.key,
    this.logoSize = 48,
    this.textColor = Colors.white,
    this.subtitleColor,
    this.subtitle,
  });

  final double logoSize;
  final Color textColor;
  final Color? subtitleColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DirshaLogo(size: logoSize),
        const SizedBox(width: 14),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dirsha',
              style: TextStyle(
                color: textColor,
                fontSize: logoSize * 0.52,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: subtitleColor ?? textColor.withAlpha(160),
                  fontSize: logoSize * 0.26,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
