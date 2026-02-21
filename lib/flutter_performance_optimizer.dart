/// A powerful developer tool that automatically detects performance issues
/// in Flutter apps and provides actionable suggestions to fix them.
///
/// ## Quick Start
///
/// Wrap your app with the optimizer:
///
/// ```dart
/// import 'package:flutter_performance_optimizer/flutter_performance_optimizer.dart';
///
/// void main() {
///   runApp(
///     PerformanceOptimizer(
///       enabled: true,
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
///
/// ## Features
///
/// - Detect excessive widget rebuilds
/// - Identify potential memory leaks
/// - Find large / expensive widgets
/// - Monitor FPS and frame rendering time
/// - Detect slow animations and jank
/// - Track widget tree depth
/// - Highlight unnecessary setState calls
/// - Performance overlay dashboard
/// - Automatic optimization suggestions
/// - Debug & release mode support
library;

// Core
export 'src/core/performance_config.dart';
export 'src/core/performance_metrics.dart';
export 'src/core/performance_warning.dart';
export 'src/core/performance_score.dart';
export 'src/core/performance_history.dart';

// Trackers
export 'src/trackers/rebuild_tracker.dart';
export 'src/trackers/memory_tracker.dart';
export 'src/trackers/frame_tracker.dart';
export 'src/trackers/animation_tracker.dart';
export 'src/trackers/widget_depth_tracker.dart';
export 'src/trackers/set_state_tracker.dart';
export 'src/trackers/widget_size_tracker.dart';
export 'src/trackers/heatmap_tracker.dart';
export 'src/trackers/profiling_tracker.dart';

// Suggestions
export 'src/suggestions/optimization_suggestion.dart';
export 'src/suggestions/suggestion_engine.dart';
export 'src/suggestions/ai_suggestion_service.dart';
export 'src/suggestions/performance_fixer.dart';

// Dashboard
export 'src/dashboard/performance_dashboard.dart';
export 'src/dashboard/dashboard_overlay.dart';
export 'src/dashboard/heatmap_overlay.dart';
export 'src/dashboard/widgets/fps_gauge.dart';
export 'src/dashboard/widgets/memory_chart.dart';
export 'src/dashboard/widgets/rebuild_list.dart';
export 'src/dashboard/widgets/suggestions_panel.dart';
export 'src/dashboard/widgets/metric_card.dart';
export 'src/dashboard/widgets/score_indicator.dart';
export 'src/dashboard/widgets/timeline_chart.dart';

// Widgets
export 'src/widgets/performance_optimizer_widget.dart';
export 'src/widgets/performance_inspector.dart';

// Utils
export 'src/utils/performance_utils.dart';
export 'src/utils/frame_timing_info.dart';
export 'src/utils/performance_test_helper.dart';
