import 'dart:async';
import 'dart:io' show ProcessInfo;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/performance_config.dart';
import '../core/performance_warning.dart';

/// Tracks memory usage and detects potential memory leaks.
///
/// Uses Dart's developer tools to monitor memory consumption.
/// Provides heuristic-based memory leak detection by analyzing
/// memory usage trends over time.
class MemoryTracker {
  MemoryTracker._();

  static final MemoryTracker _instance = MemoryTracker._();

  /// Singleton instance.
  static MemoryTracker get instance => _instance;

  Timer? _pollTimer;
  bool _isTracking = false;

  double _currentUsageMB = 0;
  double _peakUsageMB = 0;
  final List<_MemorySnapshot> _history = [];
  final Set<String> _trackedDisposables = {};
  final Set<String> _disposedItems = {};

  /// Max history entries to keep.
  static const int _maxHistory = 120;

  /// Whether the tracker is active.
  bool get isTracking => _isTracking;

  /// Current estimated memory usage in MB.
  double get currentUsageMB => _currentUsageMB;

  /// Peak memory usage recorded in MB.
  double get peakUsageMB => _peakUsageMB;

  /// Memory usage history for charting.
  List<double> get memoryHistory => _history.map((s) => s.usageMB).toList();

  /// Whether memory usage is trending upward (potential leak).
  bool get isLeaking {
    if (_history.length < 10) return false;
    final recent = _history.sublist(_history.length - 10);
    int increases = 0;
    for (int i = 1; i < recent.length; i++) {
      if (recent[i].usageMB > recent[i - 1].usageMB) increases++;
    }
    return increases >= 7; // 7 out of 9 increases suggests leak
  }

  /// Starts tracking memory.
  void start({Duration? interval}) {
    if (_isTracking) return;
    _isTracking = true;

    final pollInterval = interval ?? const Duration(seconds: 5);
    _pollMemory(); // Initial poll
    _pollTimer = Timer.periodic(pollInterval, (_) => _pollMemory());
  }

  /// Stops tracking memory.
  void stop() {
    _isTracking = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Registers a disposable resource for leak tracking.
  ///
  /// Call this when a controller or resource is created.
  /// ```dart
  /// MemoryTracker.instance.trackDisposable('HomePage.animationController');
  /// ```
  void trackDisposable(String identifier) {
    _trackedDisposables.add(identifier);
  }

  /// Marks a disposable resource as properly disposed.
  ///
  /// Call this in the dispose method.
  /// ```dart
  /// MemoryTracker.instance.markDisposed('HomePage.animationController');
  /// ```
  void markDisposed(String identifier) {
    _disposedItems.add(identifier);
  }

  /// Returns a list of tracked items that haven't been disposed.
  List<String> get undisposedItems {
    return _trackedDisposables
        .where((item) => !_disposedItems.contains(item))
        .toList();
  }

  /// Checks for undisposed items and emits warnings.
  void checkForLeaks() {
    final leaks = undisposedItems;
    for (final item in leaks) {
      PerformanceWarningManager.instance.report(
        PerformanceWarningData(
          message: '⚠️ Possible memory leak detected: "$item" not disposed.',
          type: WarningType.memoryLeak,
          severity: WarningSeverity.warning,
          suggestion:
              'Ensure controllers, streams, and subscriptions are '
              'properly disposed in the dispose() method.',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _pollMemory() {
    // Use ProcessInfo to get RSS-based memory estimate
    // This is a best-effort approach since Dart doesn't expose
    // precise heap usage through a simple API on all platforms.
    _estimateMemory();
  }

  void _estimateMemory() {
    // Use Dart's built-in memory tracking.
    // Since direct memory queries vary by platform, we track via
    // ProcessInfo on supported platforms (mobile/desktop).
    try {
      // Attempt to get memory info from the runtime
      final currentHeap = _getEstimatedHeapUsageMB();

      _currentUsageMB = currentHeap;
      if (currentHeap > _peakUsageMB) {
        _peakUsageMB = currentHeap;
      }

      final snapshot = _MemorySnapshot(
        usageMB: currentHeap,
        timestamp: DateTime.now(),
      );
      _history.add(snapshot);

      while (_history.length > _maxHistory) {
        _history.removeAt(0);
      }

      // Check for leak pattern
      if (isLeaking) {
        PerformanceWarningManager.instance.report(
          PerformanceWarningData(
            message:
                '⚠️ Memory usage is consistently increasing '
                '(${_currentUsageMB.toStringAsFixed(1)}MB). '
                'Possible memory leak.',
            type: WarningType.highMemoryUsage,
            severity:
                _currentUsageMB > 500
                    ? WarningSeverity.critical
                    : WarningSeverity.warning,
            suggestion:
                'Check for undisposed controllers, unclosed streams, '
                'and retained large objects. Use DevTools Memory tab '
                'for detailed analysis.',
            timestamp: DateTime.now(),
          ),
        );
      }

      // High memory warning
      if (_currentUsageMB > 400) {
        PerformanceWarningManager.instance.report(
          PerformanceWarningData(
            message:
                '⚠️ High memory usage: ${_currentUsageMB.toStringAsFixed(1)}MB',
            type: WarningType.highMemoryUsage,
            severity:
                _currentUsageMB > 600
                    ? WarningSeverity.critical
                    : WarningSeverity.warning,
            suggestion:
                'Consider reducing image sizes, disposing unused resources, '
                'and implementing pagination for large lists.',
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (_) {
      // Memory estimation not available on this platform
    }
  }

  double _getEstimatedHeapUsageMB() {
    // Use MemoryProcessInfo for memory estimation
    try {
      final info = MemoryProcessInfo.currentRss;
      return info / (1024 * 1024);
    } catch (_) {
      return 0;
    }
  }

  /// Resets all memory tracking data.
  void reset() {
    _currentUsageMB = 0;
    _peakUsageMB = 0;
    _history.clear();
    _trackedDisposables.clear();
    _disposedItems.clear();
  }

  /// Disposes the tracker.
  void dispose() {
    stop();
    reset();
  }
}

class _MemorySnapshot {
  const _MemorySnapshot({required this.usageMB, required this.timestamp});

  final double usageMB;
  final DateTime timestamp;
}

/// Internal utility for estimating memory usage via RSS.
class MemoryProcessInfo {
  MemoryProcessInfo._();

  /// Gets the current RSS (Resident Set Size) memory usage.
  static int get currentRss {
    if (kIsWeb) return 0;
    try {
      return ProcessInfo.currentRss;
    } catch (_) {
      return 0;
    }
  }
}
