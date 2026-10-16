import 'package:flutter/material.dart';

import '../design/app_colors.dart';

/// The AI WortBox mark: a book page dropping into the yellow vocabulary box,
/// with a small mint spark for the AI assistance. Decorative only.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _BrandMarkPainter(
            box: context.colors.box,
            ink: AppPalette.navy900,
            page: AppPalette.paper,
            spark: scheme.brightness == Brightness.light
                ? AppPalette.mintInk
                : AppPalette.mintBright,
          ),
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({
    required this.box,
    required this.ink,
    required this.page,
    required this.spark,
  });

  final Color box;
  final Color ink;
  final Color page;
  final Color spark;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round;

    // The page, tilted as if being dropped in.
    canvas.save();
    canvas.translate(s * 0.5, s * 0.36);
    canvas.rotate(-0.12);
    final pageRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s * 0.42, height: s * 0.5),
      Radius.circular(s * 0.04),
    );
    canvas.drawRRect(pageRect, Paint()..color = page);
    canvas.drawRRect(pageRect, stroke);
    for (final (dy, width) in [(-0.12, 0.24), (-0.03, 0.2), (0.06, 0.24)]) {
      canvas.drawLine(
        Offset(-s * width / 2, s * dy),
        Offset(s * width / 2, s * dy),
        stroke,
      );
    }
    canvas.restore();

    // The box.
    final body = RRect.fromRectAndCorners(
      Rect.fromLTRB(s * 0.12, s * 0.5, s * 0.88, s * 0.92),
      bottomLeft: Radius.circular(s * 0.1),
      bottomRight: Radius.circular(s * 0.1),
      topLeft: Radius.circular(s * 0.03),
      topRight: Radius.circular(s * 0.03),
    );
    canvas.drawRRect(body, Paint()..color = box);
    canvas.drawRRect(body, stroke);
    // The lid edge.
    canvas.drawLine(
      Offset(s * 0.06, s * 0.5),
      Offset(s * 0.94, s * 0.5),
      stroke..strokeWidth = s * 0.06,
    );

    // The spark.
    canvas.drawCircle(
      Offset(s * 0.84, s * 0.14),
      s * 0.06,
      Paint()..color = spark,
    );
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) =>
      oldDelegate.box != box ||
      oldDelegate.ink != ink ||
      oldDelegate.page != page ||
      oldDelegate.spark != spark;
}
