import 'dart:developer';
import '../core/performance_metrics.dart';

/// Tracks advanced CPU and GPU metrics via the Dart VM.
class ProfilingTracker {
  ProfilingTracker._();

  static final ProfilingTracker _instance = ProfilingTracker._();

  /// Singleton instance.
  static ProfilingTracker get instance => _instance;

  bool _isProfiling = false;

  /// Starts profiling.
  void start() {
    _isProfiling = true;
    Service.controlWebServer(enable: true);
  }

  /// Stops profiling.
  void stop() {
    _isProfiling = false;
  }

  /// Gets the estimated CPU load based on build times.
  double get estimatedCpuLoad {
    if (!_isProfiling) return 0.0;
    final avgBuild = PerformanceMetrics.instance.averageBuildTimeMs;
    // 16ms is the budget for 60fps. If build takes 8ms, we assume 50% CPU load for the UI thread.
    return (avgBuild / 16.6) * 100.0;
  }

  /// Gets the estimated GPU load based on raster times.
  double get estimatedGpuLoad {
    if (!_isProfiling) return 0.0;
    final avgRaster = PerformanceMetrics.instance.averageRasterTimeMs;
    return (avgRaster / 16.6) * 100.0;
  }

  /// Gets the currently recorded CPU usage (simulated).
  @Deprecated('Use estimatedCpuLoad')
  double get cpuUsage => estimatedCpuLoad;

  /// Gets the currently recorded GPU usage (simulated).
  @Deprecated('Use estimatedGpuLoad')
  double get gpuUsage => estimatedGpuLoad;
}
