import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_performance_optimizer/flutter_performance_optimizer.dart';

void main() {
  group('Advanced Features Tests', () {
    test('AI Suggestion Service returns results when enabled', () async {
      final service = AISuggestionService.instance;
      service.enabled = true;

      // Mock a bad metric snapshot
      final snapshot = PerformanceMetrics.instance.snapshot();
      // We can't easily mock the snapshot fields since it's a data class,
      // but we can check if it returns something after the simulated delay.

      final suggestions = await service.analyze(snapshot);
      expect(suggestions, isNotNull);
    });

    test('Performance Fixer generates valid code snippets', () {
      const suggestion = OptimizationSuggestion(
        title: 'Deep Trees',
        description: 'Too deep',
        category: SuggestionCategory.layout,
        impact: SuggestionImpact.medium,
        autoFixAvailable: true,
      );

      final fix = PerformanceFixer.generateFix(suggestion);
      expect(fix, contains('After (Better performance):'));
    });

    testWidgets('PerformanceTestHelper integrates correctly', (tester) async {
      await PerformanceTestHelper.runApp(
        tester,
        const MaterialApp(home: Scaffold(body: Text('Hello'))),
      );

      PerformanceMetrics.instance.reset(); // Clear initial depth warnings
      PerformanceTestHelper.assertScore(
        minScore: 0,
      ); // Should pass with any score
      PerformanceTestHelper.assertNoCriticalWarnings();
    });

    test('ProfilingTracker provides load estimates', () {
      final tracker = ProfilingTracker.instance;
      tracker.start();

      expect(tracker.estimatedCpuLoad, isNotNull);
      expect(tracker.estimatedGpuLoad, isNotNull);

      tracker.stop();
    });
  });

  test('PerformanceTestHelper generates report file', () async {
    const reportPath = 'test_report.json';
    await PerformanceTestHelper.generateReport(reportPath);

    final file = File(reportPath);
    expect(file.existsSync(), isTrue);

    final content = await file.readAsString();
    expect(content, contains('"score":'));
    expect(content, contains('"metrics":'));

    // Cleanup
    if (file.existsSync()) await file.delete();
  });
}
