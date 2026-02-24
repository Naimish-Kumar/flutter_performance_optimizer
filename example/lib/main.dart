import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_performance_optimizer/flutter_performance_optimizer.dart';

void main() {
  // Enable AI Optimization Suggestions
  AISuggestionService.instance.enabled = true;
  // Set your Gemini API Key using --dart-define=GEMINI_API_KEY=your_key
  AISuggestionService.instance.apiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
  );

  runApp(
    PerformanceOptimizer(
      enabled: kDebugMode,
      showDashboard: true,
      showHeatmap: true, // Enable the heatmap by default
      trackRebuilds: true,
      trackMemory: true,
      trackAnimations: true,
      trackWidgetDepth: true,
      trackSetState: true,
      logWarnings: true,
      onWarning: (warning) {
        debugPrint('⚡ Performance Warning: ${warning.message}');
        if (warning.suggestion != null) {
          debugPrint('  → Suggestion: ${warning.suggestion}');
        }
      },
      child: const MyApp(),
    ),
  );
}

/// Main application widget for the demo.
class MyApp extends StatelessWidget {
  /// Creates a [MyApp] widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Performance Optimizer Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

/// Main home page for the performance demo.
class DemoHomePage extends StatefulWidget {
  /// Creates a [DemoHomePage] widget.
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  int _counter = 0;
  final List<String> _items = List.generate(100, (i) => 'Item $i');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Performance Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'View Score',
            onPressed: _showScore,
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb),
            tooltip: 'View Suggestions',
            onPressed: _showSuggestions,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Counter section (demonstrates rebuild tracking)
          PerformanceInspector(
            name: 'CounterSection',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Rebuild Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Counter: $_counter',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            SetStateTracker.instance.trackSetState(
                              'CounterSection',
                            );
                            setState(() => _counter++);
                          },
                          child: const Text('Increment'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _simulateRebuilds,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Simulate 100 Rebuilds'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Heavy list section
          PerformanceInspector(
            name: 'HeavyList',
            child: Card(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Heavy List Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.primaries[index % 18],
                            child: Text('${index + 1}'),
                          ),
                          title: Text(_items[index]),
                          subtitle: Text('Subtitle for item ${index + 1}'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Animation test
          const PerformanceInspector(
            name: 'AnimationSection',
            child: _AnimationTestCard(),
          ),
          const SizedBox(height: 16),

          // Metrics display
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Metrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _MetricRow(
                    'FPS',
                    PerformanceOptimizer.metrics.fps.toStringAsFixed(1),
                  ),
                  _MetricRow(
                    'Memory',
                    '${PerformanceOptimizer.metrics.memoryUsageMB.toStringAsFixed(1)} MB',
                  ),
                  _MetricRow(
                    'Rebuilds',
                    '${PerformanceOptimizer.metrics.totalRebuilds}',
                  ),
                  _MetricRow(
                    'Jank Frames',
                    '${PerformanceOptimizer.metrics.jankFrames}',
                  ),
                  _MetricRow(
                    'Warnings',
                    '${PerformanceOptimizer.metrics.warningCount}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          SetStateTracker.instance.trackSetState('DemoHomePage');
          setState(() => _counter++);
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _simulateRebuilds() {
    for (int i = 0; i < 100; i++) {
      RebuildTracker.instance.trackRebuild('SimulatedWidget');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulated 100 rebuilds! Check the dashboard.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showScore() {
    final score = PerformanceOptimizer.score;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Performance Score'),
            content: Text(score.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSuggestions() {
    final report = PerformanceOptimizer.report;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Optimization Report'),
            content: SingleChildScrollView(
              child: Text(
                report,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

class _AnimationTestCard extends StatefulWidget {
  const _AnimationTestCard();

  @override
  State<_AnimationTestCard> createState() => _AnimationTestCardState();
}

class _AnimationTestCardState extends State<_AnimationTestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    MemoryTracker.instance.trackDisposable('AnimationTestCard.controller');
  }

  @override
  void dispose() {
    _controller.dispose();
    MemoryTracker.instance.markDisposed('AnimationTestCard.controller');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Animation Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RotationTransition(
              turns: _animation,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    AnimationTracker.instance.registerAnimation('rotation');
                    _controller.repeat();
                  },
                  child: const Text('Start'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    AnimationTracker.instance.unregisterAnimation('rotation');
                    _controller.stop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
