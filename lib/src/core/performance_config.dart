/// Configuration options for the Performance Optimizer.
///
/// Controls which tracking features are enabled and their thresholds.
///
/// ```dart
/// PerformanceConfig(
///   enabled: true,
///   trackRebuilds: true,
///   trackMemory: true,
///   trackAnimations: true,
///   trackWidgetSize: true,
///   showDashboard: true,
///   warningThreshold: Duration(milliseconds: 16),
/// );
/// ```
class PerformanceConfig {
  /// Creates a new [PerformanceConfig].
  const PerformanceConfig({
    this.enabled = true,
    this.trackRebuilds = true,
    this.trackMemory = true,
    this.trackAnimations = true,
    this.trackWidgetSize = true,
    this.trackWidgetDepth = true,
    this.trackSetState = true,
    this.showDashboard = false,
    this.showHeatmap = false,
    this.warningThreshold = const Duration(milliseconds: 16),
    this.rebuildWarningCount = 60,
    this.maxWidgetDepth = 30,
    this.memoryCheckInterval = const Duration(seconds: 5),
    this.fpsUpdateInterval = const Duration(milliseconds: 500),
    this.historyInterval = const Duration(seconds: 10),
    this.dashboardPosition = DashboardPosition.topRight,
    this.dashboardOpacity = 0.92,
    this.logWarnings = true,
    this.onWarning,
    this.onFrame,
    this.enableInReleaseMode = false,
  });

  /// Whether the optimizer is enabled.
  final bool enabled;

  /// Whether to track widget rebuilds.
  final bool trackRebuilds;

  /// Whether to track memory usage.
  final bool trackMemory;

  /// Whether to track animations and frame timing.
  final bool trackAnimations;

  /// Whether to track widget size and complexity.
  final bool trackWidgetSize;

  /// Whether to track widget tree depth.
  final bool trackWidgetDepth;

  /// Whether to track setState calls.
  final bool trackSetState;

  /// Whether to show the floating performance dashboard.
  final bool showDashboard;

  /// Whether to show the rebuild heatmap overlay.
  final bool showHeatmap;

  /// Frame time threshold for triggering warnings (default: 16ms for 60fps).
  final Duration warningThreshold;

  /// Number of rebuilds in a time window before showing a warning.
  final int rebuildWarningCount;

  /// Maximum widget tree depth before showing a warning.
  final int maxWidgetDepth;

  /// How often to check memory usage.
  final Duration memoryCheckInterval;

  /// How often to update the FPS display.
  final Duration fpsUpdateInterval;

  /// How often to record performance history.
  final Duration historyInterval;

  /// Position of the dashboard overlay.
  final DashboardPosition dashboardPosition;

  /// Opacity of the dashboard overlay (0.0 to 1.0).
  final double dashboardOpacity;

  /// Whether to log warnings to the console.
  final bool logWarnings;

  /// Callback fired when a performance warning is generated.
  final void Function(PerformanceWarningData warning)? onWarning;

  /// Callback fired on every frame timing update.
  final void Function(FrameTimingData data)? onFrame;

  /// Whether to enable in release mode. NOT recommended.
  final bool enableInReleaseMode;

