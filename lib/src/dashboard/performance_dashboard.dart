import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/performance_config.dart';
import '../core/performance_metrics.dart';
import '../core/performance_score.dart';
import '../core/performance_warning.dart';
import '../suggestions/suggestion_engine.dart';
import '../trackers/frame_tracker.dart';
import '../trackers/memory_tracker.dart';
import '../trackers/rebuild_tracker.dart';
import '../core/performance_history.dart';
import 'widgets/fps_gauge.dart';
import 'widgets/memory_chart.dart';
import 'widgets/metric_card.dart';
import 'widgets/rebuild_list.dart';
import 'widgets/score_indicator.dart';
import 'widgets/suggestions_panel.dart';
import 'widgets/timeline_chart.dart';
import '../trackers/heatmap_tracker.dart';

/// Full performance dashboard widget.
///
/// Displays comprehensive performance metrics including FPS, memory,
/// rebuilds, suggestions, and more.
///
/// Typically shown via the [DashboardOverlay], but can be used standalone:
///
/// ```dart
/// PerformanceDashboard(
///   config: PerformanceConfig(enabled: true),
/// )
/// ```
class PerformanceDashboard extends StatefulWidget {
  /// Creates a [PerformanceDashboard].
  const PerformanceDashboard({super.key, required this.config, this.onClose});

  /// Configuration.
  final PerformanceConfig config;

  /// Callback when the close button is tapped.
  final VoidCallback? onClose;

  @override
  State<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard>
    with SingleTickerProviderStateMixin {
  Timer? _updateTimer;
  late TabController _tabController;

  double _fps = 60;
  double _memoryMB = 0;
  int _rebuilds = 0;
  int _jankFrames = 0;
  int _warningCount = 0;
  PerformanceScore? _score;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _startUpdating();
  }

  void _startUpdating() {
    _updateMetrics();
    _updateTimer = Timer.periodic(
      widget.config.fpsUpdateInterval,
      (_) => _updateMetrics(),
    );
  }

  void _updateMetrics() {
    if (!mounted) return;

    final metrics = PerformanceMetrics.instance;
    setState(() {
      _fps = metrics.fps;
      _memoryMB = metrics.memoryUsageMB;
      _rebuilds = metrics.totalRebuilds;
      _jankFrames = metrics.jankFrames;
      _warningCount = metrics.warningCount;
      _score = PerformanceScore.calculate();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 380,
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1B2E).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildScoreBar(),
              _buildMetricCards(),
              _buildTabBar(),
              Flexible(child: _buildTabContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.speed, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '⚡ Performance Monitor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          if (_score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _scoreColor(_score!.total).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _scoreColor(_score!.total), width: 1),
              ),
              child: Text(
                '${_score!.total}/100',
                style: TextStyle(
                  color: _scoreColor(_score!.total),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          if (widget.onClose != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  HeatmapTracker.instance.isEnabled =
                      !HeatmapTracker.instance.isEnabled;
                });
              },
              child: Icon(
                Icons.layers_outlined,
                color:
                    HeatmapTracker.instance.isEnabled
                        ? Colors.orange
                        : Colors.white70,
                size: 18,
                semanticLabel: 'Toggle Heatmap',
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onClose,
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    if (_score == null) return const SizedBox.shrink();
    return ScoreIndicator(score: _score!);
  }

  Widget _buildMetricCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: MetricCard(
              label: 'FPS',
              value: _fps.toStringAsFixed(0),
              icon: Icons.speed,
              color: _fpsColor(_fps),
              subtitle:
                  _fps >= 55
                      ? 'Smooth'
                      : _fps >= 40
                      ? 'Fair'
                      : 'Slow',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: MetricCard(
              label: 'Memory',
              value:
                  _memoryMB > 0 ? '${_memoryMB.toStringAsFixed(0)}MB' : 'N/A',
              icon: Icons.memory,
              color: _memoryColor(_memoryMB),
              subtitle: MemoryTracker.instance.isLeaking ? '⚠ Leak?' : 'OK',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: MetricCard(
              label: 'Rebuilds',
              value: _formatCountShort(_rebuilds),
              icon: Icons.refresh,
              color: _rebuildColor(_rebuilds),
              subtitle: '$_jankFrames jank',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: MetricCard(
              label: 'Warnings',
              value: '$_warningCount',
              icon: Icons.warning_amber,
              color: _warningCount > 0 ? Colors.orange : Colors.green,
              subtitle: _warningCount == 0 ? 'Clean' : 'Review',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2D2F4A), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF6C63FF),
        unselectedLabelColor: Colors.white54,
        indicatorColor: const Color(0xFF6C63FF),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: '📊 FPS'),
          Tab(text: '🧠 Memory'),
          Tab(text: '🔄 Rebuilds'),
          Tab(text: '📈 Timeline'),
          Tab(text: '💡 Suggestions'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        FpsGauge(fps: _fps, frameTracker: FrameTracker.instance),
        MemoryChart(memoryTracker: MemoryTracker.instance),
        RebuildList(rebuildTracker: RebuildTracker.instance),
        TimelineChart(history: PerformanceHistoryManager.instance.history),
        SuggestionsPanel(
          engine: SuggestionEngine.instance,
          warningManager: PerformanceWarningManager.instance,
        ),
      ],
    );
  }

  Color _fpsColor(double fps) {
    if (fps >= 55) return const Color(0xFF4CAF50);
    if (fps >= 40) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  Color _memoryColor(double mb) {
    if (mb <= 0) return const Color(0xFF4CAF50);
    if (mb < 200) return const Color(0xFF4CAF50);
    if (mb < 400) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  Color _rebuildColor(int count) {
    if (count < 100) return const Color(0xFF4CAF50);
    if (count < 500) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  String _formatCountShort(int count) {
    if (count < 1000) return '$count';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
