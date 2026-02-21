import '../core/performance_config.dart';
import '../core/performance_metrics.dart';
import '../core/performance_warning.dart';
import '../trackers/frame_tracker.dart';
import '../trackers/memory_tracker.dart';
import '../trackers/rebuild_tracker.dart';
import '../trackers/set_state_tracker.dart';
import '../trackers/widget_depth_tracker.dart';
import './ai_suggestion_service.dart';
import './optimization_suggestion.dart';

/// The optimization suggestions engine.
///
/// Analyzes current performance metrics and generates actionable
/// suggestions for improving app performance.
///
/// ```dart
/// final suggestions = SuggestionEngine.instance.generateSuggestions();
/// for (final s in suggestions) {
///   print(s);
/// }
/// ```
class SuggestionEngine {
  SuggestionEngine._();

  static final SuggestionEngine _instance = SuggestionEngine._();

  /// Singleton instance.
  static SuggestionEngine get instance => _instance;

  /// List of heuristic-based suggestions.
  final List<OptimizationSuggestion> _suggestions = [];

  /// List of AI-generated suggestions.
  final List<OptimizationSuggestion> _aiSuggestions = [];

  bool _isAnalyzingAI = false;

  /// Generates a list of optimization suggestions based on current metrics.
  List<OptimizationSuggestion> generateSuggestions() {
    _suggestions.clear();
    // _aiSuggestions are updated asynchronously, so we don't clear them here
    // to allow them to persist until new AI results are available.

    _suggestions.addAll(_analyzeRebuilds());
    _suggestions.addAll(_analyzeMemory());
    _suggestions.addAll(_analyzeFramePerformance());
    _suggestions.addAll(_analyzeSetStatePatterns());
    _suggestions.addAll(_analyzeWidgetDepth());
    _suggestions.addAll(_analyzeWidgetSize());
    _suggestions.addAll(_analyzeWarnings());

    // Trigger AI analysis asynchronously if not already running
    _triggerAIAnalysis();

    // Combine and sort all suggestions
    final allSuggestions = List<OptimizationSuggestion>.from(_suggestions)
      ..addAll(_aiSuggestions);

    // Sort by impact
    allSuggestions.sort((a, b) => b.impact.index.compareTo(a.impact.index));

    return allSuggestions;
  }

  void _triggerAIAnalysis() {
    if (AISuggestionService.instance.enabled && !_isAnalyzingAI) {
      _isAnalyzingAI = true;
      final snapshot = PerformanceMetrics.instance.snapshot();
      AISuggestionService.instance.analyze(snapshot).then((results) {
        _aiSuggestions.clear();
        _aiSuggestions.addAll(results);
        _isAnalyzingAI = false;
      });
    }
  }

  List<OptimizationSuggestion> _analyzeRebuilds() {
    final suggestions = <OptimizationSuggestion>[];
    final tracker = RebuildTracker.instance;

    final topRebuilders = tracker.topRebuilders(count: 5);
    for (final entry in topRebuilders) {
      if (entry.value > 100) {
        suggestions.add(
          OptimizationSuggestion(
            title: 'Excessive rebuilds: ${entry.key}',
            description:
                '"${entry.key}" has been rebuilt ${entry.value} times. '
                'This widget is rebuilding too frequently and may cause '
                'visible jank or wasted CPU cycles.',
            category: SuggestionCategory.rebuild,
            impact:
                entry.value > 500
                    ? SuggestionImpact.critical
                    : SuggestionImpact.high,
            affectedWidget: entry.key,
            codeExample: '''
// Before (causes unnecessary rebuilds):
Widget build(BuildContext context) {
  return Text(someValue); // Rebuilds parent tree
}

// After (reduces rebuilds):
const MyWidget(); // Use const constructor

// Or use ValueListenableBuilder:
ValueListenableBuilder<String>(
  valueListenable: myNotifier,
  builder: (context, value, child) => Text(value),
)''',
          ),
        );
      } else if (entry.value > 50) {
        suggestions.add(
          OptimizationSuggestion(
            title: 'Frequent rebuilds: ${entry.key}',
            description:
                '"${entry.key}" has been rebuilt ${entry.value} times. '
                'Consider optimizing to reduce rebuild frequency.',
            category: SuggestionCategory.rebuild,
            impact: SuggestionImpact.medium,
            affectedWidget: entry.key,
          ),
        );
      }
    }

    return suggestions;
  }

