import 'package:flutter/material.dart';

/// A compact metric card for the dashboard.
///
/// Displays a single metric with an icon, value, and subtitle.
class MetricCard extends StatelessWidget {
  /// Creates a [MetricCard].
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  /// Label text.
  final String label;

  /// Main value text.
  final String value;

  /// Icon.
  final IconData icon;

  /// Accent color.
  final Color color;

  /// Optional subtitle.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label metric: $value${subtitle != null ? " ($subtitle)" : ""}',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
                decoration: TextDecoration.none,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
