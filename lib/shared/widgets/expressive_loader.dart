import 'dart:math' as math;
import 'package:flutter/material.dart';

class ExpressiveLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const ExpressiveLoader({
    super.key,
    this.size = 48.0,
    this.color,
    this.strokeWidth = 4.0,
  });

  @override
  State<ExpressiveLoader> createState() => _ExpressiveLoaderState();
}

class _ExpressiveLoaderState extends State<ExpressiveLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 2.5 seconds for a smooth, unhurried, expressive loop
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defaults to the onSurface color (Black in light mode, White in dark mode)
    final themeColor = widget.color ?? Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ExpressiveLoaderPainter(
              progress: _controller.value,
              color: themeColor,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _ExpressiveLoaderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ExpressiveLoaderPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // The maximum height of the wave peaks
    final maxAmplitude = size.width * 0.12;
    final baseRadius = (size.width / 2) - maxAmplitude - (strokeWidth / 2);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // High number of points for ultra-smooth rendering at 60fps
    const numPoints = 120;
    
    // Number of zigzag/waves around the circle (classic M3 uses 6 or 7)
    const numWaves = 7;
    
    // Global rotation to make the entire shape spin with classic M3 easing.
    // The rotation velocity accelerates and decelerates smoothly.
    // We use a math trick: progress - sin(progress * 2PI) to create pauses.
    final easedProgress = progress - (0.8 / (2 * math.pi)) * math.sin(2 * math.pi * progress);
    final globalRotation = easedProgress * 2 * math.pi;
    
    // Morphing factor to make the shape breathe playfully
    // When the shape slows down (progress = 0 or 1), morph is 1.0 (highly wavy).
    // When it speeds up (progress = 0.5), morph is 0.0 (smooth circle).
    final morphFactor = 0.5 + 0.5 * math.cos(progress * 2 * math.pi);
    
    // The wave amplitude oscillates perfectly between a circle (0) and maximum wave
    final currentAmplitude = maxAmplitude * morphFactor;

    for (int i = 0; i <= numPoints; i++) {
      final theta = (i / numPoints) * 2 * math.pi;
      
      // In true M3 expressive style, the shape itself is a rigid morphing polygon.
      // The waves do NOT travel along the path; the whole path rotates.
      final waveOffset = currentAmplitude * math.sin(numWaves * theta);
      
      final r = baseRadius + waveOffset;
      
      final x = center.dx + r * math.cos(theta + globalRotation);
      final y = center.dy + r * math.sin(theta + globalRotation);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ExpressiveLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
