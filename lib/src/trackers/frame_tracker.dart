import 'package:flutter/scheduler.dart';

import '../core/performance_config.dart';
import '../core/performance_warning.dart';

/// Tracks frame timing performance using Flutter's [SchedulerBinding].
///
/// Monitors FPS, build time, raster time, and detects jank frames.
///
/// Uses [SchedulerBinding.addTimingsCallback] to receive frame timing data
/// from the engine.
class FrameTracker {
  FrameTracker._();

  static final FrameTracker _instance = FrameTracker._();

  /// Singleton instance.
  static FrameTracker get instance => _instance;

  bool _isTracking = false;
  Duration _warningThreshold = const Duration(milliseconds: 16);

  final List<_FrameRecord> _frameHistory = [];
  int _jankFrameCount = 0;

  /// Maximum frame history to keep.
  static const int _maxHistorySize = 300;

  final List<void Function(FrameTimingData)> _listeners = [];

  /// Whether the tracker is currently active.
  bool get isTracking => _isTracking;

  /// Current FPS estimate based on recent frames.
  double get currentFps {
    if (_frameHistory.isEmpty) return 60.0;

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(seconds: 1));

    final recentFrames =
        _frameHistory.where((f) => f.timestamp.isAfter(cutoff)).length;
    return recentFrames.toDouble().clamp(0, 120);
  }

  /// Average build time across recent frames.
  Duration get averageBuildTime {
    if (_frameHistory.isEmpty) return Duration.zero;
    final recent = _recentFrames();
    if (recent.isEmpty) return Duration.zero;
    final totalMicroseconds = recent.fold<int>(
      0,
      (sum, f) => sum + f.buildTime.inMicroseconds,
    );
    return Duration(microseconds: totalMicroseconds ~/ recent.length);
  }

  /// Average raster time across recent frames.
  Duration get averageRasterTime {
    if (_frameHistory.isEmpty) return Duration.zero;
    final recent = _recentFrames();
    if (recent.isEmpty) return Duration.zero;
    final totalMicroseconds = recent.fold<int>(
      0,
      (sum, f) => sum + f.rasterTime.inMicroseconds,
    );
    return Duration(microseconds: totalMicroseconds ~/ recent.length);
  }

  /// Average total frame time.
  Duration get averageFrameTime {
    if (_frameHistory.isEmpty) return Duration.zero;
    final recent = _recentFrames();
    if (recent.isEmpty) return Duration.zero;
    final totalMicroseconds = recent.fold<int>(
      0,
      (sum, f) => sum + f.totalTime.inMicroseconds,
    );
    return Duration(microseconds: totalMicroseconds ~/ recent.length);
  }

  /// Total number of jank frames detected.
  int get jankFrameCount => _jankFrameCount;

  /// Whether the app is currently experiencing jank (>2 jank frames in last second).
  bool get isJanking {
    if (_frameHistory.isEmpty) return false;
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(seconds: 1));
    final recentJanks =
        _frameHistory
            .where((f) => f.timestamp.isAfter(cutoff) && f.isJank)
            .length;
    return recentJanks > 2;
  }

  /// FPS history for charting.
  List<double> get fpsHistory {
    if (_frameHistory.isEmpty) return [];
    final result = <double>[];
    final sorted = List<_FrameRecord>.from(_frameHistory)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sorted.isEmpty) return [];

    // Group by 500ms buckets
    DateTime bucketStart = sorted.first.timestamp;
    int countInBucket = 0;

    for (final frame in sorted) {
      if (frame.timestamp.difference(bucketStart).inMilliseconds < 500) {
        countInBucket++;
      } else {
        result.add((countInBucket * 2).toDouble().clamp(0, 120));
        bucketStart = frame.timestamp;
        countInBucket = 1;
      }
    }
    if (countInBucket > 0) {
      result.add((countInBucket * 2).toDouble().clamp(0, 120));
    }

    return result;
  }

  /// Frame time history in milliseconds.
  List<double> get frameTimeHistory {
    return _recentFrames()
        .map((f) => f.totalTime.inMicroseconds / 1000.0)
        .toList();
  }

  /// Starts tracking frames.
  void start({Duration? warningThreshold}) {
    if (_isTracking) return;
    _isTracking = true;
    _warningThreshold = warningThreshold ?? const Duration(milliseconds: 16);

    try {
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    } catch (_) {
      // SchedulerBinding might not be initialized in some test environments
    }
  }

  /// Adds a listener for frame timing data.
  void addListener(void Function(FrameTimingData) listener) {
    _listeners.add(listener);
  }

  /// Removes a frame timing listener.
  void removeListener(void Function(FrameTimingData) listener) {
    _listeners.remove(listener);
  }

  /// Stops tracking frames.
  void stop() {
    if (!_isTracking) return;
    _isTracking = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final buildTime = Duration(
        microseconds: timing.buildDuration.inMicroseconds,
      );
      final rasterTime = Duration(
        microseconds: timing.rasterDuration.inMicroseconds,
      );
      final totalTime = Duration(microseconds: timing.totalSpan.inMicroseconds);

      final isJank = totalTime > _warningThreshold;

      final record = _FrameRecord(
        buildTime: buildTime,
        rasterTime: rasterTime,
        totalTime: totalTime,
        timestamp: DateTime.now(),
        isJank: isJank,
      );

      _frameHistory.add(record);
      if (isJank) _jankFrameCount++;

      // Trim history
      while (_frameHistory.length > _maxHistorySize) {
        _frameHistory.removeAt(0);
      }

      // Fire listeners
      final data = FrameTimingData(
        buildTime: buildTime,
        rasterTime: rasterTime,
        totalTime: totalTime,
        timestamp: record.timestamp,
      );
      for (final listener in List.of(_listeners)) {
        listener(data);
      }

      // Generate warning for slow frames
      if (isJank) {
        final totalMs = totalTime.inMicroseconds / 1000.0;
        final severity =
            totalMs > 33 ? WarningSeverity.critical : WarningSeverity.warning;

        PerformanceWarningManager.instance.report(
          PerformanceWarningData(
            message:
                '⚠️ Frame rendering took ${totalMs.toStringAsFixed(1)}ms '
                '(threshold: ${_warningThreshold.inMilliseconds}ms)',
            type: WarningType.slowFrame,
            severity: severity,
            suggestion:
                'Avoid expensive operations during animation. '
                'Consider using RepaintBoundary or caching.',
            timestamp: DateTime.now(),
          ),
        );
      }
    }
  }

  List<_FrameRecord> _recentFrames() {
    if (_frameHistory.isEmpty) return [];
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(seconds: 2));
    return _frameHistory.where((f) => f.timestamp.isAfter(cutoff)).toList();
  }

  /// Resets all frame tracking data.
  void reset() {
    _frameHistory.clear();
    _jankFrameCount = 0;
  }

  /// Disposes the tracker.
  void dispose() {
    stop();
    reset();
    _listeners.clear();
  }
}

class _FrameRecord {
  const _FrameRecord({
    required this.buildTime,
    required this.rasterTime,
    required this.totalTime,
    required this.timestamp,
    required this.isJank,
  });

  final Duration buildTime;
  final Duration rasterTime;
  final Duration totalTime;
  final DateTime timestamp;
  final bool isJank;
}
