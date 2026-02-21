/// Represents an optimization suggestion.
///
/// Contains actionable advice to improve app performance.
class OptimizationSuggestion {
  /// Creates an [OptimizationSuggestion].
  const OptimizationSuggestion({
    required this.title,
    required this.description,
    required this.category,
    required this.impact,
    this.codeExample,
    this.affectedWidget,
    this.autoFixAvailable = false,
  });

  /// Short title of the suggestion.
  final String title;

  /// Detailed description of what to do.
  final String description;

  /// Category of the suggestion.
  final SuggestionCategory category;

  /// Estimated impact on performance.
  final SuggestionImpact impact;

  /// Optional code example showing the fix.
  final String? codeExample;

  /// The widget this suggestion relates to.
  final String? affectedWidget;

  /// Whether an automatic fix is available.
  final bool autoFixAvailable;

  @override
  String toString() =>
      '[$impact] $title\n  $description'
      '${codeExample != null ? '\n  Example:\n$codeExample' : ''}';
}

/// Category of an optimization suggestion.
enum SuggestionCategory {
  /// Rebuild optimization.
  rebuild,

  /// Memory optimization.
  memory,

  /// Layout optimization.
  layout,

  /// Animation optimization.
  animation,

  /// State management optimization.
  stateManagement,

  /// Image optimization.
  image,

  /// List optimization.
  list,

  /// General best practice.
  general,
}

/// Estimated impact level.
enum SuggestionImpact {
  /// Low impact change.
  low,

  /// Medium impact change.
  medium,

  /// High impact change.
  high,

  /// Critical — must fix.
  critical,
}
