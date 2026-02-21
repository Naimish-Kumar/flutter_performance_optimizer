/// Detailed frame timing information.
///
/// Access frame timing data:
///
/// ```dart
/// PerformanceOptimizer.onFrame((frame) {
///   print(frame.buildTime);
///   print(frame.rasterTime);
/// });
/// ```
class FrameTimingInfo {
  /// Creates a [FrameTimingInfo].
  const FrameTimingInfo({
    required this.buildDuration,
    required this.rasterDuration,
    required this.totalDuration,
    required this.vsyncOverhead,
    required this.timestamp,
    required this.isJank,
  });

  /// Time spent in the build phase.
  final Duration buildDuration;

  /// Time spent in the rasterization phase.
  final Duration rasterDuration;

  /// Total frame duration.
  final Duration totalDuration;

  /// Vsync overhead duration.
  final Duration vsyncOverhead;

  /// When the frame was measured.
  final DateTime timestamp;

  /// Whether this frame exceeded the jank threshold.
  final bool isJank;

  /// Build time in milliseconds.
  double get buildTimeMs => buildDuration.inMicroseconds / 1000.0;

  /// Raster time in milliseconds.
  double get rasterTimeMs => rasterDuration.inMicroseconds / 1000.0;

  /// Total time in milliseconds.
  double get totalTimeMs => totalDuration.inMicroseconds / 1000.0;

  @override
  String toString() =>
      'FrameTimingInfo(build: ${buildTimeMs.toStringAsFixed(2)}ms, '
      'raster: ${rasterTimeMs.toStringAsFixed(2)}ms, '
      'total: ${totalTimeMs.toStringAsFixed(2)}ms, '
      'jank: $isJank)';
}
