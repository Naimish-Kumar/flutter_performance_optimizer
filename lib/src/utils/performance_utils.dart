/// Utility functions for performance analysis.
class PerformanceUtils {
  PerformanceUtils._();

  /// Formats a duration as a human-readable string.
  static String formatDuration(Duration duration) {
    if (duration.inMicroseconds < 1000) {
      return '${duration.inMicroseconds}µs';
    } else if (duration.inMilliseconds < 1000) {
      return '${(duration.inMicroseconds / 1000).toStringAsFixed(1)}ms';
    } else {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
    }
  }

  /// Formats memory size in a human-readable format.
  static String formatMemory(double megabytes) {
    if (megabytes < 1) {
      return '${(megabytes * 1024).toStringAsFixed(0)} KB';
    } else if (megabytes < 1024) {
      return '${megabytes.toStringAsFixed(1)} MB';
    } else {
      return '${(megabytes / 1024).toStringAsFixed(2)} GB';
    }
  }

  /// Formats FPS with color indicator.
  static String formatFps(double fps) {
    final emoji =
        fps >= 55
            ? '🟢'
            : fps >= 40
            ? '🟡'
            : '🔴';
    return '$emoji ${fps.toStringAsFixed(1)} FPS';
  }

  /// Returns a performance level string.
  static String performanceLevel(double fps) {
    if (fps >= 58) return 'Excellent';
    if (fps >= 50) return 'Good';
    if (fps >= 40) return 'Fair';
    if (fps >= 30) return 'Poor';
    return 'Critical';
  }

  /// Formats a count with abbreviation.
  static String formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  /// Generates a compact metrics summary.
  static String summarize({
    required double fps,
    required double memoryMB,
    required int rebuilds,
    required int jankFrames,
    required int warnings,
  }) {
    return 'FPS: ${fps.toStringAsFixed(0)} | '
        'Mem: ${formatMemory(memoryMB)} | '
        'Rebuilds: ${formatCount(rebuilds)} | '
        'Jank: $jankFrames | '
        'Warnings: $warnings';
  }
}
