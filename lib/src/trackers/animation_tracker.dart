import 'package:flutter/scheduler.dart';

import '../core/performance_config.dart';
import '../core/performance_warning.dart';

/// Tracks animation performance and detects dropped frames / jank.
///
/// Register animations and monitor their performance:
///
/// ```dart
/// AnimationTracker.instance.registerAnimation('fadeIn');
/// // ... later
/// AnimationTracker.instance.unregisterAnimation('fadeIn');
/// ```
class AnimationTracker {
  AnimationTracker._();

  static final AnimationTracker _instance = AnimationTracker._();

  /// Singleton instance.
  static AnimationTracker get instance => _instance;

  bool _isTracking = false;
  Duration _jankThreshold = const Duration(milliseconds: 16);

  final Set<String> _activeAnimations = {};
  int _droppedFrames = 0;
  int _totalAnimationFrames = 0;
  final List<_AnimationFrameRecord> _recentFrames = [];

  /// Maximum frame records to keep.
  static const int _maxRecords = 100;

  /// Whether tracking is active.
  bool get isTracking => _isTracking;

  /// Number of currently active animations.
  int get activeAnimationCount => _activeAnimations.length;

  /// Names of currently active animations.
  Set<String> get activeAnimations => Set.unmodifiable(_activeAnimations);

  /// Total frames dropped during animations.
  int get droppedFrames => _droppedFrames;

  /// Total animation frames processed.
  int get totalAnimationFrames => _totalAnimationFrames;

  /// Drop rate as a percentage.
  double get dropRate {
    if (_totalAnimationFrames == 0) return 0;
    return (_droppedFrames / _totalAnimationFrames) * 100;
  }

  /// Whether animations are currently running smoothly.
  bool get isSmooth => dropRate < 5;

  /// Starts tracking animations.
  void start({Duration? jankThreshold}) {
    if (_isTracking) return;
    _isTracking = true;
    _jankThreshold = jankThreshold ?? const Duration(milliseconds: 16);
    try {
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    } catch (_) {
      // SchedulerBinding might not be initialized
    }
  }

  /// Stops tracking.
  void stop() {
    if (!_isTracking) return;
    _isTracking = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  /// Registers an active animation for monitoring.
  void registerAnimation(String name) {
    _activeAnimations.add(name);
  }

  /// Unregisters an animation.
  void unregisterAnimation(String name) {
    _activeAnimations.remove(name);
  }

  void _onTimings(List<FrameTiming> timings) {
    if (_activeAnimations.isEmpty) return;

    for (final timing in timings) {
      _totalAnimationFrames++;
      final totalDuration = Duration(
        microseconds: timing.totalSpan.inMicroseconds,
      );

      final isDropped = totalDuration > _jankThreshold;
      if (isDropped) {
        _droppedFrames++;
      }

      final record = _AnimationFrameRecord(
        duration: totalDuration,
        isDropped: isDropped,
        timestamp: DateTime.now(),
        activeAnimations: Set.from(_activeAnimations),
      );

      _recentFrames.add(record);
      while (_recentFrames.length > _maxRecords) {
        _recentFrames.removeAt(0);
      }

      // Emit warning for jank during animation
      if (isDropped) {
        final totalMs = totalDuration.inMicroseconds / 1000.0;
        PerformanceWarningManager.instance.report(
          PerformanceWarningData(
            message:
                '⚠️ Animation jank detected! '
                'Frame took ${totalMs.toStringAsFixed(1)}ms '
                'during: ${_activeAnimations.join(", ")}.',
            type: WarningType.animationJank,
            severity:
                totalMs > 33
                    ? WarningSeverity.critical
                    : WarningSeverity.warning,
            suggestion:
                'Avoid rebuilding large widget subtrees during animation. '
                'Use RepaintBoundary, AnimatedBuilder, or cache '
                'expensive computations outside the build method.',
            timestamp: DateTime.now(),
          ),
        );
      }
    }
  }

  /// Resets all animation tracking data.
  void reset() {
    _droppedFrames = 0;
    _totalAnimationFrames = 0;
    _recentFrames.clear();
    _activeAnimations.clear();
  }

  /// Disposes the tracker.
  void dispose() {
    stop();
    reset();
  }
}

class _AnimationFrameRecord {
  const _AnimationFrameRecord({
    required this.duration,
    required this.isDropped,
    required this.timestamp,
    required this.activeAnimations,
  });

  final Duration duration;
  final bool isDropped;
  final DateTime timestamp;
  final Set<String> activeAnimations;
}
