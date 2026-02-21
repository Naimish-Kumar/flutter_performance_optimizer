import 'dart:collection';
import '../core/performance_metrics.dart';

/// Manages the historical recording of performance metrics.
///
/// Stores snapshots over time to enable timeline visualization and
/// trend analysis.
class PerformanceHistoryManager {
  PerformanceHistoryManager._();

  static final PerformanceHistoryManager _instance =
      PerformanceHistoryManager._();

  /// Singleton instance.
  static PerformanceHistoryManager get instance => _instance;

  final List<MetricsSnapshot> _history = [];

  /// Maximum number of snapshots to keep.
  int maxHistorySize = 1000;

  /// Returns all recorded snapshots.
  List<MetricsSnapshot> get history => UnmodifiableListView(_history);

  /// Records a current snapshot.
  void record() {
    _history.add(PerformanceMetrics.instance.snapshot());

    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
    }
  }

  /// Clears all history.
  void clear() {
    _history.clear();
  }

  /// Calculates trends.
  PerformanceTrend getTrend(Duration window) {
    if (_history.length < 2) return PerformanceTrend.stable;

    final recent = _history.last;
    final previous = _history[_history.length - 2];

    final fpsDiff = recent.fps - previous.fps;
    if (fpsDiff < -5) return PerformanceTrend.declining;
    if (fpsDiff > 5) return PerformanceTrend.improving;

    return PerformanceTrend.stable;
  }
}

/// Trends for performance.
enum PerformanceTrend {
  /// Improving performance.
  improving,

  /// Stable performance.
  stable,

  /// Declining performance.
  declining,
}
