import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/performance_config.dart';
import '../core/performance_metrics.dart';
import '../core/performance_score.dart';
import '../core/performance_warning.dart';
import '../core/performance_history.dart';
import '../dashboard/dashboard_overlay.dart';
import '../dashboard/heatmap_overlay.dart';
import '../suggestions/optimization_suggestion.dart';
import '../suggestions/suggestion_engine.dart';
import '../trackers/animation_tracker.dart';
import '../trackers/frame_tracker.dart';
import '../trackers/memory_tracker.dart';
import '../trackers/rebuild_tracker.dart';
import '../trackers/set_state_tracker.dart';
import '../trackers/widget_depth_tracker.dart';
import '../trackers/widget_size_tracker.dart';
import '../trackers/heatmap_tracker.dart';

/// The main performance optimizer widget.
///
/// Wrap your app's root widget with [PerformanceOptimizer] to start
/// monitoring performance automatically.
///
/// ```dart
/// void main() {
///   runApp(
///     PerformanceOptimizer(
///       enabled: true,
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
///
/// Enable the floating dashboard for real-time visualization:
///
/// ```dart
/// PerformanceOptimizer(
///   showDashboard: true,
///   child: MyApp(),
/// );
/// ```
class PerformanceOptimizer extends StatefulWidget {
  /// Creates a [PerformanceOptimizer] widget.
  const PerformanceOptimizer({
    super.key,
    required this.child,
    this.enabled = true,
    this.trackRebuilds = true,
    this.trackMemory = true,
    this.trackAnimations = true,
    this.trackWidgetSize = true,
    this.trackWidgetDepth = true,
    this.trackSetState = true,
    this.showDashboard = false,
    this.showHeatmap = false,
    this.warningThreshold = 16,
    this.rebuildWarningCount = 60,
    this.maxWidgetDepth = 30,
    this.dashboardPosition = DashboardPosition.topRight,
    this.dashboardOpacity = 0.92,
    this.logWarnings = true,
    this.onWarning,
    this.onFrame,
    this.enableInReleaseMode = false,
    this.config,
  });

  /// The child widget (typically your app's root).
  final Widget child;

  /// Whether the optimizer is enabled.
  final bool enabled;

  /// Whether to track widget rebuilds.
  final bool trackRebuilds;

  /// Whether to track memory.
  final bool trackMemory;

  /// Whether to track animations.
  final bool trackAnimations;

  /// Whether to track widget size.
  final bool trackWidgetSize;

  /// Whether to track widget tree depth.
  final bool trackWidgetDepth;

  /// Whether to track setState calls.
  final bool trackSetState;

  /// Whether to show the floating dashboard overlay.
  final bool showDashboard;

  /// Whether to show the rebuild heatmap overlay.
  final bool showHeatmap;

  /// Frame time warning threshold in ms.
  final int warningThreshold;

  /// Rebuild count threshold for warnings.
  final int rebuildWarningCount;

  /// Max widget tree depth before warning.
  final int maxWidgetDepth;

  /// Position of the dashboard overlay.
  final DashboardPosition dashboardPosition;

  /// Dashboard opacity.
  final double dashboardOpacity;

  /// Whether to log warnings to console.
  final bool logWarnings;

  /// Callback for performance warnings.
  final void Function(PerformanceWarningData)? onWarning;

  /// Callback for frame timing data.
  final void Function(FrameTimingData)? onFrame;

  /// Whether to enable in release mode.
  final bool enableInReleaseMode;

  /// Optional full configuration object (overrides individual properties).
  final PerformanceConfig? config;

  /// Access to the global metrics.
  static PerformanceMetrics get metrics => PerformanceMetrics.instance;

  /// Get the current performance score.
  static PerformanceScore get score => PerformanceScore.calculate();

  /// Listen for performance warnings.
  static void addWarningListener(
    void Function(PerformanceWarningData) listener,
  ) {
    PerformanceWarningManager.instance.addListener(listener);
  }

  /// Remove a warning listener.
  static void removeWarningListener(
    void Function(PerformanceWarningData) listener,
  ) {
    PerformanceWarningManager.instance.removeListener(listener);
  }

  /// Add a frame listener.
  static void addFrameListener(void Function(FrameTimingData) listener) {
    FrameTracker.instance.addListener(listener);
  }

  /// Remove a frame listener.
  static void removeFrameListener(void Function(FrameTimingData) listener) {
    FrameTracker.instance.removeListener(listener);
  }

  /// Generate optimization suggestions.
  static List<OptimizationSuggestion> get suggestions =>
      SuggestionEngine.instance.generateSuggestions();

  /// Print the optimization report.
  static String get report => SuggestionEngine.instance.generateReport();

  /// Reset all performance data.
  static void resetAll() {
    PerformanceMetrics.instance.reset();
  }

  @override
  State<PerformanceOptimizer> createState() => _PerformanceOptimizerState();
}

class _PerformanceOptimizerState extends State<PerformanceOptimizer> {
  late PerformanceConfig _config;
  bool _isActive = false;
  Timer? _historyTimer;

  @override
  void initState() {
    super.initState();
    _buildConfig();
    _startTracking();
  }

