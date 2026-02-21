import '../core/performance_config.dart';
import '../core/performance_warning.dart';

/// Tracks widget rebuild frequency and detects excessive rebuilds.
///
/// Monitors how often specific widgets are rebuilt and generates warnings
/// when thresholds are exceeded.
///
/// ```dart
/// // In a widget's build method:
/// RebuildTracker.instance.trackRebuild('MyWidget');
/// ```
class RebuildTracker {
  RebuildTracker._();

  static final RebuildTracker _instance = RebuildTracker._();

  /// Singleton instance.
  static RebuildTracker get instance => _instance;

  /// Default time window for counting rebuilds.
  Duration trackingWindow = const Duration(seconds: 2);

  /// Threshold for number of rebuilds to trigger a warning.
  int warningThreshold = 60;

  final Map<String, List<DateTime>> _rebuildTimestamps = {};
  final Map<String, int> _totalRebuildCounts = {};
  bool _isTracking = false;

  /// Whether the tracker is active.
  bool get isTracking => _isTracking;

  /// Total rebuild count across all widgets.
  int get totalRebuilds =>
      _totalRebuildCounts.values.fold(0, (sum, c) => sum + c);

  /// Copy of rebuild counts per widget.
  Map<String, int> get rebuildCounts => Map.unmodifiable(_totalRebuildCounts);

  /// Returns the top N most frequently rebuilt widgets.
  List<MapEntry<String, int>> topRebuilders({int count = 10}) {
    final sorted =
        _totalRebuildCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).toList();
  }

  /// Returns recent rebuild frequency (rebuilds per second) for a widget.
  double rebuildFrequency(String widgetName) {
    final timestamps = _rebuildTimestamps[widgetName];
    if (timestamps == null || timestamps.isEmpty) return 0;

    final now = DateTime.now();
    final cutoff = now.subtract(trackingWindow);
    final recentCount = timestamps.where((t) => t.isAfter(cutoff)).length;
    return recentCount / trackingWindow.inSeconds;
  }

  /// Starts tracking.
  void start({int? threshold, Duration? window}) {
    _isTracking = true;
    if (threshold != null) warningThreshold = threshold;
    if (window != null) trackingWindow = window;
  }

  /// Stops tracking.
  void stop() {
    _isTracking = false;
  }

  /// Track a rebuild for a named widget.
  void trackRebuild(String widgetName) {
    if (!_isTracking) return;

    final now = DateTime.now();

    // Record the timestamp
    _rebuildTimestamps.putIfAbsent(widgetName, () => []);
    final rebuilds = _rebuildTimestamps[widgetName]!;
    rebuilds.add(now);

    _totalRebuildCounts[widgetName] =
        (_totalRebuildCounts[widgetName] ?? 0) + 1;

    // Prune and check threshold
    final cutoff = now.subtract(trackingWindow);

    // Performance optimization: only prune if list gets large or after window
    if (rebuilds.length > 200 || _totalRebuildCounts[widgetName]! % 50 == 0) {
      rebuilds.removeWhere((t) => t.isBefore(cutoff));
    }

    // Cap tracking to avoid infinite memory growth if window is large
    if (rebuilds.length > 500) {
      rebuilds.removeRange(0, rebuilds.length - 200);
    }

    // Check threshold
    final recentCount = _rebuildTimestamps[widgetName]!.length;
    if (recentCount >= warningThreshold) {
      _emitWarning(widgetName, recentCount);
      // Reset timestamps for this widget to avoid spam
      _rebuildTimestamps[widgetName]!.clear();
    }
  }

  void _emitWarning(String widgetName, int count) {
    final windowSeconds = trackingWindow.inSeconds;
    PerformanceWarningManager.instance.report(
      PerformanceWarningData(
        message:
            '⚠️ Widget "$widgetName" rebuilt $count times in $windowSeconds seconds.',
        type: WarningType.excessiveRebuilds,
        severity:
            count > warningThreshold * 2
                ? WarningSeverity.critical
                : WarningSeverity.warning,
        suggestion:
            'Use const constructors, memoize values, or consider '
            'ValueListenableBuilder / Selector to reduce rebuilds.',
        widgetName: widgetName,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Resets all tracking data.
  void reset() {
    _rebuildTimestamps.clear();
    _totalRebuildCounts.clear();
  }

  /// Disposes the tracker.
  void dispose() {
    stop();
    reset();
  }
}
