import 'package:flutter/material.dart';
import '../trackers/heatmap_tracker.dart';
import '../trackers/rebuild_tracker.dart';

/// Overlay that visualizes a heatmap of widget rebuilds.
class HeatmapOverlay extends StatefulWidget {
  /// Creates a [HeatmapOverlay].
  const HeatmapOverlay({super.key});

  @override
  State<HeatmapOverlay> createState() => _HeatmapOverlayState();
}

class _HeatmapOverlayState extends State<HeatmapOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final positions = HeatmapTracker.instance.positions;
        final rebuilds = RebuildTracker.instance.rebuildCounts;

        return IgnorePointer(
          child: Stack(
            children:
                positions.entries.map((entry) {
                  final name = entry.key;
                  final rect = entry.value;
                  final count = rebuilds[name] ?? 0;

                  if (count == 0) return const SizedBox.shrink();

                  // Calculate intensity based on count (log scale)
                  final intensity = (count / 50).clamp(0.0, 1.0);
                  final color =
                      Color.lerp(
                        Colors.green.withValues(alpha: 0.2),
                        Colors.red.withValues(alpha: 0.6),
                        intensity,
                      )!;

                  return Positioned(
                    left: rect.left,
                    top: rect.top,
                    width: rect.width,
                    height: rect.height,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: color.withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }
}
