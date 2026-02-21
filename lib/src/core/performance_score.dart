import 'performance_metrics.dart';
import 'performance_warning.dart';

/// Calculates a comprehensive performance score for the app.
///
/// Score ranges from 0 to 100:
/// - 90-100: Excellent performance
/// - 70-89: Good performance
/// - 50-69: Needs improvement
/// - 0-49: Poor performance
///
/// ```dart
/// final score = PerformanceScore.calculate();
/// print('Performance Score: ${score.total} / 100');
/// ```
class PerformanceScore {
  /// Creates a [PerformanceScore].
  const PerformanceScore({
    required this.total,
    required this.fpsScore,
    required this.memoryScore,
    required this.rebuildScore,
    required this.jankScore,
    required this.warningScore,
    required this.grade,
    required this.timestamp,
  });

  /// Total performance score (0-100).
  final int total;

  /// FPS-based score component (0-100).
  final int fpsScore;

  /// Memory-based score component (0-100).
  final int memoryScore;

  /// Rebuild-based score component (0-100).
  final int rebuildScore;

  /// Jank-based score component (0-100).
  final int jankScore;

  /// Warning-based score component (0-100).
  final int warningScore;

  /// Letter grade for the score.
  final String grade;

  /// When the score was calculated.
  final DateTime timestamp;

  /// Calculates the current performance score.
  static PerformanceScore calculate() {
    final metrics = PerformanceMetrics.instance;

    // FPS score (weight: 30%)
    final fps = metrics.fps;
    int fpsScore;
    if (fps >= 58) {
      fpsScore = 100;
    } else if (fps >= 50) {
      fpsScore = 80;
    } else if (fps >= 40) {
      fpsScore = 60;
    } else if (fps >= 30) {
      fpsScore = 40;
    } else {
      fpsScore = 20;
    }

    // Memory score (weight: 20%)
    final memMB = metrics.memoryUsageMB;
    int memoryScore;
    if (memMB <= 0) {
      memoryScore = 100; // Not tracking or no data
    } else if (memMB < 100) {
      memoryScore = 100;
    } else if (memMB < 200) {
      memoryScore = 80;
    } else if (memMB < 400) {
      memoryScore = 60;
    } else if (memMB < 600) {
      memoryScore = 40;
    } else {
      memoryScore = 20;
    }

    // Rebuild score (weight: 20%)
    final rebuilds = metrics.totalRebuilds;
    int rebuildScore;
    if (rebuilds < 50) {
      rebuildScore = 100;
    } else if (rebuilds < 200) {
      rebuildScore = 80;
    } else if (rebuilds < 500) {
      rebuildScore = 60;
    } else if (rebuilds < 1000) {
      rebuildScore = 40;
    } else {
      rebuildScore = 20;
    }

    // Jank score (weight: 20%)
    final jank = metrics.jankFrames;
    int jankScore;
    if (jank == 0) {
      jankScore = 100;
    } else if (jank < 5) {
      jankScore = 80;
    } else if (jank < 15) {
      jankScore = 60;
    } else if (jank < 30) {
      jankScore = 40;
    } else {
      jankScore = 20;
    }

    // Warning score (weight: 10%)
    final warnings = PerformanceWarningManager.instance;
    final criticalWarnings = warnings.criticalCount;
    int warningScore;
    if (criticalWarnings == 0 && warnings.count < 3) {
      warningScore = 100;
    } else if (criticalWarnings == 0) {
      warningScore = 80;
    } else if (criticalWarnings < 3) {
      warningScore = 60;
    } else if (criticalWarnings < 5) {
      warningScore = 40;
    } else {
      warningScore = 20;
    }

    // SetState score (weight: 10%)
    final setStateCalls = metrics.snapshot().setStateCalls;
    int setStateScore;
    if (setStateCalls < 10) {
      setStateScore = 100;
    } else if (setStateCalls < 30) {
      setStateScore = 80;
    } else if (setStateCalls < 60) {
      setStateScore = 60;
    } else if (setStateCalls < 100) {
      setStateScore = 40;
    } else {
      setStateScore = 20;
    }

    // Depth score (weight: 10%)
    final maxDepth = metrics.snapshot().maxWidgetDepth;
    int depthScore;
    if (maxDepth <= 20) {
      depthScore = 100;
    } else if (maxDepth <= 30) {
      depthScore = 80;
    } else if (maxDepth <= 40) {
      depthScore = 60;
    } else if (maxDepth <= 50) {
      depthScore = 40;
    } else {
      depthScore = 20;
    }

    // Calculate weighted total (Adjusted weights to total 100%)
    // FPS: 25%, Memory: 15%, Rebuilds: 15%, Jank: 20%, Warnings: 10%, SetState: 7.5%, Depth: 7.5%
    final total = (fpsScore * 0.25 +
            memoryScore * 0.15 +
            rebuildScore * 0.15 +
            jankScore * 0.20 +
            warningScore * 0.10 +
            setStateScore * 0.075 +
            depthScore * 0.075)
        .round()
        .clamp(0, 100);

    // Determine grade
    String grade;
    if (total >= 90) {
      grade = 'A+';
    } else if (total >= 80) {
      grade = 'A';
    } else if (total >= 70) {
      grade = 'B';
    } else if (total >= 60) {
      grade = 'C';
    } else if (total >= 50) {
      grade = 'D';
    } else {
      grade = 'F';
    }

    return PerformanceScore(
      total: total,
      fpsScore: fpsScore,
      memoryScore: memoryScore,
      rebuildScore: rebuildScore,
      jankScore: jankScore,
      warningScore: warningScore,
      grade: grade,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'Performance Score: $total / 100 (Grade: $grade)\n'
      '  FPS: $fpsScore | Memory: $memoryScore | '
      'Rebuilds: $rebuildScore | Jank: $jankScore | Warnings: $warningScore';
}
