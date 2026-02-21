import 'package:flutter/widgets.dart';

import '../core/performance_config.dart';
import '../core/performance_warning.dart';

/// Tracks widget tree depth and complexity.
///
/// Detects overly deep widget trees that may impact layout performance.
///
/// ```dart
/// WidgetDepthTracker.instance.analyzeTree(context);
/// ```
class WidgetDepthTracker {
  WidgetDepthTracker._();

  static final WidgetDepthTracker _instance = WidgetDepthTracker._();

  /// Singleton instance.
  static WidgetDepthTracker get instance => _instance;

  int _maxDepthThreshold = 30;
  int _lastMeasuredDepth = 0;
  int _lastMeasuredWidgetCount = 0;
  bool _isTracking = false;
  DateTime? _lastAnalysisTime;

  /// Analysis throttling interval.
  static const Duration _analysisInterval = Duration(seconds: 3);

  /// Whether the tracker is active.
  bool get isTracking => _isTracking;

  /// The last measured maximum tree depth.
  int get lastMeasuredDepth => _lastMeasuredDepth;

  /// The last measured total widget count.
  int get lastMeasuredWidgetCount => _lastMeasuredWidgetCount;

  /// Starts tracking with optional depth threshold.
  void start({int? maxDepth}) {
    _isTracking = true;
    if (maxDepth != null) _maxDepthThreshold = maxDepth;
  }

  /// Stops tracking.
  void stop() {
    _isTracking = false;
  }

  /// Analyzes the widget tree starting from the given [context].
  ///
  /// Returns the maximum depth found. Includes internal throttling.
  int analyzeTree(BuildContext context) {
    if (!_isTracking) return 0;

    final now = DateTime.now();
    if (_lastAnalysisTime != null &&
        now.difference(_lastAnalysisTime!) < _analysisInterval) {
      return _lastMeasuredDepth;
    }
    _lastAnalysisTime = now;

    int maxDepth = 0;
    int widgetCount = 0;

    void visit(Element element, int depth) {
      widgetCount++;
      if (depth > maxDepth) maxDepth = depth;
      element.visitChildren((child) => visit(child, depth + 1));
    }

    (context as Element).visitChildren((child) => visit(child, 1));

    _lastMeasuredDepth = maxDepth;
    _lastMeasuredWidgetCount = widgetCount;

    // Emit warning if depth exceeds threshold
    if (maxDepth > _maxDepthThreshold) {
      PerformanceWarningManager.instance.report(
        PerformanceWarningData(
          message:
              '⚠️ Widget tree depth exceeds $_maxDepthThreshold levels '
              '(found $maxDepth levels, $widgetCount widgets).',
          type: WarningType.deepWidgetTree,
          severity:
              maxDepth > _maxDepthThreshold * 1.5
                  ? WarningSeverity.critical
                  : WarningSeverity.warning,
          suggestion:
              'Split your widget tree into smaller, composable widgets. '
              'Extract nested builders and consider using '
              'CustomMultiChildLayout for complex layouts.',
          timestamp: DateTime.now(),
        ),
      );
    }

    return maxDepth;
  }

  /// Measures depth at a specific widget in the tree.
  WidgetDepthInfo measureAt(BuildContext context, String widgetName) {
    if (!_isTracking) {
      return WidgetDepthInfo(
        widgetName: widgetName,
        depth: 0,
        childCount: 0,
        deepestChild: '',
      );
    }

    int maxDepth = 0;
    int childCount = 0;
    String deepestChildName = '';

    void visit(Element element, int depth) {
      childCount++;
      if (depth > maxDepth) {
        maxDepth = depth;
        deepestChildName = element.widget.runtimeType.toString();
      }
      element.visitChildren((child) => visit(child, depth + 1));
    }

    (context as Element).visitChildren((child) => visit(child, 1));

    return WidgetDepthInfo(
      widgetName: widgetName,
      depth: maxDepth,
      childCount: childCount,
      deepestChild: deepestChildName,
    );
  }

  /// Resets tracking data.
  void reset() {
    _lastMeasuredDepth = 0;
    _lastMeasuredWidgetCount = 0;
  }

  /// Disposes the tracker.
  void dispose() {
    stop();
    reset();
  }
}

/// Information about widget tree depth at a specific point.
class WidgetDepthInfo {
  /// Creates a [WidgetDepthInfo].
  const WidgetDepthInfo({
    required this.widgetName,
    required this.depth,
    required this.childCount,
    required this.deepestChild,
  });

  /// Name of the measured widget.
  final String widgetName;

  /// Maximum depth under this widget.
  final int depth;

  /// Total number of child widgets.
  final int childCount;

  /// Type name of the deepest child widget.
  final String deepestChild;

  @override
  String toString() =>
      'WidgetDepthInfo("$widgetName": depth=$depth, '
      'children=$childCount, deepest=$deepestChild)';
}
