import 'package:flutter/material.dart';

import '../../core/performance_config.dart';
import '../../core/performance_warning.dart';
import '../../suggestions/optimization_suggestion.dart';
import '../../suggestions/suggestion_engine.dart';
import '../../suggestions/performance_fixer.dart';

/// Suggestions panel for the dashboard.
///
/// Displays optimization suggestions and recent warnings.
class SuggestionsPanel extends StatelessWidget {
  /// Creates a [SuggestionsPanel].
  const SuggestionsPanel({
    super.key,
    required this.engine,
    required this.warningManager,
  });

  /// Suggestion engine.
  final SuggestionEngine engine;

  /// Warning manager.
  final PerformanceWarningManager warningManager;

  @override
  Widget build(BuildContext context) {
    final suggestions = engine.generateSuggestions();
    final recentWarnings = warningManager.warnings.reversed.take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (suggestions.isEmpty && recentWarnings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No issues detected! 🎉',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your app is running well.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Suggestions
          if (suggestions.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.lightbulb, size: 14, color: Color(0xFFFFC107)),
                const SizedBox(width: 6),
                Text(
                  'Suggestions (${suggestions.length})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...suggestions.take(8).map((s) => _SuggestionCard(suggestion: s)),
          ],

          // Recent warnings
          if (recentWarnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  size: 14,
                  color: Color(0xFFF44336),
                ),
                const SizedBox(width: 6),
                Text(
                  'Recent Warnings (${recentWarnings.length})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...recentWarnings.map((w) => _WarningCard(warning: w)),
          ],
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});

  final OptimizationSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final color = switch (suggestion.impact) {
      SuggestionImpact.critical => const Color(0xFFF44336),
      SuggestionImpact.high => const Color(0xFFFF9800),
      SuggestionImpact.medium => const Color(0xFFFFC107),
      SuggestionImpact.low => const Color(0xFF4CAF50),
    };

    final emoji = switch (suggestion.impact) {
      SuggestionImpact.critical => '🔴',
      SuggestionImpact.high => '🟠',
      SuggestionImpact.medium => '🟡',
      SuggestionImpact.low => '🟢',
    };

    return Semantics(
      label: 'Suggestion: ${suggestion.title}. ${suggestion.description}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 10,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      suggestion.title,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                suggestion.description,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  decoration: TextDecoration.none,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (suggestion.autoFixAvailable ||
                  suggestion.codeExample != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => _FixDialog(suggestion: suggestion),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_fix_high, size: 10, color: color),
                        const SizedBox(width: 4),
                        Text(
                          suggestion.autoFixAvailable
                              ? 'GENERATE FIX'
                              : 'VIEW EXAMPLE',
                          style: TextStyle(
                            color: color,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FixDialog extends StatelessWidget {
  const _FixDialog({required this.suggestion});
  final OptimizationSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final fix =
        suggestion.autoFixAvailable
            ? PerformanceFixer.generateFix(suggestion)
            : suggestion.codeExample;

    return Dialog(
      backgroundColor: const Color(0xFF1A1B2E),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.rocket_launch,
                  color: Color(0xFF4CAF50),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  suggestion.autoFixAvailable
                      ? 'Performance Auto-Fix'
                      : 'Optimization Example',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              suggestion.title,
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0E1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2D2F4A)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  fix ?? 'No example available.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('GOT IT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.warning});

  final PerformanceWarningData warning;

  @override
  Widget build(BuildContext context) {
    final color = switch (warning.severity) {
      WarningSeverity.critical => const Color(0xFFF44336),
      WarningSeverity.warning => const Color(0xFFFFC107),
      WarningSeverity.info => const Color(0xFF2196F3),
    };

    return Semantics(
      label: 'Warning: ${warning.message}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0E1A),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  warning.message,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
