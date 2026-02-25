import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Performance history timeline chart.
class TimelineChart extends StatelessWidget {
  /// Creates a [TimelineChart].
  const TimelineChart({super.key, required this.history});

  /// The list of performance snapshots to display.
  final List<dynamic> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Text(
          'No history recorded yet.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FPS Trend (Last 100 snapshots)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0E1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2D2F4A)),
              ),
              child: CustomPaint(
                painter: _TimelinePainter(
                  data: history.map((s) => s.fps as double).toList(),
                  maxValue: 65,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Memory Trend (MB)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0E1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2D2F4A)),
              ),
              child: CustomPaint(
                painter: _TimelinePainter(
                  data: history.map((s) => s.memoryUsageMB as double).toList(),
                  maxValue: 1000,
                  color: const Color(0xFF2196F3),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Snapshots: ${history.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
                const Text(
                  'Scale: Auto',
                  style: TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.data,
    required this.maxValue,
    required this.color,
  });

  final List<double> data;
  final double maxValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Draw grid lines
    final gridPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      // Label for Y axis
      final labelValue = scaleMax * (1 - i / 4);
      final tp = TextPainter(
        text: TextSpan(
          text: labelValue.toStringAsFixed(0),
          style: const TextStyle(color: Colors.white24, fontSize: 7),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - 8));
    }

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

    final path = Path();
    final xStep = size.width / (data.length > 1 ? data.length - 1 : 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final normalizedValue = (data[i] / scaleMax).clamp(0.0, 1.0);
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Gradient fill
    canvas.drawPath(path, paint);

    final fillPath =
        Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  double get actualMax => data.isNotEmpty ? data.reduce(math.max) : maxValue;
  double get scaleMax => math.max(maxValue, actualMax * 1.1);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
