import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../trackers/rebuild_tracker.dart';
import '../trackers/widget_depth_tracker.dart';
import '../trackers/widget_size_tracker.dart';
import '../trackers/heatmap_tracker.dart';

/// Wraps a specific widget to inspect its performance.
///
/// Provides detailed rebuild tracking and depth analysis for
/// the wrapped widget.
///
/// ```dart
/// PerformanceInspector(
///   name: "HomeScreen",
///   child: HomeScreen(),
/// );
/// ```
class PerformanceInspector extends StatefulWidget {
  /// Creates a [PerformanceInspector].
  const PerformanceInspector({
    super.key,
    required this.name,
    required this.child,
    this.enabled = true,
    this.showBadge = true,
    this.trackRebuilds = true,
    this.trackDepth = true,
    this.onRebuild,
  });

  /// Name identifier for this inspection point.
  final String name;

  /// The child widget to inspect.
  final Widget child;

  /// Whether inspection is enabled.
  final bool enabled;

  /// Whether to show a visual badge with rebuild count.
  final bool showBadge;

  /// Whether to track rebuilds.
  final bool trackRebuilds;

  /// Whether to track widget tree depth.
  final bool trackDepth;

  /// Callback fired on each rebuild.
  final void Function(int rebuildCount)? onRebuild;

  @override
  State<PerformanceInspector> createState() => _PerformanceInspectorState();
}

class _PerformanceInspectorState extends State<PerformanceInspector> {
  int _localRebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || kReleaseMode) {
      return widget.child;
    }

    _localRebuildCount++;

    // Track rebuild
    if (widget.trackRebuilds) {
      RebuildTracker.instance.trackRebuild(widget.name);
    }

    // Track depth, size and position on first build
    if (widget.trackDepth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          WidgetDepthTracker.instance.measureAt(context, widget.name);
          WidgetSizeTracker.instance.trackSize(widget.name, context);

          // Update heatmap position
          final RenderObject? renderObject = context.findRenderObject();
          if (renderObject is RenderBox) {
            final position = renderObject.localToGlobal(Offset.zero);
            final size = renderObject.size;
            HeatmapTracker.instance.updatePosition(
              widget.name,
              Rect.fromLTWH(position.dx, position.dy, size.width, size.height),
            );
          }
        }
      });
    }

    // Fire callback
    widget.onRebuild?.call(_localRebuildCount);

    if (widget.showBadge) {
      return Stack(
        children: [
          widget.child,
          Positioned(
            top: 0,
            right: 0,
            child: _InspectorBadge(
              name: widget.name,
              rebuildCount: _localRebuildCount,
            ),
          ),
        ],
      );
    }

    return widget.child;
  }
}

class _InspectorBadge extends StatelessWidget {
  const _InspectorBadge({required this.name, required this.rebuildCount});

  final String name;
  final int rebuildCount;

  @override
  Widget build(BuildContext context) {
    final color =
        rebuildCount > 50
            ? Colors.red
            : rebuildCount > 20
            ? Colors.orange
            : rebuildCount > 5
            ? Colors.yellow
            : Colors.green;

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$name: $rebuildCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