  List<OptimizationSuggestion> _analyzeMemory() {
    final suggestions = <OptimizationSuggestion>[];
    final tracker = MemoryTracker.instance;

    if (tracker.isLeaking) {
      suggestions.add(
        OptimizationSuggestion(
          title: 'Possible memory leak detected',
          description:
              'Memory usage is consistently increasing '
              '(current: ${tracker.currentUsageMB.toStringAsFixed(1)}MB, '
              'peak: ${tracker.peakUsageMB.toStringAsFixed(1)}MB). '
              'This pattern typically indicates a memory leak.',
          category: SuggestionCategory.memory,
          impact: SuggestionImpact.critical,
          codeExample: '''
// Common leak: Not disposing controllers
class MyWidget extends StatefulWidget {
  @override
  void dispose() {
    _controller.dispose(); // Always dispose!
    _subscription.cancel(); // Cancel stream subscriptions!
    super.dispose();
  }
}''',
        ),
      );
    }

    final undisposed = tracker.undisposedItems;
    for (final item in undisposed) {
      suggestions.add(
        OptimizationSuggestion(
          title: 'Undisposed resource: $item',
          description:
              '"$item" was created but not yet disposed. This will cause '
              'a memory leak if not properly cleaned up.',
          category: SuggestionCategory.memory,
          impact: SuggestionImpact.high,
          codeExample: '''
@override
void dispose() {
  $item.dispose();
  super.dispose();
}''',
        ),
      );
    }

    if (tracker.currentUsageMB > 300) {
      suggestions.add(
        OptimizationSuggestion(
          title: 'High memory usage',
          description:
              'App is using ${tracker.currentUsageMB.toStringAsFixed(1)}MB '
              'of memory. Consider optimizing image loading and data caching.',
          category: SuggestionCategory.memory,
          impact:
              tracker.currentUsageMB > 500
                  ? SuggestionImpact.critical
                  : SuggestionImpact.medium,
          codeExample: '''
// Use cached_network_image for network images:
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 300, // Limit cache size
)

// Use ListView.builder for long lists:
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)''',
        ),
      );
    }

    return suggestions;
  }

  List<OptimizationSuggestion> _analyzeFramePerformance() {
    final suggestions = <OptimizationSuggestion>[];
    final tracker = FrameTracker.instance;

    if (tracker.currentFps < 50) {
      suggestions.add(
        OptimizationSuggestion(
          title: 'Low FPS detected',
          description:
              'App is running at ${tracker.currentFps.toStringAsFixed(1)} FPS. '
              'Target is 60 FPS for smooth performance.',
          category: SuggestionCategory.animation,
          impact:
              tracker.currentFps < 30
                  ? SuggestionImpact.critical
                  : SuggestionImpact.high,
          codeExample: '''
// Add RepaintBoundary around complex widgets:
RepaintBoundary(
  child: ComplexWidget(),
)

// Move expensive operations out of build():
class MyWidget extends StatelessWidget {
  // Cache expensive computations
  static final _processedData = _computeExpensiveData();
  
  @override
  Widget build(BuildContext context) {
    return DataWidget(data: _processedData);
  }
}''',
        ),
      );
    }

    if (tracker.isJanking) {
      suggestions.add(
        OptimizationSuggestion(
          title: 'Animation jank detected',
          description:
              'Multiple frames exceeded the 16ms budget recently. '
              'Average frame time: '
              '${(tracker.averageFrameTime.inMicroseconds / 1000).toStringAsFixed(1)}ms.',
          category: SuggestionCategory.animation,
          impact: SuggestionImpact.high,
          codeExample: '''
// Use RepaintBoundary to isolate animations:
RepaintBoundary(
  child: AnimatedWidget(),
)

// Avoid layout-triggering operations during animation:
// Bad: Changing constraints during animation
// Good: Only change paint properties (opacity, transform)''',
        ),
      );
    }

    return suggestions;
  }

  List<OptimizationSuggestion> _analyzeSetStatePatterns() {
    final suggestions = <OptimizationSuggestion>[];
    final tracker = SetStateTracker.instance;

    final topCallers = tracker.topCallers(count: 5);
    for (final entry in topCallers) {
      if (entry.value > 20) {
        suggestions.add(
          OptimizationSuggestion(
            title: 'Frequent setState in ${entry.key}',
            description:
                '"${entry.key}" has called setState ${entry.value} times. '
                'Consider using more targeted state management.',
            category: SuggestionCategory.stateManagement,
            impact:
                entry.value > 50
                    ? SuggestionImpact.high
                    : SuggestionImpact.medium,
            affectedWidget: entry.key,
            codeExample: '''
// Instead of setState for individual values:
// Bad:
setState(() { _count++; });

// Good — use ValueNotifier:
final _count = ValueNotifier<int>(0);

ValueListenableBuilder<int>(
  valueListenable: _count,
  builder: (_, count, __) => Text('\$count'),
)

// Increment without rebuilding entire widget:
_count.value++;''',
          ),
        );
      }
    }

    return suggestions;
  }

