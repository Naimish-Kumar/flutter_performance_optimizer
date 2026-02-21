import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/performance_metrics.dart';
import '../core/performance_score.dart';
import '../widgets/performance_optimizer_widget.dart';

/// Helper for CI/CD performance testing.
///
/// Use this in your widget or integration tests to assert on performance
/// metrics and ensure no regressions.
///
/// ```dart
/// testWidgets('Performance regression test', (tester) async {
///   await PerformanceTestHelper.runApp(tester, MyApp());
///
///   // Perform interactions...
///   await tester.drag(find.byType(ListView), const Offset(0, -500));
///   await tester.pumpAndSettle();
///
///   PerformanceTestHelper.assertFps(min: 55);
///   PerformanceTestHelper.assertMaxRebuilds(100);
/// });
/// ```
class PerformanceTestHelper {
  /// Wraps the app in [PerformanceOptimizer] and pumps it.
  static Future<void> runApp(WidgetTester tester, Widget app) async {
    await tester.pumpWidget(
      PerformanceOptimizer(enabled: true, showDashboard: false, child: app),
    );
  }

  /// Asserts that the average FPS is at least [min].
  static void assertFps({double min = 55}) {
    final fps = PerformanceMetrics.instance.fps;
    expect(
      fps,
      greaterThanOrEqualTo(min),
      reason: 'Performance dropped below $min FPS',
    );
  }

  /// Asserts that total rebuilds are below [max].
  static void assertMaxRebuilds(int max) {
    final rebuilds = PerformanceMetrics.instance.totalRebuilds;
    expect(
      rebuilds,
      lessThanOrEqualTo(max),
      reason: 'Too many widget rebuilds detected: $rebuilds',
    );
  }

  /// Asserts that the performance score is at least [minScore].
  static void assertScore({int minScore = 80}) {
    final score = PerformanceScore.calculate().total;
    expect(
      score,
      greaterThanOrEqualTo(minScore),
      reason: 'Performance score too low: $score',
    );
  }

  /// Asserts that no critical warnings were generated.
  static void assertNoCriticalWarnings() {
    final criticalCount =
        PerformanceMetrics.instance.warnings
            .where(
              (w) => w.severity.index >= 2, // Critical
            )
            .length;
    expect(criticalCount, 0, reason: 'Critical performance warnings detected');
  }

  /// Generates a performance report as a JSON file.
  static Future<void> generateReport(String filePath) async {
    final metrics = PerformanceMetrics.instance.snapshot();
    final score = PerformanceScore.calculate();
    final warnings = PerformanceMetrics.instance.warnings;

    final report = {
      'timestamp': metrics.timestamp.toIso8601String(),
      'score': score.total,
      'metrics': {
        'fps': metrics.fps,
        'buildTimeMs': metrics.averageBuildTimeMs,
        'rasterTimeMs': metrics.averageRasterTimeMs,
        'memoryMB': metrics.memoryUsageMB,
        'rebuilds': metrics.totalRebuilds,
        'jankFrames': metrics.jankFrames,
      },
      'warnings':
          warnings
              .map(
                (w) => {
                  'message': w.message,
                  'severity': w.severity.toString(),
                  'suggestion': w.suggestion,
                },
              )
              .toList(),
    };

    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    debugPrint('âš¡ Performance report generated: ${file.absolute.path}');
  }
}
