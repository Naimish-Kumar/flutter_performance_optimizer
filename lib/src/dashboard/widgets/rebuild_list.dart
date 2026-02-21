import 'package:flutter/material.dart';

import '../../trackers/rebuild_tracker.dart';

/// Rebuild tracking list for the dashboard.
///
/// Shows the most frequently rebuilt widgets with counts and freqency.
class RebuildList extends StatelessWidget {
  /// Creates a [RebuildList].
  const RebuildList({super.key, required this.rebuildTracker});

  /// Rebuild tracker instance.
  final RebuildTracker rebuildTracker;

  @override
  Widget build(BuildContext context) {
    final topRebuilders = rebuildTracker.topRebuilders(count: 15);
    final totalRebuilds = rebuildTracker.totalRebuilds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0E1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.refresh, size: 16, color: Color(0xFF6C63FF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Total Rebuilds: $totalRebuilds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Text(
                  '${topRebuilders.length} widgets',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (topRebuilders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No rebuild data yet.\n'
                  'Use PerformanceInspector to track specific widgets\n'
                  'or rebuild data will appear automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),

          // Widget list
          ...topRebuilders.map((entry) {
            final frequency = rebuildTracker.rebuildFrequency(entry.key);
            final color =
                entry.value > 200
                    ? const Color(0xFFF44336)
                    : entry.value > 50
                    ? const Color(0xFFFFC107)
                    : const Color(0xFF4CAF50);

            final maxCount = topRebuilders.first.value.clamp(1, 10000);
            final barWidth = (entry.value / maxCount).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0E1A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${entry.value}x',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: barWidth,
                        backgroundColor: const Color(0xFF2D2F4A),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${frequency.toStringAsFixed(1)} rebuilds/sec',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 8,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
