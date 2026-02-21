import 'package:flutter/material.dart';

import '../../trackers/memory_tracker.dart';

/// Memory usage chart for the dashboard.
///
/// Displays current memory, peak memory, and a history chart.
class MemoryChart extends StatelessWidget {
  /// Creates a [MemoryChart].
  const MemoryChart({super.key, required this.memoryTracker});

  /// Memory tracker instance.
  final MemoryTracker memoryTracker;

  @override
  Widget build(BuildContext context) {
    final history = memoryTracker.memoryHistory;
    final currentMB = memoryTracker.currentUsageMB;
    final peakMB = memoryTracker.peakUsageMB;
    final isLeaking = memoryTracker.isLeaking;
    final undisposed = memoryTracker.undisposedItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Memory stats row
          Row(
            children: [
              _MemoryStat(
                label: 'Current',
                value:
                    currentMB > 0
                        ? '${currentMB.toStringAsFixed(1)} MB'
                        : 'N/A',
                color: _memColor(currentMB),
              ),
              const SizedBox(width: 12),
              _MemoryStat(
                label: 'Peak',
                value: peakMB > 0 ? '${peakMB.toStringAsFixed(1)} MB' : 'N/A',
                color: const Color(0xFFFFC107),
              ),
              const SizedBox(width: 12),
              _MemoryStat(
                label: 'Status',
                value: isLeaking ? '⚠ Leaking' : '✓ OK',
                color:
                    isLeaking
                        ? const Color(0xFFF44336)
                        : const Color(0xFF4CAF50),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Memory chart
          const Text(
            'Memory History',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0E1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2D2F4A), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                size: const Size(double.infinity, 70),
                painter: _MemoryChartPainter(
                  values: history,
                  isLeaking: isLeaking,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Undisposed items
          if (undisposed.isNotEmpty) ...[
            const Text(
              '⚠ Undisposed Resources',
              style: TextStyle(
                color: Color(0xFFF44336),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 4),
            ...undisposed.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      size: 12,
                      color: Color(0xFFF44336),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          decoration: TextDecoration.none,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (history.isEmpty && undisposed.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Memory tracking data will appear here.\n'
                  'Detailed memory metrics require profile/debug mode.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _memColor(double mb) {
    if (mb <= 0) return const Color(0xFF4CAF50);
    if (mb < 200) return const Color(0xFF4CAF50);
    if (mb < 400) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }
}

class _MemoryStat extends StatelessWidget {
  const _MemoryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0E1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryChartPainter extends CustomPainter {
  _MemoryChartPainter({required this.values, required this.isLeaking});

  final List<double> values;
  final bool isLeaking;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce((a, b) => a > b ? a : b).clamp(1.0, 2048.0);

    // Area fill
    final path = Path();
    path.moveTo(0, size.height);

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1).clamp(1, values.length)) * size.width;
      final y = size.height - (values[i] / maxVal * size.height * 0.9);
      if (i == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    final fillColor =
        isLeaking ? const Color(0xFFF44336) : const Color(0xFF6C63FF);

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fillColor.withAlpha(102), fillColor.withAlpha(13)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, fillPaint);

    // Line
    final linePath = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1).clamp(1, values.length)) * size.width;
      final y = size.height - (values[i] / maxVal * size.height * 0.9);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final linePaint =
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(_MemoryChartPainter oldDelegate) => true;
}
