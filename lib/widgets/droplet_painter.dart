import 'package:flutter/material.dart';
import 'dart:math';

class DropletPainter extends CustomPainter {
  final double fillPercent;
  final double wavePhase;

  DropletPainter({required this.fillPercent, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Gradient fill
    final Paint dropPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    // Fatter symmetrical droplet
    Path dropletPath = Path();
    dropletPath.moveTo(width / 2, 0);
    dropletPath.cubicTo(
      -width * 0.3, height * 0.45,
      -width * 0.05, height * 0.95,
      width / 2, height,
    );
    dropletPath.cubicTo(
      width * 1.05, height * 0.95,
      width * 1.3, height * 0.45,
      width / 2, 0,
    );
    dropletPath.close();

    canvas.drawPath(dropletPath, dropPaint);
    canvas.save();
    canvas.clipPath(dropletPath);

    // Wavy fill animation
    final wavePaint = Paint()..color = Colors.blueAccent.withOpacity(0.4);
    final wavePaint2 = Paint()..color = Colors.blue.shade200.withOpacity(0.5);
    final waveHeight = 10.0;
    final baseHeight = height * (1 - fillPercent);

    Path wavePath(double offset, double shift) {
      final path = Path();
      path.moveTo(0, baseHeight);
      for (double x = 0; x <= width; x++) {
        final y = sin((x / width * 2 * pi) + offset) * waveHeight + baseHeight + shift;
        path.lineTo(x, y);
      }
      path.lineTo(width, height);
      path.lineTo(0, height);
      path.close();
      return path;
    }

    canvas.drawPath(wavePath(wavePhase, 0), wavePaint);
    canvas.drawPath(wavePath(wavePhase + pi, -4), wavePaint2);
    canvas.restore();

    // Text inside droplet
    final percent = (fillPercent * 100).clamp(0, 100).toInt();
    final ml = (fillPercent * 4000).toInt();

    final TextSpan span = TextSpan(
      text: "$ml ML\n$percent%",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    );
    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset((width - tp.width) / 2, height * 0.4));

    // Glowing icon bubble
    final iconOffset = Offset(width * 0.78, height * 0.22);
    final iconCircleSize = 30.0;

    // Glow background
    canvas.drawCircle(
      iconOffset,
      iconCircleSize / 2,
      Paint()
        ..color = Colors.blueAccent.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Inner circle
    canvas.drawCircle(
      iconOffset,
      iconCircleSize / 2.5,
      Paint()..color = Colors.white.withOpacity(0.4),
    );

    // Icon
    final icon = Icons.local_drink;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 16,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      iconOffset - Offset(iconPainter.width / 2, iconPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}