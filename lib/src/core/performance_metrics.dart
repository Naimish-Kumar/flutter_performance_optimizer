import 'dart:collection';

import '../trackers/animation_tracker.dart';
import '../trackers/frame_tracker.dart';
import '../trackers/memory_tracker.dart';
import '../trackers/rebuild_tracker.dart';
import '../trackers/set_state_tracker.dart';
import '../trackers/widget_depth_tracker.dart';
import '../trackers/widget_size_tracker.dart';
import 'performance_config.dart';
import 'performance_warning.dart';

/// Central hub for all performance metrics.
///
/// Access metrics programmatically:
///
/// ```dart
/// final metrics = PerformanceMetrics.instance;
/// print(metrics.fps);
/// print(metrics.memoryUsageMB);
/// ```
class PerformanceMetrics {
  PerformanceMetrics._();

  static final PerformanceMetrics _instance = PerformanceMetrics._();

  /// Singleton instance.
  static PerformanceMetrics get instance => _instance;

  /// Current frames per second.
  double get fps => FrameTracker.instance.currentFps;

  /// Average frame build time in milliseconds.
  double get averageBuildTimeMs =>
      FrameTracker.instance.averageBuildTime.inMicroseconds / 1000.0;

  /// Average frame raster time in milliseconds.
  double get averageRasterTimeMs =>
      FrameTracker.instance.averageRasterTime.inMicroseconds / 1000.0;

  /// Average total frame time in milliseconds.
  double get averageFrameTimeMs =>
      FrameTracker.instance.averageFrameTime.inMicroseconds / 1000.0;

  /// Current memory usage in megabytes.
  double get memoryUsageMB => MemoryTracker.instance.currentUsageMB;

  /// Alias for [memoryUsageMB] to match requested API.
  double get memoryUsage => memoryUsageMB;

  /// Peak memory usage in megabytes.
  double get peakMemoryUsageMB => MemoryTracker.instance.peakUsageMB;

  /// Total widget rebuilds tracked.
  int get totalRebuilds => RebuildTracker.instance.totalRebuilds;

  /// Number of jank frames detected.
  int get jankFrames => FrameTracker.instance.jankFrameCount;

  /// Whether jank is currently occurring.
  bool get isJanking => FrameTracker.instance.isJanking;

  /// Number of active warnings.
  int get warningCount => PerformanceWarningManager.instance.count;

  /// All active warnings.
  UnmodifiableListView<PerformanceWarningData> get warnings =>
      PerformanceWarningManager.instance.warnings;

  /// Map of widget names to their rebuild counts.
  Map<String, int> get rebuildCounts => RebuildTracker.instance.rebuildCounts;

  /// Returns a snapshot of all current metrics.
  MetricsSnapshot snapshot() {
    return MetricsSnapshot(
      fps: fps,
      averageBuildTimeMs: averageBuildTimeMs,
      averageRasterTimeMs: averageRasterTimeMs,
      averageFrameTimeMs: averageFrameTimeMs,
      memoryUsageMB: memoryUsageMB,
      peakMemoryUsageMB: peakMemoryUsageMB,
      totalRebuilds: totalRebuilds,
      jankFrames: jankFrames,
      warningCount: warningCount,
      setStateCalls: SetStateTracker.instance.totalSetStateCalls,
      maxWidgetDepth: WidgetDepthTracker.instance.lastMeasuredDepth,
      timestamp: DateTime.now(),
    );
  }

  /// Resets all metrics.
  void reset() {
    FrameTracker.instance.reset();
    RebuildTracker.instance.reset();
    MemoryTracker.instance.reset();
    AnimationTracker.instance.reset();
    WidgetDepthTracker.instance.reset();
    SetStateTracker.instance.reset();
    WidgetSizeTracker.instance.reset();
    PerformanceWarningManager.instance.clear();
  }
}

/// An immutable snapshot of performance metrics at a point in time.
class MetricsSnapshot {
  /// Creates a [MetricsSnapshot].
  const MetricsSnapshot({
    required this.fps,
    required this.averageBuildTimeMs,
    required this.averageRasterTimeMs,
    required this.averageFrameTimeMs,
    required this.memoryUsageMB,
    required this.peakMemoryUsageMB,
    required this.totalRebuilds,
    required this.jankFrames,
    required this.warningCount,
    required this.setStateCalls,
    required this.maxWidgetDepth,
    required this.timestamp,
  });

  /// Frames per second.
  final double fps;

  /// Average build time in ms.
  final double averageBuildTimeMs;

  /// Average raster time in ms.
  final double averageRasterTimeMs;

  /// Average total frame time in ms.
  final double averageFrameTimeMs;

  /// Current memory usage in MB.
  final double memoryUsageMB;

  /// Peak memory usage in MB.
  final double peakMemoryUsageMB;

  /// Total rebuilds counted.
  final int totalRebuilds;

  /// Total jank frames.
  final int jankFrames;

  /// Number of warnings.
  final int warningCount;

  /// Total setState calls.
  final int setStateCalls;

  /// Max widget depth measured.
  final int maxWidgetDepth;

  /// When the snapshot was taken.
  final DateTime timestamp;

  @override
  String toString() =>
      'MetricsSnapshot(fps: ${fps.toStringAsFixed(1)}, '
      'build: ${averageBuildTimeMs.toStringAsFixed(2)}ms, '
      'raster: ${averageRasterTimeMs.toStringAsFixed(2)}ms, '
      'memory: ${memoryUsageMB.toStringAsFixed(1)}MB, '
      'rebuilds: $totalRebuilds, jank: $jankFrames)';
}