  /// Creates a copy with overrides.
  PerformanceConfig copyWith({
    bool? enabled,
    bool? trackRebuilds,
    bool? trackMemory,
    bool? trackAnimations,
    bool? trackWidgetSize,
    bool? trackWidgetDepth,
    bool? trackSetState,
    bool? showDashboard,
    bool? showHeatmap,
    Duration? warningThreshold,
    int? rebuildWarningCount,
    int? maxWidgetDepth,
    Duration? memoryCheckInterval,
    Duration? fpsUpdateInterval,
    Duration? historyInterval,
    DashboardPosition? dashboardPosition,
    double? dashboardOpacity,
    bool? logWarnings,
    void Function(PerformanceWarningData warning)? onWarning,
    void Function(FrameTimingData data)? onFrame,
    bool? enableInReleaseMode,
  }) {
    return PerformanceConfig(
      enabled: enabled ?? this.enabled,
      trackRebuilds: trackRebuilds ?? this.trackRebuilds,
      trackMemory: trackMemory ?? this.trackMemory,
      trackAnimations: trackAnimations ?? this.trackAnimations,
      trackWidgetSize: trackWidgetSize ?? this.trackWidgetSize,
      trackWidgetDepth: trackWidgetDepth ?? this.trackWidgetDepth,
      trackSetState: trackSetState ?? this.trackSetState,
      showDashboard: showDashboard ?? this.showDashboard,
      showHeatmap: showHeatmap ?? this.showHeatmap,
      warningThreshold: warningThreshold ?? this.warningThreshold,
      rebuildWarningCount: rebuildWarningCount ?? this.rebuildWarningCount,
      maxWidgetDepth: maxWidgetDepth ?? this.maxWidgetDepth,
      memoryCheckInterval: memoryCheckInterval ?? this.memoryCheckInterval,
      fpsUpdateInterval: fpsUpdateInterval ?? this.fpsUpdateInterval,
      historyInterval: historyInterval ?? this.historyInterval,
      dashboardPosition: dashboardPosition ?? this.dashboardPosition,
      dashboardOpacity: dashboardOpacity ?? this.dashboardOpacity,
      logWarnings: logWarnings ?? this.logWarnings,
      onWarning: onWarning ?? this.onWarning,
      onFrame: onFrame ?? this.onFrame,
      enableInReleaseMode: enableInReleaseMode ?? this.enableInReleaseMode,
    );
  }
}

/// Position for the dashboard overlay.
enum DashboardPosition {
  /// Top-left corner.
  topLeft,

  /// Top-right corner.
  topRight,

  /// Bottom-left corner.
  bottomLeft,

  /// Bottom-right corner.
  bottomRight,

  /// Center of the screen.
  center,
}

/// Data class for frame timing callbacks.
class FrameTimingData {
  /// Creates a [FrameTimingData].
  const FrameTimingData({
    required this.buildTime,
    required this.rasterTime,
    required this.totalTime,
    required this.timestamp,
  });

  /// Time spent building the frame.
  final Duration buildTime;

  /// Time spent rasterizing the frame.
  final Duration rasterTime;

  /// Total frame time.
  final Duration totalTime;

  /// When the frame was recorded.
  final DateTime timestamp;

  @override
  String toString() =>
      'FrameTimingData(build: ${buildTime.inMicroseconds}µs, '
      'raster: ${rasterTime.inMicroseconds}µs, '
      'total: ${totalTime.inMicroseconds}µs)';
}

/// Data class for warning callbacks.
class PerformanceWarningData {
  /// Creates a [PerformanceWarningData].
  const PerformanceWarningData({
    required this.message,
    required this.type,
    required this.severity,
    this.suggestion,
    this.widgetName,
    this.timestamp,
  });

  /// Warning message.
  final String message;

  /// Type of warning.
  final WarningType type;

  /// Severity level.
  final WarningSeverity severity;

  /// Suggested fix.
  final String? suggestion;

  /// Associated widget name, if applicable.
  final String? widgetName;

  /// When the warning occurred.
  final DateTime? timestamp;

  @override
  String toString() =>
      '[$severity] $message${suggestion != null ? '\n  → $suggestion' : ''}';
}

/// Types of performance warnings.
enum WarningType {
  /// Excessive widget rebuilds.
  excessiveRebuilds,

  /// Potential memory leak.
  memoryLeak,

  /// Widget tree too deep.
  deepWidgetTree,

  /// Frame took too long.
  slowFrame,

  /// Animation jank detected.
  animationJank,

  /// Large widget detected.
  largeWidget,

  /// Unnecessary setState.
  unnecessarySetState,

  /// High memory usage.
  highMemoryUsage,

  /// Slow build method.
  slowBuild,
}

/// Severity levels for warnings.
enum WarningSeverity {
  /// Low severity — informational.
  info,

  /// Medium severity — should be addressed.
  warning,

  /// High severity — critical performance issue.
  critical,
}
