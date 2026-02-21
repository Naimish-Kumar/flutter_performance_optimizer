import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_performance_optimizer/flutter_performance_optimizer.dart';

void main() {
  group('PerformanceConfig', () {
    test('default values are correct', () {
      const config = PerformanceConfig();

      expect(config.enabled, true);
      expect(config.trackRebuilds, true);
      expect(config.trackMemory, true);
      expect(config.trackAnimations, true);
      expect(config.trackWidgetSize, true);
      expect(config.trackWidgetDepth, true);
      expect(config.trackSetState, true);
      expect(config.showDashboard, false);
      expect(config.warningThreshold, const Duration(milliseconds: 16));
      expect(config.rebuildWarningCount, 60);
      expect(config.maxWidgetDepth, 30);
      expect(config.logWarnings, true);
      expect(config.enableInReleaseMode, false);
    });

    test('copyWith creates correct copy', () {
      const config = PerformanceConfig();
      final modified = config.copyWith(
        enabled: false,
        showDashboard: true,
        maxWidgetDepth: 50,
      );

      expect(modified.enabled, false);
      expect(modified.showDashboard, true);
      expect(modified.maxWidgetDepth, 50);
      // Unchanged values
      expect(modified.trackRebuilds, true);
      expect(modified.warningThreshold, const Duration(milliseconds: 16));
    });
  });

  group('RebuildTracker', () {
    setUp(() {
      RebuildTracker.instance.reset();
    });

    test('tracks rebuilds correctly', () {
      RebuildTracker.instance.start();

      RebuildTracker.instance.trackRebuild('WidgetA');
      RebuildTracker.instance.trackRebuild('WidgetA');
      RebuildTracker.instance.trackRebuild('WidgetB');

      expect(RebuildTracker.instance.totalRebuilds, 3);
      expect(RebuildTracker.instance.rebuildCounts['WidgetA'], 2);
      expect(RebuildTracker.instance.rebuildCounts['WidgetB'], 1);

      RebuildTracker.instance.stop();
    });

    test('does not track when stopped', () {
      RebuildTracker.instance.trackRebuild('WidgetA');
      expect(RebuildTracker.instance.totalRebuilds, 0);
    });

    test('topRebuilders returns sorted results', () {
      RebuildTracker.instance.start();

      for (int i = 0; i < 10; i++) {
        RebuildTracker.instance.trackRebuild('WidgetA');
      }
      for (int i = 0; i < 5; i++) {
        RebuildTracker.instance.trackRebuild('WidgetB');
      }
      for (int i = 0; i < 20; i++) {
        RebuildTracker.instance.trackRebuild('WidgetC');
      }

      final top = RebuildTracker.instance.topRebuilders(count: 2);
      expect(top.length, 2);
      expect(top[0].key, 'WidgetC');
      expect(top[0].value, 20);
      expect(top[1].key, 'WidgetA');
      expect(top[1].value, 10);

      RebuildTracker.instance.stop();
    });

    test('reset clears all data', () {
      RebuildTracker.instance.start();
      RebuildTracker.instance.trackRebuild('WidgetA');
      RebuildTracker.instance.reset();

      expect(RebuildTracker.instance.totalRebuilds, 0);
      expect(RebuildTracker.instance.rebuildCounts, isEmpty);
    });
  });

  group('SetStateTracker', () {
    setUp(() {
      SetStateTracker.instance.reset();
    });

    test('tracks setState calls', () {
      SetStateTracker.instance.start();

      SetStateTracker.instance.trackSetState('WidgetA');
      SetStateTracker.instance.trackSetState('WidgetA');

      expect(SetStateTracker.instance.totalSetStateCalls, 2);
      expect(SetStateTracker.instance.setStateCounts['WidgetA'], 2);

      SetStateTracker.instance.stop();
    });

    test('topCallers returns correct results', () {
      SetStateTracker.instance.start();

      for (int i = 0; i < 5; i++) {
        SetStateTracker.instance.trackSetState('WidgetA');
      }
      for (int i = 0; i < 3; i++) {
        SetStateTracker.instance.trackSetState('WidgetB');
      }

      final top = SetStateTracker.instance.topCallers(count: 1);
      expect(top.length, 1);
      expect(top[0].key, 'WidgetA');

      SetStateTracker.instance.stop();
    });
  });

  group('PerformanceWarningManager', () {
    setUp(() {
      PerformanceWarningManager.instance.clear();
    });

    test('reports and stores warnings', () {
      const warning = PerformanceWarningData(
        message: 'Test warning',
        type: WarningType.excessiveRebuilds,
        severity: WarningSeverity.warning,
      );

      PerformanceWarningManager.instance.report(warning);

      expect(PerformanceWarningManager.instance.count, 1);
      expect(
        PerformanceWarningManager.instance.warnings.first.message,
        'Test warning',
      );
    });

    test('filters by type', () {
      PerformanceWarningManager.instance.report(
        const PerformanceWarningData(
          message: 'Rebuild warning',
          type: WarningType.excessiveRebuilds,
          severity: WarningSeverity.warning,
        ),
      );
      PerformanceWarningManager.instance.report(
        const PerformanceWarningData(
          message: 'Memory warning',
          type: WarningType.memoryLeak,
          severity: WarningSeverity.critical,
        ),
      );

      final rebuilds = PerformanceWarningManager.instance.byType(
        WarningType.excessiveRebuilds,
      );
      expect(rebuilds.length, 1);
      expect(rebuilds.first.message, 'Rebuild warning');
    });

    test('filters by severity', () {
      PerformanceWarningManager.instance.report(
        const PerformanceWarningData(
          message: 'Info',
          type: WarningType.slowFrame,
          severity: WarningSeverity.info,
        ),
      );
      PerformanceWarningManager.instance.report(
        const PerformanceWarningData(
          message: 'Critical',
          type: WarningType.memoryLeak,
          severity: WarningSeverity.critical,
        ),
      );

      expect(PerformanceWarningManager.instance.criticalCount, 1);
      expect(PerformanceWarningManager.instance.infoCount, 1);
    });

    test('notifies listeners', () {
      PerformanceWarningData? received;
      PerformanceWarningManager.instance.addListener((w) => received = w);

      PerformanceWarningManager.instance.report(
        const PerformanceWarningData(
          message: 'Test',
          type: WarningType.slowFrame,
          severity: WarningSeverity.warning,
        ),
      );

      expect(received, isNotNull);
      expect(received!.message, 'Test');
    });
  });

  group('PerformanceScore', () {
    test('calculates score', () {
      final score = PerformanceScore.calculate();

      expect(score.total, greaterThanOrEqualTo(0));
      expect(score.total, lessThanOrEqualTo(100));
      expect(score.grade, isNotEmpty);
    });
  });

  group('MemoryTracker', () {
    setUp(() {
      MemoryTracker.instance.reset();
    });

    test('tracks disposable resources', () {
      MemoryTracker.instance.trackDisposable('controller1');
      MemoryTracker.instance.trackDisposable('controller2');

      expect(MemoryTracker.instance.undisposedItems, [
        'controller1',
        'controller2',
      ]);

      MemoryTracker.instance.markDisposed('controller1');
      expect(MemoryTracker.instance.undisposedItems, ['controller2']);
    });
  });

  group('SuggestionEngine', () {
    test('generates suggestions list', () {
      final suggestions = SuggestionEngine.instance.generateSuggestions();
      expect(suggestions, isList);
    });

    test('generates report string', () {
      final report = SuggestionEngine.instance.generateReport();
      expect(report, isA<String>());
      expect(report, isNotEmpty);
    });
  });

  group('PerformanceUtils', () {
    test('formatDuration formats correctly', () {
      expect(
        PerformanceUtils.formatDuration(const Duration(microseconds: 500)),
        '500µs',
      );
      expect(
        PerformanceUtils.formatDuration(const Duration(milliseconds: 16)),
        '16.0ms',
      );
      expect(
        PerformanceUtils.formatDuration(const Duration(seconds: 2)),
        '2.00s',
      );
    });

    test('formatMemory formats correctly', () {
      expect(PerformanceUtils.formatMemory(0.5), '512 KB');
      expect(PerformanceUtils.formatMemory(256.0), '256.0 MB');
      expect(PerformanceUtils.formatMemory(2048.0), '2.00 GB');
    });

    test('formatCount abbreviates correctly', () {
      expect(PerformanceUtils.formatCount(42), '42');
      expect(PerformanceUtils.formatCount(1500), '1.5K');
      expect(PerformanceUtils.formatCount(2500000), '2.5M');
    });
  });

  group('PerformanceOptimizer widget', () {
    testWidgets('renders child when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PerformanceOptimizer(enabled: false, child: Text('Hello')),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders child when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PerformanceOptimizer(enabled: true, child: Text('Hello')),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('shows dashboard when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PerformanceOptimizer(
            enabled: true,
            showDashboard: true,
            child: Scaffold(body: Text('App')),
          ),
        ),
      );

      expect(find.text('App'), findsOneWidget);
      // Dashboard overlay should be in the tree
      expect(find.text('⚡ Performance Monitor'), findsOneWidget);
    });
  });

  group('PerformanceInspector widget', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PerformanceInspector(name: 'Test', child: Text('Inspected')),
        ),
      );

      expect(find.text('Inspected'), findsOneWidget);
    });

    testWidgets('shows badge when enabled', (tester) async {
      RebuildTracker.instance.start();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PerformanceInspector(
              name: 'Test',
              showBadge: true,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      // Badge should contain widget name
      expect(find.textContaining('Test:'), findsOneWidget);

      RebuildTracker.instance.stop();
    });
  });
}
