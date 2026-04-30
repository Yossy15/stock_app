import 'dart:math';
import 'package:flutter/material.dart';

class CustomTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final random = Random(42); // Seed for consistent texture

    // Draw random geometric shapes as texture
    for (var i = 0; i < 20; i++) {
      final center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = random.nextDouble() * 100 + 50;
      
      if (random.nextBool()) {
        canvas.drawCircle(center, radius, paint);
      } else {
        final rect = Rect.fromCenter(
          center: center,
          width: radius * 1.5,
          height: radius * 1.5,
        );
        canvas.drawRect(rect, paint);
      }
    }

    // Draw some subtle lines
    final linePaint = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.02)
      ..strokeWidth = 1;

    for (var i = 0; i < 10; i++) {
      canvas.drawLine(
        Offset(0, random.nextDouble() * size.height),
        Offset(size.width, random.nextDouble() * size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomTexturePainter oldDelegate) => false;
}
