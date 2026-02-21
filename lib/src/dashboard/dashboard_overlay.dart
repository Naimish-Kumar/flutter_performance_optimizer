import 'package:flutter/material.dart';

import '../core/performance_config.dart';
import '../trackers/frame_tracker.dart';
import 'performance_dashboard.dart';

/// A draggable floating overlay that displays the performance dashboard.
///
/// Shown when [PerformanceOptimizer.showDashboard] is `true`.
///
/// The overlay can be dragged around the screen and minimized.
class DashboardOverlay extends StatefulWidget {
  /// Creates a [DashboardOverlay].
  const DashboardOverlay({super.key, required this.config});

  /// Configuration.
  final PerformanceConfig config;

  @override
  State<DashboardOverlay> createState() => _DashboardOverlayState();
}

class _DashboardOverlayState extends State<DashboardOverlay>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  bool _isExpanded = true;
  bool _initialized = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _initPosition(BuildContext context) {
    if (_initialized) return;
    _initialized = true;

    final size = MediaQuery.of(context).size;
    switch (widget.config.dashboardPosition) {
      case DashboardPosition.topLeft:
        _position = const Offset(10, 40);
        break;
      case DashboardPosition.topRight:
        _position = Offset(size.width - 395, 40);
        break;
      case DashboardPosition.bottomLeft:
        _position = Offset(10, size.height - 560);
        break;
      case DashboardPosition.bottomRight:
        _position = Offset(size.width - 395, size.height - 560);
        break;
      case DashboardPosition.center:
        _position = Offset((size.width - 380) / 2, (size.height - 520) / 2);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    _initPosition(context);

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _position += details.delta;
            });
          },
          child: Opacity(
            opacity: widget.config.dashboardOpacity,
            child:
                _isExpanded
                    ? _buildExpandedDashboard()
                    : _buildMinimizedBadge(),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedDashboard() {
    return Material(
      color: Colors.transparent,
      child: PerformanceDashboard(
        config: widget.config,
        onClose: () {
          setState(() {
            _isExpanded = false;
          });
        },
      ),
    );
  }

  Widget _buildMinimizedBadge() {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: StreamBuilder(
            stream: Stream.periodic(const Duration(milliseconds: 500)),
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '⚡ ${FrameTracker.instance.currentFps.toStringAsFixed(0)} FPS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
