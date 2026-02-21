import 'optimization_suggestion.dart';

/// Service that generates automatic code fixes for performance issues.
class PerformanceFixer {
  /// Generates a suggested code fix for a given suggestion.
  static String? generateFix(OptimizationSuggestion suggestion) {
    if (!suggestion.autoFixAvailable) return null;

    switch (suggestion.category) {
      case SuggestionCategory.rebuild:
        return _generateRebuildFix(suggestion);
      case SuggestionCategory.layout:
        return _generateLayoutFix(suggestion);
      case SuggestionCategory.list:
        return _generateListFix(suggestion);
      default:
        return suggestion.codeExample;
    }
  }

  static String _generateRebuildFix(OptimizationSuggestion suggestion) {
    final widgetName = suggestion.affectedWidget ?? 'Widget';
    return '''
// Before:
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Static Content'),
      $widgetName(), // Rebuilds every time Column rebuilds
    ],
  );
}

// After (Using RepaintBoundary or const):
Widget build(BuildContext context) {
  return Column(
    children: [
      const Text('Static Content'),
      const RepaintBoundary(
        child: $widgetName(),
      ),
    ],
  );
}
''';
  }

  static String _generateLayoutFix(OptimizationSuggestion suggestion) {
    return '''
// Optimization: Use Opacity widget sparingly.
// Before:
Opacity(opacity: 0.5, child: MyWidget())

// After (Better performance):
ColorFiltered(
  colorFilter: ColorFilter.mode(
    Colors.white.withValues(alpha: 0.5), 
    BlendMode.modulate,
  ),
  child: MyWidget(),
)
''';
  }

  static String _generateListFix(OptimizationSuggestion suggestion) {
    return '''
// Optimization: Use ListView.builder for long lists.
// Before:
ListView(
  children: items.map((i) => MyItem(i)).toList(),
)

// After (Lazy loading):
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => MyItem(items[index]),
)
''';
  }
}