  List<OptimizationSuggestion> _analyzeWidgetDepth() {
    final suggestions = <OptimizationSuggestion>[];
    final tracker = WidgetDepthTracker.instance;

    if (tracker.lastMeasuredDepth > 30) {
      suggestions.add(
        OptimizationSuggestion(
          title: 'Deep widget tree detected',
          description:
              'Widget tree depth is ${tracker.lastMeasuredDepth} levels '
              'with ${tracker.lastMeasuredWidgetCount} total widgets. '
              'Deep trees can slow down layout calculations.',
          category: SuggestionCategory.layout,
          impact:
              tracker.lastMeasuredDepth > 50
                  ? SuggestionImpact.critical
                  : SuggestionImpact.medium,
          codeExample: '''
// Break down large widgets:
// Before:
Widget build(BuildContext context) {
  return Column(
    children: [
      // ... 20 nested widgets
    ],
  );
}

// After:
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildHeader(),
      _buildContent(),
      _buildFooter(),
    ],
  );
}''',
        ),
      );
    }

    return suggestions;
  }

  List<OptimizationSuggestion> _analyzeWidgetSize() {
    final suggestions = <OptimizationSuggestion>[];
    final warnings = PerformanceWarningManager.instance;

    // Look for large widget warnings
    final largeWidgetWarnings = warnings.byType(WarningType.largeWidget);

    final handledWidgets = <String>{};
    for (final warning in largeWidgetWarnings) {
      final name = warning.widgetName;
      if (name == null || handledWidgets.contains(name)) continue;
      handledWidgets.add(name);

      suggestions.add(
        OptimizationSuggestion(
          title: 'Oversized widget detected: $name',
          description:
              'The widget "$name" is rendering with an exceptionally '
              'large size. This can lead to excessive memory usage and '
              'slow rasterization times.',
          category: SuggestionCategory.layout,
          impact: SuggestionImpact.high,
          affectedWidget: name,
          codeExample: '''
// Use ListView.builder for large lists:
ListView.builder(
  itemCount: 1000,
  itemBuilder: (context, index) => ListItem(),
)

// Add RepaintBoundary to isolate updates:
RepaintBoundary(
  child: LargeComplexWidget(),
)''',
        ),
      );
    }

    return suggestions;
  }

  List<OptimizationSuggestion> _analyzeWarnings() {
    final suggestions = <OptimizationSuggestion>[];
    final warnings = PerformanceWarningManager.instance;

    // Count warnings by type
    final typeCount = <WarningType, int>{};
    for (final w in warnings.warnings) {
      typeCount[w.type] = (typeCount[w.type] ?? 0) + 1;
    }

    for (final entry in typeCount.entries) {
      if (entry.value >= 5) {
        final typeName = entry.key.name;
        suggestions.add(
          OptimizationSuggestion(
            title: 'Recurring issue: $typeName',
            description:
                'There have been ${entry.value} "$typeName" warnings. '
                'This indicates a systematic issue that should be addressed.',
            category: SuggestionCategory.general,
            impact:
                entry.value > 10
                    ? SuggestionImpact.high
                    : SuggestionImpact.medium,
          ),
        );
      }
    }

    return suggestions;
  }

  /// Generates a formatted report of all suggestions.
  String generateReport() {
    final suggestions = generateSuggestions();
    if (suggestions.isEmpty) {
      return '✅ No performance issues detected! Your app looks great.';
    }

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('  🔍 Performance Optimization Report');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();

    final critical = suggestions.where(
      (s) => s.impact == SuggestionImpact.critical,
    );
    final high = suggestions.where((s) => s.impact == SuggestionImpact.high);
    final medium = suggestions.where(
      (s) => s.impact == SuggestionImpact.medium,
    );
    final low = suggestions.where((s) => s.impact == SuggestionImpact.low);

    if (critical.isNotEmpty) {
      buffer.writeln('🔴 CRITICAL (${critical.length}):');
      for (final s in critical) {
        buffer.writeln('  • ${s.title}');
        buffer.writeln('    ${s.description}');
        buffer.writeln();
      }
    }

    if (high.isNotEmpty) {
      buffer.writeln('🟠 HIGH IMPACT (${high.length}):');
      for (final s in high) {
        buffer.writeln('  • ${s.title}');
        buffer.writeln('    ${s.description}');
        buffer.writeln();
      }
    }

    if (medium.isNotEmpty) {
      buffer.writeln('🟡 MEDIUM IMPACT (${medium.length}):');
      for (final s in medium) {
        buffer.writeln('  • ${s.title}');
        buffer.writeln('    ${s.description}');
        buffer.writeln();
      }
    }

    if (low.isNotEmpty) {
      buffer.writeln('🟢 LOW IMPACT (${low.length}):');
      for (final s in low) {
        buffer.writeln('  • ${s.title}');
        buffer.writeln('    ${s.description}');
        buffer.writeln();
      }
    }

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('  Total: ${suggestions.length} suggestions');
    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }
}
