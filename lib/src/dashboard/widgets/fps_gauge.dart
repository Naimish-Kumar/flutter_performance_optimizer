import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../trackers/frame_tracker.dart';
import '../../trackers/profiling_tracker.dart';

/// FPS gauge and frame timeline visualization.
///
/// Shows current FPS, frame time graph, and jank indicators.
class FpsGauge extends StatelessWidget {
  /// Creates a [FpsGauge].
  const FpsGauge({super.key, required this.fps, required this.frameTracker});

  /// Current FPS.
  final double fps;

  /// Frame tracker instance.
  final FrameTracker frameTracker;

  @override
  Widget build(BuildContext context) {
    final frameTimes = frameTracker.frameTimeHistory;
    final buildTimeMs = frameTracker.averageBuildTime.inMicroseconds / 1000.0;
    final rasterTimeMs = frameTracker.averageRasterTime.inMicroseconds / 1000.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FPS Arc Gauge
          Center(
            child: SizedBox(
              width: 120,
              height: 80,
              child: CustomPaint(painter: _FpsArcPainter(fps: fps)),
            ),
          ),
          const SizedBox(height: 8),

          // Build & Raster times
          Row(
            children: [
              Expanded(
                child: _TimingRow(
                  label: 'Build',
                  value: '${buildTimeMs.toStringAsFixed(2)}ms',
                  color:
                      buildTimeMs < 8
                          ? const Color(0xFF4CAF50)
                          : buildTimeMs < 16
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFF44336),
                ),
              ),
              Expanded(
                child: _TimingRow(
                  label: 'Raster',
                  value: '${rasterTimeMs.toStringAsFixed(2)}ms',
                  color:
                      rasterTimeMs < 8
                          ? const Color(0xFF4CAF50)
                          : rasterTimeMs < 16
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFF44336),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _TimingRow(
            label: 'Jank Frames',
            value: '${frameTracker.jankFrameCount}',
            color:
                frameTracker.isJanking
                    ? const Color(0xFFF44336)
                    : const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 8),

          // CPU / GPU Load
          const Text(
            'System Load',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _LoadIndicator(
                  label: 'CPU',
                  value: ProfilingTracker.instance.estimatedCpuLoad,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LoadIndicator(
                  label: 'GPU',
                  value: ProfilingTracker.instance.estimatedGpuLoad,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Frame timeline
          const Text(
            'Frame Timeline',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0E1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2D2F4A), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                size: const Size(double.infinity, 60),
                painter: _FrameTimelinePainter(frameTimes: frameTimes),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${frameTimes.length} frames',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  decoration: TextDecoration.none,
                ),
              ),
              const Text(
                '— 16ms threshold',
                style: TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 9,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  const _TimingRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _FpsArcPainter extends CustomPainter {
  _FpsArcPainter({required this.fps});

  final double fps;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    // Background arc
    final bgPaint =
        Paint()
          ..color = const Color(0xFF2D2F4A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Value arc
    final fpsNormalized = (fps / 60).clamp(0.0, 1.0);
    final color =
        fps >= 55
            ? const Color(0xFF4CAF50)
            : fps >= 40
            ? const Color(0xFFFFC107)
            : const Color(0xFFF44336);

    final valuePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * fpsNormalized,
      false,
      valuePaint,
    );

    // FPS text
    final textPainter = TextPainter(
      text: TextSpan(
        text: fps.toStringAsFixed(0),
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - 32),
    );

    // Label
    final labelPainter = TextPainter(
      text: const TextSpan(
        text: 'FPS',
        style: TextStyle(color: Colors.white38, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, center.dy - 12),
    );
  }

  @override
  bool shouldRepaint(_FpsArcPainter oldDelegate) => oldDelegate.fps != fps;
}

class _FrameTimelinePainter extends CustomPainter {
  _FrameTimelinePainter({required this.frameTimes});

  final List<double> frameTimes;

  @override
  void paint(Canvas canvas, Size size) {
    if (frameTimes.isEmpty) return;

    // Threshold line at 16ms
    final thresholdY = size.height * (1 - 16 / 50); // Scale to 50ms max
    final thresholdPaint =
        Paint()
          ..color = const Color(0xFFFFC107).withAlpha(77)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, thresholdY),
      Offset(size.width, thresholdY),
      thresholdPaint,
    );

    // Frame bars
    final barWidth = size.width / frameTimes.length.clamp(1, 100);
    for (int i = 0; i < frameTimes.length && i < 100; i++) {
      final ms = frameTimes[i];
      final height = (ms / 50 * size.height).clamp(1.0, size.height);
      final color =
          ms <= 16
              ? const Color(0xFF4CAF50)
              : ms <= 33
              ? const Color(0xFFFFC107)
              : const Color(0xFFF44336);

      final paint = Paint()..color = color.withAlpha(179);
      canvas.drawRect(
        Rect.fromLTWH(
          i * barWidth,
          size.height - height,
          barWidth * 0.8,
          height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_FrameTimelinePainter oldDelegate) => true;
}

class _LoadIndicator extends StatelessWidget {
  const _LoadIndicator({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final color =
        value < 50
            ? const Color(0xFF4CAF50)
            : value < 80
            ? const Color(0xFFFFC107)
            : const Color(0xFFF44336);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0E1A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2D2F4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 8),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (value / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${value.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
