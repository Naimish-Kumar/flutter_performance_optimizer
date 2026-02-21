import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/performance_metrics.dart';
import '../suggestions/optimization_suggestion.dart';

/// Service for generating AI-powered optimization suggestions.
class AISuggestionService {
  AISuggestionService._();

  static final AISuggestionService _instance = AISuggestionService._();

  /// Singleton instance.
  static AISuggestionService get instance => _instance;

  /// Whether AI suggestions are enabled.
  bool enabled = false;

  /// API Key for Gemini.
  /// Get your key from https://aistudio.google.com/
  String? apiKey;

  GenerativeModel? _model;

  void _initModel() {
    if (_model != null || apiKey == null) return;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey!,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  /// Generates AI suggestions based on a metrics snapshot.
  Future<List<OptimizationSuggestion>> analyze(MetricsSnapshot snapshot) async {
    if (!enabled) return [];

    final suggestions = <OptimizationSuggestion>[];

    // 1. Add Heuristic-based suggestions (Fast, Offline)
    suggestions.addAll(_getHeuristicSuggestions(snapshot));

    // 2. Add Gemini-based suggestions (Deep insights)
    if (apiKey != null) {
      try {
        final geminiResults = await _getGeminiSuggestions(snapshot);
        suggestions.addAll(geminiResults);
      } catch (e) {
        debugPrint('âš¡ AISuggestionService: Gemini analysis failed: $e');
      }
    }

    return suggestions;
  }

  List<OptimizationSuggestion> _getHeuristicSuggestions(
    MetricsSnapshot snapshot,
  ) {
    final aiSuggestions = <OptimizationSuggestion>[];

    if (snapshot.averageBuildTimeMs > 10 && snapshot.totalRebuilds > 500) {
      aiSuggestions.add(
        const OptimizationSuggestion(
          title: '🤖 AI: Architectural Bloat Detected',
          description:
              'Patterns suggest deep widget tree rebuilds are causing '
              'cascading builds. Consider implementing a RepaintBoundary '
              'and moving state closer to leaf nodes.',
          category: SuggestionCategory.rebuild,
          impact: SuggestionImpact.critical,
        ),
      );
    }

    if (snapshot.memoryUsageMB > 350 && snapshot.fps < 40) {
      aiSuggestions.add(
        const OptimizationSuggestion(
          title: '🤖 AI: GC Pressure Identified',
          description:
              'High memory usage combined with low FPS indicates '
              'heavy Garbage Collection pressure. Check for frequent '
              'object allocations in scroll listeners.',
          category: SuggestionCategory.memory,
          impact: SuggestionImpact.high,
        ),
      );
    }

    if (snapshot.maxWidgetDepth > 40) {
      aiSuggestions.add(
        OptimizationSuggestion(
          title: '🤖 AI: Deep Tree Complexity',
          description:
              'A widget depth of ${snapshot.maxWidgetDepth} is unusually high. '
              'AI analysis suggests refactoring the layout into smaller, '
              'compositional widgets.',
          category: SuggestionCategory.layout,
          impact: SuggestionImpact.medium,
          autoFixAvailable: true,
        ),
      );
    }

    if (snapshot.fps < 50 && snapshot.averageRasterTimeMs > 12) {
      aiSuggestions.add(
        const OptimizationSuggestion(
          title: '🤖 AI: GPU Bottleneck Detected',
          description:
              'High rasterization times suggest complex graphics. '
              'AI recommends simplifying ClipRRect or Opacity usage.',
          category: SuggestionCategory.animation,
          impact: SuggestionImpact.high,
          autoFixAvailable: true,
        ),
      );
    }

    return aiSuggestions;
  }

  Future<List<OptimizationSuggestion>> _getGeminiSuggestions(
    MetricsSnapshot snapshot,
  ) async {
    _initModel();
    if (_model == null) return [];

    final prompt = '''
    Analyze these Flutter performance metrics and provide optimization suggestions in JSON format.
    Metrics:
    - FPS: ${snapshot.fps}
    - Build Time: ${snapshot.averageBuildTimeMs}ms
    - Raster Time: ${snapshot.averageRasterTimeMs}ms
    - Memory: ${snapshot.memoryUsageMB.toStringAsFixed(1)}MB
    - Total Rebuilds: ${snapshot.totalRebuilds}
    - Max Widget Depth: ${snapshot.maxWidgetDepth}
    - Jank Frames: ${snapshot.jankFrames}

    Return a JSON list of objects with these fields:
    - title: String (prefixed with "✨ Gemini:")
    - description: String
    - category: "rebuild", "memory", "layout", "animation", "stateManagement", or "general"
    - impact: "low", "medium", "high", or "critical"
    - autoFixAvailable: boolean
    ''';

    final content = [Content.text(prompt)];
    final response = await _model!.generateContent(content);
    final text = response.text;

    if (text == null) return [];

    final List<dynamic> data = jsonDecode(text);
    return data.map((item) {
      return OptimizationSuggestion(
        title: item['title'] ?? 'Gemini Suggestion',
        description: item['description'] ?? '',
        category: _parseCategory(item['category']),
        impact: _parseImpact(item['impact']),
        autoFixAvailable: item['autoFixAvailable'] ?? false,
      );
    }).toList();
  }

  SuggestionCategory _parseCategory(String? category) {
    switch (category) {
      case 'rebuild':
        return SuggestionCategory.rebuild;
      case 'memory':
        return SuggestionCategory.memory;
      case 'layout':
        return SuggestionCategory.layout;
      case 'animation':
        return SuggestionCategory.animation;
      case 'stateManagement':
        return SuggestionCategory.stateManagement;
      default:
        return SuggestionCategory.general;
    }
  }

  SuggestionImpact _parseImpact(String? impact) {
    switch (impact) {
      case 'critical':
        return SuggestionImpact.critical;
      case 'high':
        return SuggestionImpact.high;
      case 'medium':
        return SuggestionImpact.medium;
      default:
        return SuggestionImpact.low;
    }
  }
}
