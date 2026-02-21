import 'package:flutter/material.dart';

import '../../core/performance_score.dart';

/// A compact score indicator bar.
///
/// Displays the overall performance score with a gradient progress bar.
class ScoreIndicator extends StatelessWidget {
  /// Creates a [ScoreIndicator].
  const ScoreIndicator({super.key, required this.score});

  /// The performance score to display.
  final PerformanceScore score;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score.total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF0D0E1A),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Performance: ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                '${score.total}/100',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  score.grade,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const Spacer(),
              _MiniScore(label: 'FPS', value: score.fpsScore, color: color),
              _MiniScore(label: 'MEM', value: score.memoryScore, color: color),
              _MiniScore(label: 'REB', value: score.rebuildScore, color: color),
              _MiniScore(label: 'JNK', value: score.jankScore, color: color),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: score.total / 100,
              backgroundColor: const Color(0xFF2D2F4A),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFFC107);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 7,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
