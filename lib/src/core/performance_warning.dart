import 'dart:collection';

import 'performance_config.dart';

/// Manages performance warnings.
///
/// Collects, deduplicates, and provides access to generated warnings.
class PerformanceWarningManager {
  PerformanceWarningManager._();

  static final PerformanceWarningManager _instance =
      PerformanceWarningManager._();

  /// Singleton instance.
  static PerformanceWarningManager get instance => _instance;

  final List<PerformanceWarningData> _warnings = [];
  final List<void Function(PerformanceWarningData)> _listeners = [];

  /// Maximum number of warnings to keep in memory.
  int maxWarnings = 200;

  /// All active warnings.
  UnmodifiableListView<PerformanceWarningData> get warnings =>
      UnmodifiableListView(_warnings);

  /// Number of active warnings.
  int get count => _warnings.length;

  /// Returns warnings of a specific type.
  List<PerformanceWarningData> byType(WarningType type) =>
      _warnings.where((w) => w.type == type).toList();

  /// Returns warnings of a specific severity.
  List<PerformanceWarningData> bySeverity(WarningSeverity severity) =>
      _warnings.where((w) => w.severity == severity).toList();

  /// Returns the count of critical warnings.
  int get criticalCount =>
      _warnings.where((w) => w.severity == WarningSeverity.critical).length;

  /// Returns the count of informational warnings.
  int get infoCount =>
      _warnings.where((w) => w.severity == WarningSeverity.info).length;

  /// Reports a new warning.
  void report(PerformanceWarningData warning) {
    _warnings.add(warning);

    // Trim oldest warnings if over max
    while (_warnings.length > maxWarnings) {
      _warnings.removeAt(0);
    }

    for (final listener in List.of(_listeners)) {
      listener(warning);
    }
  }

  /// Adds a listener for new warnings.
  void addListener(void Function(PerformanceWarningData) listener) {
    _listeners.add(listener);
  }

  /// Removes a warning listener.
  void removeListener(void Function(PerformanceWarningData) listener) {
    _listeners.remove(listener);
  }

  /// Clears all warnings.
  void clear() {
    _warnings.clear();
  }

  /// Resets the warning manager.
  void dispose() {
    _warnings.clear();
    _listeners.clear();
  }
}
