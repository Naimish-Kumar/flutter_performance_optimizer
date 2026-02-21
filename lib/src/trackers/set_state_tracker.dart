import '../core/performance_config.dart';
import '../core/performance_warning.dart';

/// Tracks setState calls and detects unnecessary or excessive usage.
///
/// Helps identify widgets that may benefit from using more targeted
/// state management solutions.
///
/// ```dart
/// SetStateTracker.instance.trackSetState('MyWidget');
/// ```
class SetStateTracker {
  SetStateTracker._();

  static final SetStateTracker _instance = SetStateTracker._();

  /// Singleton instance.
  static SetStateTracker get instance => _instance;

  bool _isTracking = false;

  /// Time window for counting setState calls.
  Duration _window = const Duration(seconds: 2);

  /// Threshold for warnings.
  int _warningThreshold = 10;

  final Map<String, List<DateTime>> _setStateCalls = {};
  final Map<String, int> _totalCounts = {};

  /// Whether the tracker is active.
  bool get isTracking => _isTracking;

  /// Total setState calls across all widgets.
  int get totalSetStateCalls =>
      _totalCounts.values.fold(0, (sum, c) => sum + c);

  /// setState counts per widget.
  Map<String, int> get setStateCounts => Map.unmodifiable(_totalCounts);

  /// Returns the top setState callers.
  List<MapEntry<String, int>> topCallers({int count = 10}) {
    final sorted =
        _totalCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).toList();
  }

  /// Returns setState frequency for a widget (calls per second).
  double frequency(String widgetName) {
    final calls = _setStateCalls[widgetName];
    if (calls == null || calls.isEmpty) return 0;
    final now = DateTime.now();
    final cutoff = now.subtract(_window);
    final recentCount = calls.where((t) => t.isAfter(cutoff)).length;
    return recentCount / _window.inSeconds;
  }

  /// Starts tracking.
  void start({int? threshold, Duration? window}) {
    _isTracking = true;
    if (threshold != null) _warningThreshold = threshold;
    if (window != null) _window = window;
  }

  /// Stops tracking.
  void stop() {
    _isTracking = false;
  }

  /// Track a setState call for a named widget.
  void trackSetState(String widgetName) {
    if (!_isTracking) return;

    final now = DateTime.now();

    final rebuilds = _setStateCalls.putIfAbsent(widgetName, () => []);
    rebuilds.add(now);
    _totalCounts[widgetName] = (_totalCounts[widgetName] ?? 0) + 1;

    // Prune and check threshold
    final cutoff = now.subtract(_window);

    // Optimization: only prune occasionally or if large
    if (rebuilds.length > 50 || _totalCounts[widgetName]! % 20 == 0) {
      rebuilds.removeWhere((t) => t.isBefore(cutoff));
    }

    if (rebuilds.length > 200) {
      rebuilds.removeRange(0, rebuilds.length - 50);
    }

    // Check threshold
    final recentCount = _setStateCalls[widgetName]!.length;
    if (recentCount >= _warningThreshold) {
      PerformanceWarningManager.instance.report(
        PerformanceWarningData(
          message:
              '⚠️ Widget "$widgetName" called setState $recentCount times '
              'in ${_window.inSeconds} seconds.',
          type: WarningType.unnecessarySetState,
          severity:
              recentCount > _warningThreshold * 2
                  ? WarningSeverity.critical
                  : WarningSeverity.warning,
          suggestion:
              'Consider using ValueNotifier, ValueListenableBuilder, '
              'or a proper state management solution (Provider, Riverpod, '
              'Bloc) to reduce unnecessary setState calls.',
          widgetName: widgetName,
          timestamp: DateTime.now(),
        ),
      );
      // Reset to avoid warning spam
      _setStateCalls[widgetName]!.clear();
    }
  }

  /// Resets all tracking data.
  void reset() {
    _setStateCalls.clear();
    _totalCounts.clear();
  }

  /// Disposes the tracker.
  void dispose() {
    stop();
    reset();
  }
}