  @override
  void didUpdateWidget(PerformanceOptimizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if anything significant changed
    final changed =
        widget.enabled != oldWidget.enabled ||
        widget.showDashboard != oldWidget.showDashboard ||
        widget.showHeatmap != oldWidget.showHeatmap ||
        widget.logWarnings != oldWidget.logWarnings ||
        widget.trackRebuilds != oldWidget.trackRebuilds ||
        widget.trackMemory != oldWidget.trackMemory ||
        widget.trackAnimations != oldWidget.trackAnimations ||
        widget.trackWidgetDepth != oldWidget.trackWidgetDepth ||
        widget.trackSetState != oldWidget.trackSetState ||
        widget.config != oldWidget.config;

    if (changed) {
      final wasActive = _isActive;
      _stopTracking();
      _buildConfig();
      if (widget.enabled || (wasActive && widget.enabled)) {
        _startTracking();
      }
    }
  }

  void _buildConfig() {
    if (widget.config != null) {
      _config = widget.config!;
    } else {
      _config = PerformanceConfig(
        enabled: widget.enabled,
        trackRebuilds: widget.trackRebuilds,
        trackMemory: widget.trackMemory,
        trackAnimations: widget.trackAnimations,
        trackWidgetSize: widget.trackWidgetSize,
        trackWidgetDepth: widget.trackWidgetDepth,
        trackSetState: widget.trackSetState,
        showDashboard: widget.showDashboard,
        showHeatmap: widget.showHeatmap,
        warningThreshold: Duration(milliseconds: widget.warningThreshold),
        rebuildWarningCount: widget.rebuildWarningCount,
        maxWidgetDepth: widget.maxWidgetDepth,
        dashboardPosition: widget.dashboardPosition,
        dashboardOpacity: widget.dashboardOpacity,
        logWarnings: widget.logWarnings,
        onWarning: widget.onWarning,
        onFrame: widget.onFrame,
        enableInReleaseMode: widget.enableInReleaseMode,
      );
    }
  }

  void _startTracking() {
    // Don't run in release mode unless explicitly enabled
    if (kReleaseMode && !_config.enableInReleaseMode) return;
    if (!_config.enabled) return;

    _isActive = true;

    // Start frame tracker
    if (_config.trackAnimations) {
      FrameTracker.instance.start(warningThreshold: _config.warningThreshold);
      if (_config.onFrame != null) {
        FrameTracker.instance.addListener(_config.onFrame!);
      }
    }

    // Start rebuild tracker
    if (_config.trackRebuilds) {
      RebuildTracker.instance.start(threshold: _config.rebuildWarningCount);
    }

    // Start memory tracker
    if (_config.trackMemory) {
      MemoryTracker.instance.start(interval: _config.memoryCheckInterval);
    }

    // Start animation tracker
    if (_config.trackAnimations) {
      AnimationTracker.instance.start(jankThreshold: _config.warningThreshold);
    }

    // Start widget depth tracker
    if (_config.trackWidgetDepth) {
      WidgetDepthTracker.instance.start(maxDepth: _config.maxWidgetDepth);
    }

    // Start setState tracker
    if (_config.trackSetState) {
      SetStateTracker.instance.start();
    }

    // Start widget size tracker
    if (_config.trackWidgetSize) {
      WidgetSizeTracker.instance.start();
    }

    // Start heatmap tracker
    if (_config.showHeatmap) {
      HeatmapTracker.instance.isEnabled = true;
    }

    // Start history recording
    _historyTimer?.cancel();
    _historyTimer = Timer.periodic(_config.historyInterval, (_) {
      if (_isActive) PerformanceHistoryManager.instance.record();
    });

    // Setup warning logging
    if (_config.logWarnings) {
      PerformanceWarningManager.instance.addListener(_logWarning);
    }

    // Setup warning callback
    if (_config.onWarning != null) {
      PerformanceWarningManager.instance.addListener(_config.onWarning!);
    }

    if (kDebugMode) {
      debugPrint('⚡ PerformanceOptimizer: Started monitoring');
    }
  }

  void _stopTracking() {
    _isActive = false;

    FrameTracker.instance.stop();
    RebuildTracker.instance.stop();
    MemoryTracker.instance.stop();
    AnimationTracker.instance.stop();
    WidgetDepthTracker.instance.stop();
    SetStateTracker.instance.stop();
    WidgetSizeTracker.instance.stop();
    HeatmapTracker.instance.isEnabled = false;
    HeatmapTracker.instance.reset();
    _historyTimer?.cancel();
    _historyTimer = null;

    PerformanceWarningManager.instance.removeListener(_logWarning);
    if (_config.onWarning != null) {
      PerformanceWarningManager.instance.removeListener(_config.onWarning!);
    }
    if (_config.onFrame != null) {
      FrameTracker.instance.removeListener(_config.onFrame!);
    }

    if (kDebugMode) {
      debugPrint('⚡ PerformanceOptimizer: Stopped monitoring');
    }
  }

  void _logWarning(PerformanceWarningData warning) {
    if (kDebugMode) {
      debugPrint('⚡ PERF: $warning');
    }
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_config.enabled || (kReleaseMode && !_config.enableInReleaseMode)) {
      return widget.child;
    }

    // Analyze widget tree depth on each build (throttled internally)
    if (_config.trackWidgetDepth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          WidgetDepthTracker.instance.analyzeTree(context);
        }
      });
    }

    final List<Widget> children = [widget.child];
    if (_config.showHeatmap) {
      children.add(const HeatmapOverlay());
    }
    if (_config.showDashboard) {
      children.add(DashboardOverlay(config: _config));
    }

    if (children.length > 1) {
      return Stack(children: children);
    }

    return widget.child;
  }
}
