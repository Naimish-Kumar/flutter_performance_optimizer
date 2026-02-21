import 'package:flutter/widgets.dart';

import '../core/performance_config.dart';
import '../core/performance_warning.dart';

/// Tracks widget sizes to detect oversized or expensive rendering.
class WidgetSizeTracker {
  WidgetSizeTracker._();

  static final WidgetSizeTracker _instance = WidgetSizeTracker._();

  /// Singleton instance.
  static WidgetSizeTracker get instance => _instance;

  bool _isTracking = false;

  /// Whether tracking is active.
  bool get isTracking => _isTracking;

  /// Starts tracking.
  void start() {
    _isTracking = true;
  }

  /// Stops tracking.
  void stop() {
    _isTracking = false;
  }

  /// Checks the size of a widget's [RenderBox].
  void trackSize(String widgetName, BuildContext context) {
    if (!_isTracking) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        final size = renderObject.size;

        // Logical pixels threshold (e.g., larger than most screens)
        if (size.width > 2000 || size.height > 2000) {
          PerformanceWarningManager.instance.report(
            PerformanceWarningData(
              message:
                  '⚠️ Widget "$widgetName" has a very large size: '
                  '${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)}',
              type: WarningType.largeWidget,
              severity: WarningSeverity.warning,
              suggestion:
                  'Consider using pagination, lazy loading, or '
                  'optimizing the layout to reduce the rendered area.',
              timestamp: DateTime.now(),
              widgetName: widgetName,
            ),
          );
        }
      }
    });
  }

  /// Resets tracking data.
  void reset() {}
}
