import 'package:flutter/widgets.dart';

/// Tracks global positions of inspected widgets for heatmap visualization.
class HeatmapTracker {
  HeatmapTracker._();

  static final HeatmapTracker _instance = HeatmapTracker._();

  /// Singleton instance.
  static HeatmapTracker get instance => _instance;

  final Map<String, Rect> _positions = {};

  /// Whether heatmap tracking is enabled.
  bool isEnabled = false;

  /// Updates the position of a widget.
  void updatePosition(String name, Rect rect) {
    if (!isEnabled) return;
    _positions[name] = rect;
  }

  /// Removes a widget from tracking.
  void removeWidget(String name) {
    _positions.remove(name);
  }

  /// Returns all tracked positions.
  Map<String, Rect> get positions => Map.unmodifiable(_positions);

  /// Resets tracker.
  void reset() {
    _positions.clear();
  }
}
