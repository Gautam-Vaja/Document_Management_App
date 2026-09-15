import 'package:flutter/material.dart';

class ScannerFramePainter extends CustomPainter {
  final double? scanProgress;
  final bool showGrid;

  ScannerFramePainter({this.scanProgress, this.showGrid = false});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw 3x3 alignment grid if enabled
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      final oneThirdX = size.width / 3;
      final twoThirdsX = size.width * 2 / 3;
      final oneThirdY = size.height / 3;
      final twoThirdsY = size.height * 2 / 3;

      canvas.drawLine(
        Offset(oneThirdX, 0),
        Offset(oneThirdX, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(twoThirdsX, 0),
        Offset(twoThirdsX, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, oneThirdY),
        Offset(size.width, oneThirdY),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, twoThirdsY),
        Offset(size.width, twoThirdsY),
        gridPaint,
      );
    }

    // 2. Corner brackets
    final paint = Paint()
      ..color = const Color(0xFF58F5B0)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double corner = 28;

    // Top-left
    canvas.drawLine(const Offset(0, corner), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(corner, 0), paint);

    // Top-right
    canvas.drawLine(
      Offset(size.width - corner, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, corner), paint);

    // Bottom-left
    canvas.drawLine(
      Offset(0, size.height - corner),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(Offset(0, size.height), Offset(corner, size.height), paint);

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - corner, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - corner),
      Offset(size.width, size.height),
      paint,
    );

    // 3. Scanning Laser Line
    if (scanProgress != null) {
      final y = size.height * scanProgress!;

      // Laser beam gradient
      final linePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF58F5B0).withValues(alpha: 0.0),
            const Color(0xFF58F5B0).withValues(alpha: 0.9),
            const Color(0xFF58F5B0).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, y - 2, size.width, 4))
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), linePaint);

      // Laser glow trail
      final glowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF58F5B0).withValues(alpha: 0.25),
            const Color(0xFF58F5B0).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, y - 24, size.width, 24))
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(10, y - 24, size.width - 20, 24),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScannerFramePainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.showGrid != showGrid;
  }
}
